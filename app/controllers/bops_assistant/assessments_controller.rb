require "net/http"
require "json"
require "openssl"

module BopsAssistant
  class AssessmentsController < ApplicationController
    # List previous runs for a planning application (or all recent)
    def index
      scope = AiAssessment.order(created_at: :desc).limit(50)
      if params[:planning_application_id].present?
        scope = scope.where(planning_application_id: params[:planning_application_id])
      end
      render json: scope.as_json(only: [:id, :planning_application_id, :stage, :status, :model_ref, :latency_ms, :created_at])
    end

    # Show a specific run, including structured sections split out for UI tabs
    def show
      run = AiAssessment.find(params[:id])
      out = run.outputs_json || {}
      render json: {
        id: run.id,
        stage: run.stage,
        status: run.status,
        model_ref: run.model_ref,
        latency_ms: run.latency_ms,
        recommendation: out['recommendation'],
        policies: out['policies'],
        spatial: out['spatial'],
        checklist: out['checklist'],
        draft_report_md: out['draft_report_md'],
        artifacts: out['artifacts'],
        trace: out['trace']
      }
    end

    def create
      pa_id = params[:planning_application_id]
      stage = params[:stage].presence || "assess"
      pa = begin
        Object.const_defined?("PlanningApplication") ? PlanningApplication.find_by(id: pa_id) : nil
      rescue
        nil
      end

      envelope = pack_envelope(pa)
      body = envelope.to_json
      sig  = OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("AGENT_BRIDGE_HMAC_SECRET", "change-me"), body)
      uri  = URI.join(ENV.fetch("AGENT_BRIDGE_URL", "http://localhost:8000") + "/", path_for(stage))

      res = Net::HTTP.start(uri.host, uri.port) do |http|
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["x-signature"]  = sig
        req.body = body
        http.request(req)
      end

      json = JSON.parse(res.body) rescue {}
      run = AiAssessment.create!(
        planning_application_id: pa&.id,
        stage: stage,
        status: res.code.to_i == 200 ? "ok" : "error",
        outputs_json: json,
        model_ref: json.dig("trace","model_ref"),
        latency_ms: json.dig("trace","latency_ms")
      )

      # optional: explode evidences into table
      Array(json["policies"]).each do |pf|
        Array(pf["evidence"]).each do |ev|
          AiEvidence.create!(
            ai_assessment_id: run.id,
            kind: ev["kind"], label: pf["policy_id"] || pf["title"],
            source_uri: ev["uri"], source_pointer: ev["pointer"],
            snippet: ev["snippet"], score: nil, rationale: nil
          )
        end
      end

      render json: { id: run.id, result: json }
    end

    private

    def path_for(stage)
      case stage
      when "validate" then "validate"
      when "notice"   then "notice"
      else                 "assess"
      end
    end

    def pack_envelope(pa)
      red_line = pa&.respond_to?(:site_boundary_geojson) ? pa.site_boundary_geojson : nil
      docs = if pa&.respond_to?(:documents) && pa.documents
        pa.documents.map do |d|
          { id: d.id.to_s, kind: (d.respond_to?(:kind) ? d.kind : "doc"), uri: (d.respond_to?(:file_url) ? d.file_url : ""), mime: (d.respond_to?(:content_type) ? d.content_type : nil) }
        end
      else
        []
      end

      {
        schema: "tpa.run/0.2",
        case:   { id: pa&.id&.to_s || "local", type: (pa&.respond_to?(:application_type) ? pa.application_type : "householder"),
                  lpa_code: (pa&.respond_to?(:local_authority) ? pa.local_authority&.code : nil), reference: pa&.try(:reference) },
        site:   { id: (pa&.respond_to?(:site_address) ? pa.site_address&.parameterize : "site-1"),
                  geometry: red_line, geometry_ref: nil, uprn: nil },
        documents: docs,
        policy_scope: [],
        constraints_layers: [],
        goals: [],
        consultation: [],
        figures: []
      }
    end
  end
end

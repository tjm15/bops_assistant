module BopsAssistant
  class OverlaysController < ApplicationController
    # Returns a FeatureCollection GeoJSON built from stored artifacts if available
    def show
      run = AiAssessment.find(params[:id])
      artifacts = run.outputs_json && run.outputs_json["artifacts"] || {}

      # Try common keys where GeoJSON might be stored
      fc = artifacts["geojson"] || artifacts.dig("overlays", "geojson") || artifacts.dig("map", "geojson")

      if fc.present?
        render json: fc
      else
        render json: { type: "FeatureCollection", features: [] }
      end
    end
  end
end

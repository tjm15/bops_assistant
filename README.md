# bops_assistant (Rails engine)

Mountable engine that adds a GOV.UK-compliant Assistant panel to BOPS and proxies to a Python FastAPI agent-bridge.

## Mount
Add to Gemfile of host app and mount in routes:
```ruby
gem "bops_assistant", git: "https://github.com/you/bops_assistant.git", branch: "main"
mount BopsAssistant::Engine => "/assistant"
```

In your case view, render the panel partial (expects `@planning_application`):
```erb
<%= render "bops_assistant/panel" %>
```

## Environment
```
ENABLE_BOPS_ASSISTANT=true
AGENT_BRIDGE_URL=http://localhost:8000
AGENT_BRIDGE_HMAC_SECRET=change-me
```

## Features
- Run Validate / Assess / Notice stages against agent-bridge
- Store run outputs and derive evidence records
- Tabbed panel: Overview, Policies, Constraints, Documents, Report
- OpenLayers map shows site and AI overlays if present in artifacts.geojson
- Renders Draft Report (Markdown)

## API contract
Matches `assistant.v0.yaml` (OpenAPI 3.0.3) with `/validate`, `/assess`, `/notice` accepting `AssessmentEnvelope` and returning `AssessmentResult`.

## Assets
The panel loads OpenLayers via CDN by default. If your host app bundles OpenLayers, remove the CDN tags from the partial.

## Development
Run migrations in the host app after bundling the engine:

```bash
bin/rails db:migrate
```

The engine persists to:
- `assistant_ai_assessments`
- `assistant_ai_evidences`

## Security
The engine is disabled by default. It returns 403 unless `ENABLE_BOPS_ASSISTANT=true`.
Back Office Planning System (BOPS) x The Planners Assistant (TPA)

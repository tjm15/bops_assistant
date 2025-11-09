# BOPS Assistant Panel — Extended Integrated Specification

*Version 1.2 • 9 Nov 2025*

> **Scope:** Fully integrated assistant layer within BOPS for Development Management workflows, including OpenLayers maps, canonical constraints via PostGIS, document APIs, and structured report/decision template autofill.

---

## 1. Executive Summary

The **BOPS Assistant Panel** augments BOPS with explainable, semi-automated decision support. It integrates:

* Policy retrieval and synthesis
* Spatial constraint analysis (via PostGIS)
* Document intelligence (DAS, plans, design codes)
* Autofill for officer report and decision templates
* Real-time visual reasoning and map-linked AI overlays

The system adheres to **GOV.UK Design System** standards for accessibility and interface consistency, but leverages a **Python FastAPI agent-bridge backend** to perform reasoning, document parsing, and spatial analysis. It unifies textual, spatial, and visual evidence into an auditable reasoning chain.

---

## 2. Architecture Overview

### 2.1 High-level architecture

```
+----------------------------------------------+
|                 BOPS (Rails)                 |
|----------------------------------------------|
| GOV.UK UI | OpenLayers Map | Report Editor   |
|----------------------------------------------|
| Assistant Panel  │ Document API │ PostGIS DB  |
+----------------------------------------------+
                │         │         │
                ▼         ▼         ▼
         agent-bridge (FastAPI backend)
                │
                ▼
      LLM / VLM / GraphRAG toolchain
```

### 2.2 Components

| Component                  | Description                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------ |
| **BOPS Assistant Panel**   | GOV.UK-compliant UI with embedded OpenLayers map and report editor controls.         |
| **agent-bridge (FastAPI)** | Orchestrates retrieval (textual + spatial), reasoning, and VLM analysis.             |
| **PostGIS**                | Stores canonical constraint layers; accessed by both BOPS and agent-bridge.          |
| **Document APIs**          | Shared BOPS document endpoints (DAS, plans, decision notices).                       |
| **LLM/VLM Modules**        | Perform reasoning, summarisation, structured extraction, and design visual analysis. |

---

## 3. Functional Scope (Integrated)

| Category                         | Description                                                                                   |
| -------------------------------- | --------------------------------------------------------------------------------------------- |
| **Policy Analysis**              | Retrieve and interpret relevant local plan policies.                                          |
| **Constraint Synthesis**         | Use PostGIS layers to flag flood risk, conservation, heritage, etc.                           |
| **Document Parsing**             | Parse submitted PDFs and design statements for contextual data.                               |
| **Visual Analysis (VLM)**        | Interpret plans/elevations for height, frontage rhythm, and materials.                        |
| **Report Autofill**              | Populate officer report and decision template fields with generated content, editable inline. |
| **Interactive Map (OpenLayers)** | Display canonical constraint layers, site boundary, and AI annotations.                       |
| **User Guidance**                | Officers can confirm, edit, or reject suggested autofill sections.                            |
| **Provenance Tracking**          | Each autofill item includes source links (policy, map layer, doc extract).                    |
| **Live Spatial AI Overlay**      | Dynamic GeoJSON layers streamed from agent-bridge representing active reasoning.              |

---

## 4. User Interface Specification

### 4.1 Layout

```
┌───────────────────────────────────────────────┐
│ Header: Application reference, status         │
├───────────────────────────────────────────────┤
│ [Assistant Panel]                             │
│  ├─ Tabs: Overview | Policies | Constraints | Documents | Report │
│  ├─ OpenLayers Map showing dynamic overlays    │
│  ├─ GOV.UK Summary Lists + Details sections   │
│  └─ Inline Report Editor (autofill fields)    │
└───────────────────────────────────────────────┘
```

### 4.2 Interactive elements

* **OpenLayers map viewer:** constraint layers toggled via GOV.UK checkboxes.
* **Dynamic overlays:** streamed GeoJSON from agent-bridge (AI interpretations, footprints, visual features).
* **Constraint list:** summarises intersected layers with clickable provenance.
* **Report editor:** GOV.UK form sections (Design, Amenity, Transport). Prefilled and editable.
* **Run analysis button:** triggers multi-modal reasoning pass (policy + spatial + document).

---

## 5. Data Flow

```
User Action → BOPS Panel → agent-bridge /v1/run
    ├── retrieves policy text from DB
    ├── queries PostGIS for constraint intersections
    ├── parses documents via BOPS API
    ├── VLM extracts design metrics
    ├── fuses results (GraphRAG)
    └── streams structured JSON + GeoJSON (SSE)
          → Updates UI tabs, OpenLayers map, and report fields in real time
```

---

## 6. API & Data Contracts

*(unchanged from v1.1; includes `/v1/runs` and streamed JSON payloads with policies, constraints, documents, vlm_findings, and report_fields.)*

---

## 7. PostGIS & Canonical Constraints

* Shared `bops_postgis` spatial database.
* Canonical layers: flood zones, conservation areas, listed buildings, green belt, APA, designated views.
* CRS: EPSG:27700. Geometry: `MultiPolygon`.
* agent-bridge performs intersect, buffer, and area-weighted impact calculations.
* OpenLayers renders via GeoJSON served by `/constraints/:run_id.geojson`.

---

## 8. Document API Integration

* BOPS document endpoints reused for retrieval and parsing.
* VLM performs optical layout detection, plan parsing, and massing recognition.
* agent-bridge merges text + visual cues into reasoning graph.

---

## 9. Report and Decision Templates

Autofill maps directly onto YAML/JSON-defined templates. Officers can edit, highlight AI-derived segments, and re-run partial sections. All editable text retains audit provenance and regenerates live map highlights on focus.

---

## 10. Backend (agent-bridge) Modules

* **Retriever:** pgvector + BM25 hybrid search over policy/docs.
* **SpatialAdapter:** PostGIS SQL adapter with canonical layer registry.
* **DocParser:** PDF text + VLM layout extraction.
* **Reasoner:** AgentKit chain integrating multi-modal context.
* **OverlayEmitter:** Streams live GeoJSON overlays (e.g. building outline interpretation).
* **ReportGenerator:** Populates officer templates.
* **StreamEmitter:** Sends JSON + GeoJSON updates via SSE.

---

## 11. Security and Audit

* Service tokens for secure communication.
* No PII passed.
* Full audit logging per run with provenance links.
* Model versions and timestamps included.

---

## 12. Deployment

| Component        | Tech                       | Notes                                                              |
| ---------------- | -------------------------- | ------------------------------------------------------------------ |
| **BOPS**         | Ruby on Rails + OpenLayers | Adds GOV.UK panel, integrated AI overlays, report editor partials. |
| **agent-bridge** | Python FastAPI             | Containerised; SSE; PostGIS + VLM pipelines.                       |
| **PostGIS**      | PostgreSQL 16 + PostGIS 3  | Canonical spatial data store.                                      |
| **Frontend Map** | OpenLayers                 | Streams GeoJSON overlays and canonical layers.                     |

---

## 13. Development Roadmap — Ambitious Mode

| Phase                             | Description                                                                                                 | Target Outcome                                 |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **1 — Foundation**                | Implement agent-bridge skeleton with live SSE + GeoJSON stubs. Integrate OpenLayers in-panel rendering.     | End-to-end reactive loop demo.                 |
| **2 — Cognitive Core**            | Build real multi-modal reasoning chain: PostGIS + policy retrieval + doc parsing unified in one agent call. | AI-assisted constraint synthesis.              |
| **3 — Live Report Mode**          | Implement inline report editing with live provenance back-links to map and document extracts.               | Human-in-the-loop co-authoring.                |
| **4 — Visual Comprehension**      | Integrate VLM pipeline for plan/elevation interpretation.                                                   | Automatic detection of design-code compliance. |
| **5 — Real-Time Reasoning Graph** | GraphRAG with visible causal edges (policy ↔ constraint ↔ design feature).                                  | Interactive explainer UI.                      |
| **6 — Multi-User Review Layer**   | Concurrent editing and cross-officer review with change provenance.                                         | Collaborative decision environment.            |
| **7 — Continuous Learning**       | Feedback-based retraining of retrieval and report style models using anonymised BOPS data.                  | Adaptive, auditable AI support.                |
| **8 — External API Gateway**      | Public REST/GraphQL API for Local Plan dashboards and external audit tools.                                 | One backend for planning AI ecosystem.         |

---

## 14. Compliance

* GOV.UK Design System v4.7
* WCAG 2.2 AA
* GDS cloud security + service token policies
* MHCLG Digital Planning Data Schemas (spatial + doc standards)

---

**Summary:** The Assistant Panel is a high‑ambition, multi‑modal reasoning environment within BOPS. It couples live OpenLayers overlays, canonical PostGIS data, document intelligence, and editable report templates into a single, explainable decision‑support tool — paving the way for full digital planning intelligence within compliant public systems.

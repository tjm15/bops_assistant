import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "output","button","stage","status",
    "panelOverview","panelPolicies","panelConstraints","panelDocuments","panelReport",
    "policies","constraints","documents","reportHtml","map","outcome","confidence","model","latency"
  ]

  static values = { assessmentsPath: String }

  connect(){
    this.activePanel = this.panelOverviewTarget
    this.initMap()
    this.fetchRecent()
  }

  selectTab(event){
    event.preventDefault()
    const id = event.currentTarget.getAttribute('href').replace('#','')
    const panelMap = {
      overview: this.panelOverviewTarget,
      policies: this.panelPoliciesTarget,
      constraints: this.panelConstraintsTarget,
      documents: this.panelDocumentsTarget,
      report: this.panelReportTarget
    }
    Object.values(panelMap).forEach(p => p.classList.add('govuk-tabs__panel--hidden'))
    panelMap[id].classList.remove('govuk-tabs__panel--hidden')
    this.activePanel = panelMap[id]
    if(id === 'overview') this.mapUpdateSize()
  }

  run(e){
    e.preventDefault()
    const paId = this.element.dataset.planningApplicationId
    const stage = this.stageTarget?.value || 'assess'
    this.buttonTarget.disabled = true
    this.statusTarget.textContent = 'Running…'
    fetch(`/assistant/assessments?planning_application_id=${paId}&stage=${stage}`, {
      method: 'POST',
      headers: { 'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content }
    })
      .then(r => r.json())
      .then(j => {
        this.outputTarget.textContent = JSON.stringify(j.result, null, 2)
        this.renderResult(j.result)
      })
      .catch(err => { this.outputTarget.textContent = `Error: ${err}` })
      .finally(()=> { this.buttonTarget.disabled = false; this.statusTarget.textContent = '' })
  }

  fetchRecent(){
    if(!this.assessmentsPathValue) return
    fetch(this.assessmentsPathValue)
      .then(r => r.json())
      .then(list => {
        if(list.length > 0){ this.statusTarget.textContent = `Loaded ${list.length} previous runs` }
      })
      .catch(()=>{})
  }

  renderResult(res){
    const rec = res.recommendation || {}
    this.outcomeTarget.textContent = rec.outcome || '—'
    this.confidenceTarget.textContent = rec.confidence != null ? (rec.confidence*100).toFixed(1)+'%' : '—'
    this.modelTarget.textContent = res.trace?.model_ref || '—'
    this.latencyTarget.textContent = res.trace?.latency_ms ? res.trace.latency_ms + ' ms' : '—'
    this.renderPolicies(res.policies || [])
    this.renderSpatial(res.spatial || [])
    this.renderDocuments(res)
    this.renderReport(res.draft_report_md || '')
    this.updateMapArtifacts(res.artifacts || {})
  }

  renderPolicies(policies){
    const html = policies.map(p => `<details class="govuk-details"><summary class="govuk-details__summary"><span class="govuk-details__summary-text">${this.escape(p.title || p.policy_id)}</span></summary><div class="govuk-details__text"><p><strong>RAG:</strong> ${this.escape(p.rag || 'n/a')}</p><p>${this.escape(p.explanation || '')}</p>${this.renderEvidenceList(p.evidence)}</div></details>`).join('')
    this.policiesTarget.innerHTML = html || '<p class="govuk-hint">No policy analysis returned.</p>'
  }

  renderSpatial(spatial){
    const html = spatial.map(s => `<div class="govuk-summary-list__row"><dt class="govuk-summary-list__key">${this.escape(s.layer)}</dt><dd class="govuk-summary-list__value">${s.hit ? 'Hit' : 'No'}${s.detail ? ' – '+this.escape(JSON.stringify(s.detail)) : ''}${this.renderEvidenceList(s.evidence)}</dd></div>`).join('')
    this.constraintsTarget.innerHTML = `<dl class="govuk-summary-list">${html}</dl>`
  }

  renderDocuments(res){
    // placeholder until documents are surfaced explicitly
    this.documentsTarget.textContent = 'Artifacts keys: ' + Object.keys(res.artifacts || {}).join(', ')
  }

  renderReport(md){
    // markdown server-side helper could be used; fallback to naive client conversion
    const safe = this.escape(md).replace(/\n\n/g,'</p><p>').replace(/\n/g,'<br>')
    this.reportHtmlTarget.innerHTML = `<p>${safe}</p>`
  }

  renderEvidenceList(evs){
    if(!Array.isArray(evs) || evs.length === 0) return ''
    return '<ul class="govuk-list govuk-list--bullet">' + evs.map(e => `<li>${this.escape(e.kind)}: <code>${this.escape(e.pointer || '')}</code></li>`).join('') + '</ul>'
  }

  escape(str){
    return (str || '').toString().replace(/[&<>]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))
  }

  initMap(){
    if(!window.ol || !this.hasMapTarget) return
    this.mapObj = new ol.Map({
      target: this.mapTarget,
      layers: [new ol.layer.Tile({ source: new ol.source.OSM() })],
      view: new ol.View({ center: ol.proj.fromLonLat([0.1,51.5]), zoom: 10 })
    })
  }

  mapUpdateSize(){
    if(this.mapObj){ setTimeout(()=> this.mapObj.updateSize(), 50) }
  }

  updateMapArtifacts(artifacts){
    if(!this.mapObj) return
    const geojson = artifacts.geojson || artifacts?.overlays?.geojson || null
    if(!geojson) return
    if(this.vectorLayer){ this.mapObj.removeLayer(this.vectorLayer) }
    const format = new ol.format.GeoJSON()
    const features = format.readFeatures(geojson, { featureProjection: 'EPSG:3857' })
    this.vectorLayer = new ol.layer.Vector({ source: new ol.source.Vector({ features }) })
    this.mapObj.addLayer(this.vectorLayer)
    const extent = this.vectorLayer.getSource().getExtent()
    if(extent && extent.every(e => isFinite(e))){ this.mapObj.getView().fit(extent, { padding: [10,10,10,10] }) }
  }
}

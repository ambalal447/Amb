# Financial Intelligence Operating System

## Executive Mission

The Financial Intelligence Operating System is an institutional-grade intelligence engine that answers four questions for every market-relevant development: **what happened, why it happened, what will be affected, and what to watch next**. It is not a social feed, not a rumor aggregator, and not a generic AI chatbot. It is an evidence-bound system for verified financial events, graph-based impact propagation, portfolio-aware monitoring, and auditable AI analysis.

The product is designed to replace fragmented business television, newspapers, finance portals, chat channels, social finance feeds, and multiple market apps by unifying trusted data ingestion, source verification, GraphRAG, event streaming, market impact modeling, and analyst-grade user experience.

## 1. Complete System Architecture

### Platform Layers

1. **Trusted ingestion layer** collects official releases, exchange notices, filings, macro publications, issuer documents, licensed news, market data, and alternative signals.
2. **Verification and provenance layer** validates source identity, timestamps, content hashes, licensing constraints, duplicate status, and contradiction risk.
3. **Event intelligence layer** converts raw documents and streams into canonical events with evidence spans, extracted entities, event types, and confidence scores.
4. **Global intelligence graph** connects countries, companies, central banks, currencies, commodities, sectors, supply chains, ETFs, indices, executives, policies, and investors.
5. **GraphRAG and retrieval layer** retrieves only relevant evidence from PostgreSQL, Elasticsearch, Qdrant, Neo4j, ClickHouse, and licensed data APIs.
6. **Multi-agent analysis layer** separates extraction, verification, graph reasoning, market impact, portfolio exposure, earnings intelligence, fraud detection, and report generation into independently testable agents.
7. **Simulation and digital twin layer** estimates scenario paths such as oil shocks, rate changes, currency moves, tariffs, export restrictions, or subsidy programs.
8. **Delivery layer** serves professional web, mobile, terminal-style dashboards, portfolio alerts, APIs, webhooks, and analyst workspaces.
9. **Governance layer** enforces zero-hallucination policies, model evaluation, audit logs, human escalation, entitlement management, and regulatory controls.

### Logical Architecture

```text
Sources -> Connectors -> Kafka -> Raw Store -> Verification -> Entity/Event Extraction
          -> Evidence Store -> Knowledge Graph -> GraphRAG -> Agent Orchestration
          -> Impact Engine -> Intelligence Reports -> APIs/Web/Mobile/Alerts
                                    |              -> Portfolio Exposure Engine
                                    |              -> Digital Twin Simulator
                                    |              -> Early Signal Engine
                                    |              -> Earnings/Fraud Engines
```

### Technology Choices

- **Frontend:** Next.js, TypeScript, Tailwind, React Native.
- **Backend:** Python, FastAPI, Pydantic, async workers.
- **Streaming:** Kafka with schema registry and dead-letter topics.
- **Transactional database:** PostgreSQL.
- **Analytical database:** ClickHouse.
- **Graph database:** Neo4j.
- **Search:** Elasticsearch.
- **Vector database:** Qdrant.
- **AI providers:** OpenAI, Claude, Gemini behind a model gateway.
- **Embeddings:** BGE for open retrieval and OpenAI embeddings for high-precision semantic search.
- **Infrastructure:** AWS, Cloudflare, Kubernetes, Terraform, OpenTelemetry.

## 2. Database Schema

The core schema separates immutable evidence from AI interpretations. PostgreSQL stores sources, raw documents, evidence spans, canonical entities, event records, impact assessments, agent runs, portfolios, positions, and audit logs. The schema blueprint is maintained in `architecture/sql/core_schema.sql`.

### PostgreSQL Tables

| Table | Purpose |
| --- | --- |
| `sources` | Trusted source registry with trust tier, license terms, URL, and review requirements. |
| `raw_documents` | Immutable ingested source payloads with content hashes and verification status. |
| `evidence_spans` | Exact cited text ranges used to support claims and AI outputs. |
| `entities` | Canonical companies, countries, currencies, commodities, indices, sectors, executives, and policies. |
| `events` | Deduplicated market events with confidence, source, model version, and evidence manifest. |
| `event_entities` | Entity roles and relevance scores for each event. |
| `impact_assessments` | Bullish, neutral, bearish, or mixed impact judgments by entity, channel, magnitude, horizon, and evidence. |
| `agent_runs` | Full AI execution lineage: agent, model, prompt hash, input evidence, output JSON, and policy result. |
| `portfolios` | User or institution portfolios. |
| `portfolio_positions` | Point-in-time holdings for exposure analysis. |
| `audit_log` | Tamper-evident record of user, system, model, and administrator actions. |

### ClickHouse Tables

ClickHouse stores high-volume immutable data:

- `market_ticks`: real-time and delayed prices, volume, bid/ask, venue, and quality flags.
- `economic_series_observations`: macro time series from central banks, IMF, World Bank, WTO, Eurostat, RBI, and other official sources.
- `entity_signal_features`: shipping rates, port activity, commodity moves, currency moves, bond yields, job postings, and trade statistics.
- `event_impact_timeseries`: post-event price, spread, volume, volatility, and factor-response windows.
- `portfolio_exposure_snapshots`: factor, sector, country, currency, and graph exposure calculations.
- `agent_quality_metrics`: latency, abstention rate, citation coverage, contradiction rate, and human correction rate.

### Elasticsearch Indexes

- `documents_v1`: full-text search over source documents.
- `evidence_spans_v1`: claim-level search over verified evidence.
- `events_v1`: search over canonical events, impacted entities, jurisdictions, and event types.
- `transcripts_v1`: earnings-call and management commentary search.

### Qdrant Collections

- `document_chunks_bge`: semantic retrieval across long documents.
- `evidence_spans_openai`: claim-level retrieval for AI grounding.
- `event_memory_bge`: historical analog retrieval.
- `earnings_call_segments_bge`: management commentary comparison.

## 3. Neo4j Graph Design

Neo4j stores the global intelligence graph used for GraphRAG, contagion analysis, supply-chain propagation, portfolio exposure, and digital twin simulation. The graph model and constraints are maintained in `architecture/neo4j/graph_model.cypher`.

### Node Types

- `Country`, `CentralBank`, `Currency`, `Company`, `Security`, `ETF`, `Index`.
- `Industry`, `Sector`, `Commodity`, `Facility`, `Port`, `SupplyChainComponent`.
- `Executive`, `InstitutionalInvestor`, `Policy`, `Regulation`, `Event`.
- `Source`, `Filing`, `EarningsCall`, `MacroSeries`.

### Relationship Types

- Ownership: `OWNS`, `HELD_BY`, `TRACKS_COMPANY`, `CONSTITUENT_OF`.
- Macro: `ISSUES_CURRENCY`, `SETS_POLICY_RATE_FOR`, `REGULATES`, `TAXES`, `SUBSIDIZES`.
- Corporate: `LISTED_ON`, `OPERATES_IN`, `SUPPLIES`, `CUSTOMER_OF`, `COMPETES_WITH`.
- Sector: `MEMBER_OF`, `PART_OF`, `INPUT_TO`, `DEMAND_DRIVER_FOR`.
- Intelligence: `MENTIONS`, `AFFECTS`, `IMPACTS`, `CONTRADICTS`, `SUPPORTS`.

Every factual edge must include `confidence`, `evidence_ids`, `source_ids`, `as_of`, and `updated_at` where applicable. No edge that affects user-facing reasoning may exist without provenance.

### Impact Propagation

When an event enters the graph, the propagation engine:

1. Finds directly mentioned entities.
2. Traverses high-confidence causal and exposure edges.
3. Applies decay by path length, edge confidence, exposure weight, recency, and channel relevance.
4. Produces first-order, second-order, and third-order impacted entities.
5. Requires evidence for the original event and evidence-backed graph relationships for propagation.
6. Returns path explanations such as `China export policy -> rare earths -> EV industry -> battery manufacturers -> lithium demand`.

## 4. Event Pipeline

### Kafka Topics

| Topic | Description |
| --- | --- |
| `source.raw.official` | Raw documents from official agencies, regulators, exchanges, and central banks. |
| `source.raw.issuer` | Press releases, investor relations updates, filings, earnings documents. |
| `source.raw.news` | Licensed trusted-news payloads. |
| `source.raw.market` | Market data ticks, rates, commodities, FX, yields, and indices. |
| `doc.verified` | Source-verified and hash-deduplicated documents. |
| `event.candidate` | Candidate events extracted from documents or abnormal market signals. |
| `event.enriched` | Entity-linked, graph-linked, evidence-backed event records. |
| `event.published` | User-visible events that passed policy checks. |
| `impact.calculated` | Per-entity impact assessments. |
| `alert.portfolio` | User and institution portfolio alerts. |
| `agent.deadletter` | Failed, disputed, or policy-rejected AI jobs. |

### Processing Flow

1. **Ingest:** Connectors fetch SEC, Federal Reserve, Treasury, NASDAQ, NYSE, NSE, BSE, RBI, SEBI, PBOC, Shanghai Exchange, Shenzhen Exchange, BOJ, TSE, ECB, Eurostat, IMF, World Bank, WTO, OPEC, issuer pages, filings, earnings calls, and trusted licensed news.
2. **Verify:** The source registry checks domain, certificate, API key, feed signature, publication timestamp, content hash, and licensing rules.
3. **Normalize:** Documents are converted into canonical text, metadata, attachments, language, and source identifiers.
4. **Extract:** Agents identify claims, entities, numerical values, dates, event type, geography, and affected instruments.
5. **Deduplicate:** Similar events are merged using source time, document hash, embeddings, entity overlap, and event-type rules.
6. **Link:** Entities are resolved against PostgreSQL and Neo4j using identifiers, aliases, ticker mappings, ISINs, CIKs, LEIs, and exchange symbols.
7. **Score:** Confidence is calculated from source tier, extraction certainty, corroboration, contradiction, graph support, and data freshness.
8. **Analyze:** Market impact, portfolio exposure, historical analogs, and watchlists are generated.
9. **Publish:** Only policy-passing, evidence-backed reports reach users.
10. **Audit:** Every output stores model version, prompt hash, retrieved evidence, graph paths, confidence score, and validation result.

## 5. Agent Architecture

### Agent Roster

| Agent | Responsibility | Output |
| --- | --- | --- |
| Source Verification Agent | Validate source authenticity, license, timestamp, duplication, and retraction status. | Verification decision and trust score. |
| Entity Extraction Agent | Extract companies, securities, countries, commodities, people, policies, and macro series. | Entity candidates with evidence spans. |
| Entity Resolution Agent | Link mentions to canonical entities and graph nodes. | Resolved entity IDs with ambiguity notes. |
| Event Classification Agent | Classify event type and produce canonical event summary. | Event candidate JSON. |
| Evidence Auditor Agent | Check every generated statement against evidence spans. | Pass, fail, or abstain result. |
| Graph Reasoning Agent | Retrieve graph paths and propagate impact. | Impact paths with confidence decay. |
| Market Impact Agent | Estimate revenue, margin, supply chain, regulatory, rate, FX, and commodity channels. | Bullish/neutral/bearish assessment. |
| Historical Analog Agent | Retrieve prior similar events and post-event outcomes. | Comparison table and caveats. |
| Portfolio Agent | Map events to holdings, factors, sectors, currencies, countries, and counterparties. | Portfolio exposure alert. |
| Earnings Agent | Analyze transcripts, guidance, tone, risks, opportunities, and quarter-over-quarter changes. | Earnings intelligence report. |
| Lie Detector Agent | Compare current statements with past statements, actual results, competitors, and industry trends. | Consistency score with evidence. |
| Fraud Risk Agent | Detect auditor resignations, promoter selling, pledges, anomalies, unusual disclosures, and governance issues. | Risk alert and severity. |
| Digital Twin Agent | Run scenario simulations over graph, macro, and factor models. | Scenario impact map. |
| Report Composer Agent | Assemble final user-facing output from verified agent outputs only. | Cited intelligence report. |

### Orchestration Rules

- Agents may not use untrusted memory as a factual source.
- Agents must return structured JSON with evidence IDs for every claim.
- Agents must abstain when evidence is insufficient.
- The composer cannot introduce new facts; it can only transform verified intermediate outputs.
- Cross-model consensus is used for high-impact events, but consensus never replaces evidence.
- A policy gate rejects unsupported numbers, unsourced quotes, vague attributions, stale market data, and ungrounded predictions.

## 6. API Design

### Public and Institutional APIs

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/v1/events` | Search and filter verified events. |
| `GET` | `/v1/events/{event_id}` | Fetch full event report, evidence, graph paths, and impact. |
| `GET` | `/v1/entities/{entity_id}` | Entity profile with graph relationships, documents, and exposures. |
| `GET` | `/v1/entities/{entity_id}/timeline` | Chronological event and signal history. |
| `GET` | `/v1/markets/{symbol}` | Market snapshot with provenance and freshness metadata. |
| `POST` | `/v1/ask` | Evidence-bound GraphRAG question answering. |
| `POST` | `/v1/scenarios` | Digital twin scenario simulation. |
| `POST` | `/v1/portfolios` | Create or update portfolio. |
| `GET` | `/v1/portfolios/{id}/exposures` | Exposure by factor, graph path, sector, country, currency, and event. |
| `GET` | `/v1/watchlists/stocks-to-watch` | Most impacted names and hidden beneficiaries. |
| `GET` | `/v1/earnings/{entity_id}` | Earnings intelligence and transcript deltas. |
| `GET` | `/v1/risk/fraud` | Governance and fraud risk alerts. |
| `POST` | `/v1/webhooks` | Register event, portfolio, or signal webhooks. |

### Example Event Response

```json
{
  "event_id": "evt_123",
  "headline": "Central bank raises policy rate by 25 bps",
  "what_happened": {"text": "...", "evidence_ids": ["evs_1"]},
  "why_it_matters": {"text": "...", "evidence_ids": ["evs_2", "graph_path_7"]},
  "confidence": {"score": 0.91, "band": "very_high", "drivers": ["official_source", "numeric_match", "no_contradictions"]},
  "impacts": [
    {"entity_id": "sec_abc", "direction": "bearish", "channel": "interest_rate", "horizon": "1-6m", "evidence_ids": ["evs_1"]}
  ],
  "watch_next": ["bond yields", "bank net interest margins", "currency reaction"],
  "source_links": ["https://official-source.example/release"]
}
```

## 7. Frontend Screens

### Professional Web Application

1. **Command Center:** Real-time verified event tape, macro clock, market regime, top cross-asset movers, and portfolio alerts.
2. **Event Intelligence Page:** What happened, why it matters, impact map, confidence score, evidence drawer, source links, and historical analogs.
3. **Global Graph Explorer:** Interactive graph of entities, supply chains, countries, commodities, central banks, investors, and policies.
4. **Stocks to Watch:** Most positively impacted, most negatively impacted, hidden beneficiaries, second-order effects, and rationale.
5. **Portfolio Intelligence:** Holdings exposure, event sensitivity, factor decomposition, drawdown scenarios, and alert history.
6. **Digital Twin Simulator:** Scenario builder for oil, rates, currencies, commodities, tariffs, sanctions, subsidies, inflation, and GDP shocks.
7. **Early Signals Dashboard:** Shipping, ports, commodities, FX, yields, job postings, import-export anomalies, and early warnings.
8. **Earnings Workspace:** Transcript comparison, guidance changes, management tone, risk/opportunity extraction, and peer comparison.
9. **Corporate Truth Monitor:** Management statement consistency, contradictory evidence, governance risk, and disclosure anomalies.
10. **Source and Evidence Browser:** Search official documents, filings, evidence spans, and raw source metadata.
11. **Analyst Workbench:** Saved investigations, graph paths, notes, exports, and shareable institutional reports.
12. **Admin and Governance Console:** Source registry, model quality metrics, policy failures, human review queue, entitlements, and audit logs.

### Design Principles

- Dark institutional theme with high contrast, dense data, keyboard navigation, and deterministic loading states.
- No meme-stock visual language, casino colors, or gamified trading prompts.
- Every AI statement has a visible evidence control.
- Confidence and freshness are first-class UI elements.
- Professional exports to PDF, CSV, Slack, Teams, email, and webhooks.

## 8. Folder Structure

```text
financial-intelligence-os/
  apps/
    web/                         # Next.js institutional dashboard
    mobile/                      # React Native mobile client
    admin/                       # Governance and source-management console
  services/
    api/                         # FastAPI public and internal APIs
    ingestion/                   # Source connectors and parsers
    verification/                # Source verification and provenance checks
    event-engine/                # Event extraction, dedupe, classification
    graph-service/               # Neo4j graph APIs and propagation
    impact-engine/               # Market impact and stocks-to-watch logic
    portfolio-engine/            # Exposure and portfolio alerts
    simulation-engine/           # Financial digital twin
    earnings-engine/             # Transcript and guidance intelligence
    fraud-engine/                # Governance and anomaly detection
    model-gateway/               # OpenAI/Claude/Gemini routing and policies
    report-service/              # Evidence-bound report generation
  packages/
    schemas/                     # Avro/JSON schemas and Pydantic models
    ui/                          # Shared TypeScript UI components
    auth/                        # Auth, entitlement, and policy helpers
    observability/               # Logging, tracing, metrics
  infra/
    terraform/                   # AWS, Cloudflare, networking, IAM
    kubernetes/                  # Helm charts and service manifests
    kafka/                       # Topics, ACLs, schema registry
    db/                          # PostgreSQL, ClickHouse, Neo4j migrations
  ml/
    evals/                       # Hallucination, citation, extraction evals
    prompts/                     # Versioned prompts and tool policies
    notebooks/                   # Research notebooks, never production truth
  docs/
    architecture/                # System design documents
    runbooks/                    # Incident and operations runbooks
    compliance/                  # Security and regulatory documentation
```

## 9. Deployment Architecture

### AWS Reference Deployment

- **Cloudflare:** WAF, DDoS protection, bot protection, CDN, Zero Trust access.
- **AWS Route 53 and ACM:** DNS and certificates.
- **EKS:** Kubernetes workloads for APIs, agents, ingestion, and streaming consumers.
- **MSK or Confluent Cloud:** Kafka topics, replication, schema registry, and ACLs.
- **RDS PostgreSQL:** Transactional source, evidence, event, portfolio, and audit data.
- **ClickHouse Cloud or self-managed ClickHouse:** High-volume time-series analytics.
- **Neo4j AuraDS or clustered Neo4j:** Graph intelligence and propagation.
- **Amazon OpenSearch or Elastic Cloud:** Search indexes.
- **Qdrant Cloud or Kubernetes Qdrant:** Vector retrieval.
- **S3:** Immutable raw payloads, filings, transcripts, attachments, model artifacts, and audit exports.
- **KMS and Secrets Manager:** Encryption keys and secrets.
- **OpenTelemetry, Prometheus, Grafana, Loki:** Observability.
- **PagerDuty/Opsgenie:** Operational alerts.

### Environments

- **Development:** Small single-region stack with synthetic and sandbox data.
- **Staging:** Production-like data contracts, replay testing, and model eval gates.
- **Production:** Multi-AZ, cross-region disaster recovery, strict entitlements, and audit logging.
- **Institutional Dedicated:** Optional isolated VPC, private connectivity, customer-managed keys, and data residency controls.

## 10. Cost Estimates

Costs vary sharply with data licensing and real-time market data. Approximate monthly infrastructure estimates excluding premium data licenses:

| Stage | Users / Load | Estimated Infra | Notes |
| --- | ---: | ---: | --- |
| Prototype | 5-20 internal users | `$3k-$8k` | Managed Postgres, small Kafka, small Neo4j, Qdrant, basic observability. |
| MVP | 500-2,000 users | `$20k-$60k` | Production EKS, MSK/Confluent, ClickHouse, OpenSearch, model gateway, monitoring. |
| Growth | 10k-50k users | `$100k-$350k` | Multi-region read, higher Kafka retention, larger ClickHouse, more AI calls and alerts. |
| Institutional | 100k+ users or enterprise desks | `$500k+` | Dedicated tenants, low-latency feeds, enterprise graph, DR, compliance, premium support. |

Potential additional monthly data costs:

- Real-time exchange data can range from thousands to millions depending on venues, redistribution rights, and user entitlements.
- Licensed news wires and transcript providers may be a major fixed cost.
- Alternative data such as shipping, job postings, card data, or satellite-derived indicators can materially exceed infrastructure costs.

## 11. Scaling Strategy

### Data Scaling

- Partition Kafka topics by source, jurisdiction, event type, and entity hash.
- Store immutable raw data in S3 and compacted metadata in PostgreSQL.
- Use ClickHouse for market, macro, and signal analytics instead of overloading PostgreSQL.
- Incrementally update Neo4j subgraphs by event and entity rather than rebuilding the global graph.
- Maintain embedding versioning and lazy re-embedding queues.

### Compute Scaling

- Autoscale ingestion and agent workers by Kafka lag.
- Use priority queues for official-source events, portfolio-impacting events, and market-moving alerts.
- Cache graph neighborhoods and common GraphRAG retrieval bundles.
- Route simpler extraction tasks to cheaper models and reserve frontier models for high-impact reasoning and adjudication.
- Use backpressure and graceful degradation: publish verified factual alerts first, then attach deeper impact reports as they complete.

### Product Scaling

- Start with U.S. and India official sources, then expand to Europe, Japan, China, and global institutions.
- Build entity master data and graph quality before broad source expansion.
- Introduce institutional entitlements early to avoid re-architecting data rights later.

## 12. Security Architecture

### Core Controls

- SSO with SAML/OIDC, MFA, SCIM provisioning, and role-based access control.
- Attribute-based entitlements by data source, exchange license, jurisdiction, portfolio, and organization.
- Encryption at rest with KMS and in transit with TLS 1.3.
- Private subnets for databases and model gateway egress controls.
- Secrets in AWS Secrets Manager or Vault, never in environment files committed to source.
- Tamper-evident audit logs for user actions, model outputs, admin changes, and data mutations.
- Row-level security for portfolios and enterprise workspaces.
- DLP controls for uploaded portfolios and client-sensitive documents.
- Vendor isolation through a model gateway that strips restricted data unless explicitly permitted.
- SOC 2 Type II roadmap, ISO 27001 roadmap, and institutional penetration testing.

### AI Security

- Prompt injection detection for source documents and web content.
- Tool allowlists by agent role.
- No arbitrary browsing or tool access from report-composition agents.
- Strict JSON schemas for model outputs.
- Retrieval boundary enforcement so agents cannot cite unlicensed or unauthorized content.
- Human review queue for high-impact, low-confidence, disputed, or legally sensitive outputs.

## 13. Hallucination Prevention Framework

### Non-Negotiable Rules

1. No claim without an evidence ID.
2. No number without a source, timestamp, unit, and freshness indicator.
3. No quote unless it is extracted from a source span.
4. No market price unless it comes from an entitled market data source and includes time and venue or delay status.
5. No prediction without assumptions, reasoning path, confidence score, and scenario label.
6. No social media as a primary source.
7. No anonymous rumor publication.
8. No unsupported graph edge in impact propagation.
9. No report publication if the evidence auditor fails.
10. Always abstain when evidence is insufficient.

### Confidence Scoring

The confidence score combines:

- Source trust tier and source authentication.
- Evidence span quality and extraction certainty.
- Corroboration from independent trusted sources.
- Contradiction count and retraction state.
- Entity resolution confidence.
- Graph edge confidence and path decay.
- Market data freshness.
- Historical model calibration.
- Human review status.

Confidence bands:

- `Very high`: official or issuer source, direct evidence, no contradiction, high extraction certainty.
- `High`: trusted source and corroboration, minor ambiguity resolved.
- `Medium`: credible but indirect or partially model-derived relationship.
- `Low`: weak propagation, incomplete evidence, or unresolved ambiguity; user-facing system should usually abstain or label clearly.

### Evidence-First Generation

The report composer receives only verified structured inputs:

- `facts[]` with evidence spans.
- `numbers[]` with units, source, timestamp, and calculation lineage.
- `quotes[]` with exact spans.
- `graph_paths[]` with edge evidence.
- `impact_assessments[]` with assumptions and confidence.

If the composer attempts to add any claim not present in the input manifest, the evidence auditor rejects the output.

## 14. Development Roadmap

### Phase 0: Foundations

- Source registry, evidence model, entity schema, audit logs, and model gateway.
- Initial official connectors for SEC, Federal Reserve, Treasury, NSE/BSE/RBI/SEBI, and major issuer press releases.
- Internal event workbench and evidence browser.

### Phase 1: MVP Intelligence

- Event extraction, entity resolution, canonical event pages, source links, and confidence scoring.
- Initial Neo4j graph for countries, currencies, central banks, sectors, industries, companies, commodities, ETFs, and indices.
- Stocks-to-watch engine with first- and second-order graph propagation.
- Portfolio upload and event exposure alerts.

### Phase 2: Professional Platform

- Real-time command center, analyst workbench, earnings intelligence, early signal dashboard, and digital twin simulator.
- Historical analogs using event memory and ClickHouse market reaction windows.
- Mobile app and push alerts.

### Phase 3: Institutional Platform

- Entitlements, dedicated tenants, advanced audit exports, compliance controls, SSO/SCIM, private deployments.
- Expanded data coverage across China, Japan, Europe, IMF, World Bank, WTO, OPEC, and licensed news.
- Client-specific knowledge graphs and portfolio risk integrations.

### Phase 4: Terminal-Grade Ecosystem

- API marketplace, custom factor models, research notebook integration, execution-system integrations, and enterprise workflow automation.
- Human analyst contribution system with review and provenance controls.

## 15. MVP Plan

### MVP Scope

The MVP should prove that the system can produce trusted, evidence-backed financial intelligence faster and more clearly than existing tools.

Included:

- Official source monitoring for SEC, Federal Reserve, Treasury, NSE, BSE, RBI, SEBI, and selected issuer IR pages.
- Licensed or manually approved trusted news source integration.
- Event intelligence pages with what happened, why it matters, impact, confidence, evidence, and source links.
- Initial global graph covering U.S. and India markets plus core macro relationships.
- Stocks-to-watch engine for equities, sectors, ETFs, commodities, and currencies.
- Portfolio upload with event exposure alerts.
- Digital twin v1 for oil, rates, FX, and commodity scenarios.
- Admin console for source registry, policy failures, and human review.

Excluded from MVP:

- Full global exchange coverage.
- Full redistribution of real-time exchange prices unless licensed.
- Autonomous trading or investment advice.
- Unverified social-media ingestion.

### MVP Success Metrics

- 99%+ published claim citation coverage.
- Less than 1% material factual correction rate after human review.
- Median official-source event detection under 30 seconds after source availability.
- Median event report publication under 2 minutes for simple events.
- Entity resolution precision above 95% for covered securities.
- Portfolio alert relevance above 80% in analyst review.

## 16. Institutional Version Plan

### Institutional Features

- Dedicated tenant or private VPC deployment.
- Customer-managed encryption keys.
- Fine-grained data entitlements and exchange-license enforcement.
- SAML/OIDC SSO, SCIM, RBAC, ABAC, and approval workflows.
- Custom knowledge graph overlays for client portfolios, counterparties, suppliers, and watchlists.
- Portfolio and risk-system integrations with Aladdin-like exposure views.
- API and webhook SLAs.
- Human analyst review workflows and report approval chains.
- Compliance exports for audit, model lineage, and decision support.
- On-premise or private-cloud model gateway options.

### Institutional Operating Model

- 24/7 source ingestion monitoring.
- Data quality operations team for entity resolution and graph maintenance.
- Model risk management team for evaluations, drift, and prompt/version governance.
- Security and compliance team for SOC 2, ISO 27001, vendor reviews, and incident response.
- Analyst advisory team for domain validation across macro, equities, credit, commodities, and geopolitics.

## Product Differentiation

The defensible advantage is not a chat interface. It is the combination of trusted ingestion, immutable evidence, graph-based financial causality, real-time event processing, calibrated confidence, portfolio awareness, and institutional governance. The system wins when users trust that every sentence can be traced, every number can be checked, every forecast is framed as a scenario, and every alert explains what to watch next.

-- Financial Intelligence OS core schema blueprint.
-- PostgreSQL owns transactional truth, ClickHouse owns time-series analytics,
-- Elasticsearch owns lexical search, Qdrant owns vector retrieval, and Neo4j owns graph propagation.

CREATE SCHEMA IF NOT EXISTS fio;

CREATE TYPE fio.source_tier AS ENUM ('official', 'exchange', 'issuer', 'trusted_news', 'licensed_data', 'derived');
CREATE TYPE fio.verification_status AS ENUM ('pending', 'verified', 'disputed', 'rejected');
CREATE TYPE fio.event_status AS ENUM ('candidate', 'deduplicated', 'enriched', 'published', 'retracted');
CREATE TYPE fio.impact_direction AS ENUM ('bullish', 'neutral', 'bearish', 'mixed');
CREATE TYPE fio.confidence_band AS ENUM ('low', 'medium', 'high', 'very_high');

CREATE TABLE fio.sources (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    jurisdiction TEXT,
    source_tier fio.source_tier NOT NULL,
    canonical_url TEXT NOT NULL UNIQUE,
    license_terms TEXT,
    trust_score NUMERIC(5,4) NOT NULL CHECK (trust_score >= 0 AND trust_score <= 1),
    requires_human_review BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fio.raw_documents (
    id UUID PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES fio.sources(id),
    source_url TEXT NOT NULL,
    source_published_at TIMESTAMPTZ,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    content_hash TEXT NOT NULL UNIQUE,
    title TEXT,
    language_code TEXT NOT NULL DEFAULT 'en',
    raw_text TEXT NOT NULL,
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    verification_status fio.verification_status NOT NULL DEFAULT 'pending'
);

CREATE TABLE fio.evidence_spans (
    id UUID PRIMARY KEY,
    document_id UUID NOT NULL REFERENCES fio.raw_documents(id),
    char_start INTEGER NOT NULL CHECK (char_start >= 0),
    char_end INTEGER NOT NULL CHECK (char_end > char_start),
    extracted_text TEXT NOT NULL,
    claim_type TEXT NOT NULL,
    checksum TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fio.entities (
    id UUID PRIMARY KEY,
    entity_type TEXT NOT NULL,
    canonical_name TEXT NOT NULL,
    country_code TEXT,
    identifiers JSONB NOT NULL DEFAULT '{}'::jsonb,
    aliases TEXT[] NOT NULL DEFAULT '{}',
    graph_node_id TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (entity_type, canonical_name, country_code)
);

CREATE TABLE fio.events (
    id UUID PRIMARY KEY,
    event_type TEXT NOT NULL,
    headline TEXT NOT NULL,
    canonical_summary TEXT NOT NULL,
    event_time TIMESTAMPTZ,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status fio.event_status NOT NULL DEFAULT 'candidate',
    confidence_score NUMERIC(5,4) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    confidence_band fio.confidence_band NOT NULL,
    primary_source_id UUID NOT NULL REFERENCES fio.sources(id),
    primary_document_id UUID NOT NULL REFERENCES fio.raw_documents(id),
    contradiction_count INTEGER NOT NULL DEFAULT 0,
    model_version TEXT NOT NULL,
    evidence_manifest JSONB NOT NULL DEFAULT '[]'::jsonb
);

CREATE TABLE fio.event_entities (
    event_id UUID NOT NULL REFERENCES fio.events(id),
    entity_id UUID NOT NULL REFERENCES fio.entities(id),
    role TEXT NOT NULL,
    relevance_score NUMERIC(5,4) NOT NULL CHECK (relevance_score >= 0 AND relevance_score <= 1),
    evidence_span_id UUID REFERENCES fio.evidence_spans(id),
    PRIMARY KEY (event_id, entity_id, role)
);

CREATE TABLE fio.impact_assessments (
    id UUID PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES fio.events(id),
    entity_id UUID NOT NULL REFERENCES fio.entities(id),
    impact_channel TEXT NOT NULL,
    direction fio.impact_direction NOT NULL,
    magnitude_score NUMERIC(6,4) NOT NULL CHECK (magnitude_score >= -1 AND magnitude_score <= 1),
    time_horizon TEXT NOT NULL,
    reasoning TEXT NOT NULL,
    confidence_score NUMERIC(5,4) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    evidence_span_ids UUID[] NOT NULL DEFAULT '{}',
    assumptions JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fio.agent_runs (
    id UUID PRIMARY KEY,
    event_id UUID REFERENCES fio.events(id),
    agent_name TEXT NOT NULL,
    model_provider TEXT NOT NULL,
    model_name TEXT NOT NULL,
    prompt_hash TEXT NOT NULL,
    input_evidence_ids UUID[] NOT NULL DEFAULT '{}',
    output_json JSONB NOT NULL,
    confidence_score NUMERIC(5,4) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    passed_policy_checks BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fio.portfolios (
    id UUID PRIMARY KEY,
    owner_id UUID NOT NULL,
    name TEXT NOT NULL,
    base_currency TEXT NOT NULL DEFAULT 'USD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fio.portfolio_positions (
    portfolio_id UUID NOT NULL REFERENCES fio.portfolios(id),
    entity_id UUID NOT NULL REFERENCES fio.entities(id),
    quantity NUMERIC(28,8) NOT NULL,
    average_cost NUMERIC(28,8),
    currency TEXT NOT NULL,
    as_of TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (portfolio_id, entity_id, as_of)
);

CREATE TABLE fio.audit_log (
    id UUID PRIMARY KEY,
    actor_type TEXT NOT NULL,
    actor_id TEXT NOT NULL,
    action TEXT NOT NULL,
    object_type TEXT NOT NULL,
    object_id TEXT NOT NULL,
    before_state JSONB,
    after_state JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ClickHouse tables should mirror high-volume immutable facts:
-- market_ticks, economic_series_observations, entity_signal_features,
-- event_impact_timeseries, portfolio_exposure_snapshots, and agent_quality_metrics.

-- Elasticsearch indexes:
-- documents_v1(title, body, source, jurisdiction, language, timestamps)
-- evidence_spans_v1(extracted_text, claim_type, entity_ids)
-- events_v1(headline, canonical_summary, event_type, impacted_entities)

-- Qdrant collections:
-- document_chunks_bge, evidence_spans_openai, event_memory_bge, earnings_call_segments_bge.

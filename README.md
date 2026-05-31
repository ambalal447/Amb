# AI-Powered Financial Intelligence Operating System

This repository contains the institutional product and architecture blueprint for a zero-hallucination Financial Intelligence Operating System: an AI-first platform designed to explain market-moving events, trace evidence, propagate impact through a global knowledge graph, and continuously monitor portfolios and macro exposures.

Start with the full blueprint:

- [Financial Intelligence OS Architecture](docs/financial-intelligence-os.md)
- [PostgreSQL / ClickHouse / Elasticsearch / Qdrant schema blueprint](architecture/sql/core_schema.sql)
- [Neo4j graph model and constraints](architecture/neo4j/graph_model.cypher)

## Preview

You can preview the product concept without installing any dependencies:

1. Open `preview/index.html` directly in your browser, or
2. Run a local static server from the repository root:

```bash
python3 -m http.server 4173
```

Then visit <http://localhost:4173/preview/>.

The preview is a static, dark-mode command-center mockup that visualizes the architecture blueprint, event pipeline, AI-agent roster, graph propagation example, and zero-hallucination guardrails.

// Financial Intelligence OS Neo4j graph model.
// Neo4j stores durable relationships used for GraphRAG, impact propagation, and scenario simulation.

CREATE CONSTRAINT country_code IF NOT EXISTS FOR (n:Country) REQUIRE n.code IS UNIQUE;
CREATE CONSTRAINT currency_code IF NOT EXISTS FOR (n:Currency) REQUIRE n.code IS UNIQUE;
CREATE CONSTRAINT company_id IF NOT EXISTS FOR (n:Company) REQUIRE n.entity_id IS UNIQUE;
CREATE CONSTRAINT security_id IF NOT EXISTS FOR (n:Security) REQUIRE n.entity_id IS UNIQUE;
CREATE CONSTRAINT commodity_code IF NOT EXISTS FOR (n:Commodity) REQUIRE n.code IS UNIQUE;
CREATE CONSTRAINT event_id IF NOT EXISTS FOR (n:Event) REQUIRE n.event_id IS UNIQUE;
CREATE CONSTRAINT policy_id IF NOT EXISTS FOR (n:Policy) REQUIRE n.policy_id IS UNIQUE;

// Node labels:
// Country, CentralBank, Currency, Company, Security, ETF, Index, Industry, Sector,
// Commodity, Facility, Port, Executive, Investor, Policy, Regulation, Event, Source,
// Filing, EarningsCall, MacroSeries, SupplyChainComponent.

// Core relationship vocabulary with required evidence metadata on every factual edge:
// (:Country)-[:ISSUES_CURRENCY]->(:Currency)
// (:CentralBank)-[:SETS_POLICY_RATE_FOR]->(:Currency)
// (:Company)-[:LISTED_ON]->(:Exchange)
// (:Security)-[:TRACKS_COMPANY]->(:Company)
// (:Company)-[:OPERATES_IN]->(:Country)
// (:Company)-[:MEMBER_OF]->(:Industry)
// (:Industry)-[:PART_OF]->(:Sector)
// (:Company)-[:SUPPLIES {revenue_share, confidence, evidence_ids}]->(:Company)
// (:Commodity)-[:INPUT_TO {cost_share, confidence, evidence_ids}]->(:Industry)
// (:Policy)-[:AFFECTS {channel, direction, confidence, evidence_ids}]->(:Industry)
// (:Event)-[:MENTIONS {role, confidence, evidence_ids}]->(:Company)
// (:Event)-[:IMPACTS {channel, direction, magnitude, horizon, confidence, evidence_ids}]->(:Security)
// (:Executive)-[:LEADS {title, start_date, confidence, evidence_ids}]->(:Company)
// (:Investor)-[:OWNS {percent, as_of, confidence, evidence_ids}]->(:Security)

// Example impact path:
MERGE (china:Country {code: 'CN', name: 'China'})
MERGE (rareEarths:Commodity {code: 'RARE_EARTHS', name: 'Rare earth elements'})
MERGE (evIndustry:Industry {name: 'Electric vehicles'})
MERGE (batteryIndustry:Industry {name: 'Battery manufacturing'})
MERGE (lithium:Commodity {code: 'LITHIUM', name: 'Lithium'})
MERGE (china)-[:EXPORTS {confidence: 0.95, evidence_policy: 'official_trade_data_required'}]->(rareEarths)
MERGE (rareEarths)-[:INPUT_TO {confidence: 0.90, evidence_policy: 'supply_chain_source_required'}]->(evIndustry)
MERGE (evIndustry)-[:DEMAND_DRIVER_FOR {confidence: 0.85, evidence_policy: 'industry_model_required'}]->(batteryIndustry)
MERGE (batteryIndustry)-[:DEMAND_DRIVER_FOR {confidence: 0.85, evidence_policy: 'commodity_model_required'}]->(lithium);

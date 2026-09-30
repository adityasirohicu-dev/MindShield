"""Gateway routing note: modules are split by router today and can be extracted behind this prefix map."""

SERVICE_PREFIXES = {
    "auth-consent": ["/v1/auth", "/v1/consent"],
    "wellness": ["/v1/checkins"],
    "context-data": ["/v1/context"],
    "sensor-ingestion": ["/v1/sensors"],
    "risk-engine": ["/v1/risk"],
    "counselling": ["/v1/counselling"],
    "audit": ["/v1/audit"],
    "privacy": ["/v1/privacy"],
    "org": ["/v1/org"],
    "wearables": ["/v1/wearables"],
}

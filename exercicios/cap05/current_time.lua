function add_ingest_timestamp(tag, timestamp, record)
    -- Gera a data atual no formato ISO8601 (Ex: 2026-03-04T22:15:00Z)
    record["ingest_timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    return 1, timestamp, record
end

function cb_filter(tag, timestamp, record)
  -- Classificar saúde do container baseado em métricas
  local memory_mb = tonumber(record['memory_mb'] or 0)
  local cpu_percent = tonumber(record['cpu_percent'] or 0)
  local status = record['status'] or 'unknown'

  -- Determinar status de saúde
  if status == 'healthy' then
    record['health_status'] = 'ok'
    record['severity'] = 'low'
  elseif status == 'unhealthy' then
    record['health_status'] = 'critical'
    record['severity'] = 'high'
  else
    record['health_status'] = 'unknown'
    record['severity'] = 'medium'
  end

  -- Alertar se CPU alto
  if cpu_percent > 80 then
    record['alert_high_cpu'] = true
    record['cpu_severity'] = 'high'
  elseif cpu_percent > 50 then
    record['alert_high_cpu'] = false
    record['cpu_severity'] = 'medium'
  else
    record['alert_high_cpu'] = false
    record['cpu_severity'] = 'low'
  end

  -- Alertar se memória alta
  if memory_mb > 300 then
    record['alert_high_memory'] = true
    record['memory_severity'] = 'high'
  elseif memory_mb > 150 then
    record['alert_high_memory'] = false
    record['memory_severity'] = 'medium'
  else
    record['alert_high_memory'] = false
    record['memory_severity'] = 'low'
  end

  -- Adicionar timestamp de processamento
  local now = os.time()
  record['processed_at'] = os.date('!%Y-%m-%dT%H:%M:%SZ', now)

  -- Adicionar identificador de evento para deduplicação
  if record['container'] then
    record['event_key'] = record['container'] .. ':' .. tostring(timestamp)
  end

  return 1, timestamp, record
end

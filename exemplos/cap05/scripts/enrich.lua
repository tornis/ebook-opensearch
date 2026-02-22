function cb_filter(tag, timestamp, record)
  -- Normalizar nível para minúsculas
  if record['level'] then
    record['level'] = string.lower(record['level'])
  end

  -- Converter preço de string para número (remove "R$" e espaços)
  if record['price'] then
    local price_str = string.gsub(record['price'], 'R$', '')
    price_str = string.gsub(price_str, ' ', '')
    record['price'] = tonumber(price_str) or 0
  end

  -- Classificar por valor
  if record['price'] then
    if record['price'] > 1000 then
      record['value_category'] = 'high'
    elseif record['price'] > 100 then
      record['value_category'] = 'medium'
    else
      record['value_category'] = 'low'
    end
  end

  -- Adicionar timestamp de processamento (ISO 8601)
  local now = os.time()
  local datestr = os.date('!%Y-%m-%dT%H:%M:%SZ', now)
  record['processed_at'] = datestr

  -- Classificar por severidade
  local level = record['level'] or 'unknown'
  if level == 'error' then
    record['severity'] = 'high'
    record['should_alert'] = true
  elseif level == 'warn' then
    record['severity'] = 'medium'
    record['should_alert'] = false
  else
    record['severity'] = 'low'
    record['should_alert'] = false
  end

  -- Descartar logs de debug
  if level == 'debug' then
    return -1, 0, nil
  end

  return 1, timestamp, record
end

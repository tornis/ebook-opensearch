---============================================================================
--- Lua Script: Sampling Inteligente de Logs Apache
---
--- Descrição:
---   Implementa política de captura seletiva baseada em HTTP status code:
---   - HTTP 200: Captura 10% das requisições (sampling)
---   - HTTP 400, 500: Captura 100% das requisições (todos os erros)
---   - Outros: Captura 100% por padrão
---
--- Como funciona:
---   1. Extrai o status code do log
---   2. Define critério de sampling baseado no status
---   3. Gera número aleatório e compara com threshold
---   4. Retorna 1 (incluir) ou 0 (descartar)
---
---============================================================================

function apply_sampling(tag, timestamp, record)
    -- Extrair status code do record
    local status_code = tonumber(record["code"])

    -- Se não conseguiu extrair status, incluir por segurança
    if not status_code then
        return 2, timestamp, record
    end

    -- Definir política de sampling
    local sample_rate = 1.0  -- padrão: incluir tudo

    if status_code == 200 then
        -- HTTP 200: Apenas 10% das requisições
        sample_rate = 0.10
    elseif status_code == 400 or status_code == 401 or status_code == 403 or status_code == 404 then
        -- HTTP 4xx: Incluir todos (100%)
        sample_rate = 1.0
    elseif status_code == 500 or status_code == 502 or status_code == 503 or status_code == 504 then
        -- HTTP 5xx: Incluir todos (100%)
        sample_rate = 1.0
    else
        -- Outros status: Incluir todos (100%)
        sample_rate = 1.0
    end

    -- Gerar número aleatório entre 0 e 1
    local random_value = math.random()

    -- Comparar com sample_rate
    if random_value <= sample_rate then
        -- Incluir este log - adicionar metadata de sampling
        record["_sampling_rate"] = tostring(sample_rate * 100) .. "%"
        record["_sampled"] = "true"
        return 2, timestamp, record
    else
        -- Descartar este log
        return -1
    end
end

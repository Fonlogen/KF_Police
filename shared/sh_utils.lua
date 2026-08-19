--[[
    KF_Police - Utilita' condivise
]]

--- Traduzione. Ricade sulla chiave se il locale non ha la voce.
function Locale(key, ...)
    local locale = Locales and Locales[Config.Locale] or {}
    local value = locale[key]

    if not value then
        local fallback = Locales and Locales['en'] or {}
        value = fallback[key] or key
    end

    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, value, ...)
        if ok then
            return formatted
        end
    end

    return value
end

function DecodeJson(value, fallback)
    if type(value) == 'table' then
        return value
    end

    if type(value) ~= 'string' or value == '' then
        return fallback or {}
    end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end

    return fallback or {}
end

function EncodeJson(value)
    if type(value) == 'string' then
        return value
    end

    return json.encode(value or {})
end

function TableCount(tbl)
    local count = 0
    if type(tbl) ~= 'table' then
        return count
    end

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

--- Trasforma una mappa o una lista in una lista Lua contigua.
function NormalizeList(value)
    local decoded = DecodeJson(value, {})
    local list = {}

    if decoded[1] ~= nil then
        for _, item in ipairs(decoded) do
            list[#list + 1] = item
        end
        return list
    end

    for _, item in pairs(decoded) do
        list[#list + 1] = item
    end

    return list
end

--- Toglie gli spazi ai bordi. Ritorna sempre una stringa.
function Trim(value)
    if value == nil then
        return ''
    end

    return (tostring(value):gsub('^%s+', ''):gsub('%s+$', ''))
end

--- Sanifica un testo proveniente dalla NUI: trim + taglio alla lunghezza max.
--- @param value any
--- @param maxLength number|nil
--- @return string
function SanitizeText(value, maxLength)
    local text = Trim(value)

    -- Via i caratteri di controllo, che nella NUI romperebbero il rendering.
    text = text:gsub('[%c]', function(c)
        return c == '\n' and '\n' or ' '
    end)

    if maxLength and #text > maxLength then
        text = text:sub(1, maxLength)
    end

    return text
end

--- Rimuove le emoji da un testo.
--- Il progetto usa esclusivamente icone FontAwesome: le emoji ereditate dai
--- vecchi seed (kf_police_tags) vengono ripulite dalla migrazione.
--- Vengono preservati i caratteri tipografici (U+2000-U+22FF: apici, dash).
function StripEmoji(text)
    if type(text) ~= 'string' then
        return text
    end

    -- Sequenze UTF-8 a 4 byte: emoticon, pittogrammi, bandiere.
    text = text:gsub('[\240-\244][\128-\191][\128-\191][\128-\191]', '')
    -- U+2300 e oltre nel blocco E2: simboli vari e dingbats.
    text = text:gsub('\226[\140-\191][\128-\191]', '')
    -- Blocco E3: simboli CJK racchiusi.
    text = text:gsub('\227[\128-\191][\128-\191]', '')
    -- Selettori di variazione (U+FE0E / U+FE0F).
    text = text:gsub('\239\184[\142\143]', '')

    return Trim(text)
end

--- Numero intero entro un intervallo, con valore di riserva.
function ClampInt(value, min, max, fallback)
    local number = math.floor(tonumber(value) or fallback or 0)

    if min and number < min then
        number = min
    end
    if max and number > max then
        number = max
    end

    return number
end

--- Vero per true, 1, '1', 'true'.
function ToBool(value)
    return value == true or value == 1 or value == '1' or value == 'true'
end

--- Normalizza una targa: maiuscole, senza spazi ai bordi.
function NormalizePlate(plate)
    if not plate then
        return nil
    end

    local normalized = Trim(plate):upper()
    if normalized == '' then
        return nil
    end

    return normalized
end

--- Etichetta di durata leggibile a partire da secondi (es. "12m 30s").
function FormatDuration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local rest = seconds % 60

    if hours > 0 then
        return ('%dh %02dm'):format(hours, minutes)
    end
    if minutes > 0 then
        return ('%dm %02ds'):format(minutes, rest)
    end

    return ('%ds'):format(rest)
end

--- Timestamp SQL corrente.
function SqlNow()
    return os.date('%Y-%m-%d %H:%M:%S')
end

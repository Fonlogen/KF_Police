function Locale(key)
    local locale = Locales and Locales[Config.Locale] or {}
    return locale[key] or key
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

function ToObjectMap(list, keyField)
    local map = {}
    if type(list) ~= 'table' then
        return map
    end

    if list[1] ~= nil then
        for _, item in ipairs(list) do
            if type(item) == 'table' then
                local key = item[keyField] or item.id
                if key ~= nil then
                    map[tostring(key)] = item
                end
            end
        end
        return map
    end

    for key, item in pairs(list) do
        map[tostring(key)] = item
    end

    return map
end

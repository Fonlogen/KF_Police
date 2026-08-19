--[[
    KF_Police - Accesso al database
    ----------------------------------------------------------------------------
    CORREZIONE BUG L9
    ----------------------------------------------------------------------------
    Il vecchio `safeQuery` inghiottiva gli errori e ritornava `{}`: un errore SQL
    diventava indistinguibile da "nessun dato". Qui un errore ritorna `nil` e
    viene stampato con il punto di chiamata, mentre "nessun dato" resta `{}`.

    CORREZIONE Config.AutoDatabaseCreation
    ----------------------------------------------------------------------------
    Lo schema non e' piu' scritto a mano dentro il Lua: viene caricato da
    sql/install.sql, cosi' schema e codice non possono divergere.
]]

Database = {}

local ready = false
local readyWaiters = {}

--- Vero quando schema e migrazioni sono stati applicati.
function Database.IsReady()
    return ready
end

--- Blocca fino a quando il database e' pronto (max `timeout` ms).
function Database.WaitReady(timeout)
    if ready then
        return true
    end

    local deadline = GetGameTimer() + (timeout or 15000)
    while not ready and GetGameTimer() < deadline do
        Wait(50)
    end

    return ready
end

local function markReady()
    ready = true
    for _, cb in ipairs(readyWaiters) do
        pcall(cb)
    end
    readyWaiters = {}
end

function Database.OnReady(cb)
    if ready then
        return cb()
    end
    readyWaiters[#readyWaiters + 1] = cb
end

-- ============================================================================
--  Wrapper delle query
-- ============================================================================

local function fail(kind, query, err)
    local snippet = tostring(query):gsub('%s+', ' '):sub(1, 160)
    print(('^1[KF_Police] %s fallita: %s^7'):format(kind, tostring(err)))
    print(('^3[KF_Police]   query: %s^7'):format(snippet))
end

--- @return table|nil righe, nil in caso di errore
function Database.Query(query, params)
    local ok, result = pcall(MySQL.query.await, query, params or {})

    if not ok then
        fail('Query', query, result)
        return nil
    end

    return result or {}
end

--- @return any|nil
function Database.Scalar(query, params)
    local ok, result = pcall(MySQL.scalar.await, query, params or {})

    if not ok then
        fail('Scalar', query, result)
        return nil
    end

    return result
end

--- @return table|nil prima riga
function Database.Single(query, params)
    local ok, result = pcall(MySQL.single.await, query, params or {})

    if not ok then
        fail('Single', query, result)
        return nil
    end

    return result
end

--- @return number|nil id inserito
function Database.Insert(query, params)
    local ok, result = pcall(MySQL.insert.await, query, params or {})

    if not ok then
        fail('Insert', query, result)
        return nil
    end

    return result
end

--- @return number|nil righe modificate
function Database.Update(query, params)
    local ok, result = pcall(MySQL.update.await, query, params or {})

    if not ok then
        fail('Update', query, result)
        return nil
    end

    return result
end

--- Transazione atomica: o tutte le query passano, o nessuna.
--- @param queries table lista di { query, params }
--- @return boolean
function Database.Transaction(queries)
    if type(queries) ~= 'table' or #queries == 0 then
        return true
    end

    local ok, result = pcall(MySQL.transaction.await, queries)

    if not ok then
        fail('Transaction', queries[1] and queries[1][1] or '?', result)
        return false
    end

    return result ~= false
end

-- ============================================================================
--  Introspezione
-- ============================================================================

function Database.TableExists(tableName)
    local count = Database.Scalar([[
        SELECT COUNT(*) FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
    ]], { tableName })

    return (tonumber(count) or 0) > 0
end

function Database.ColumnExists(tableName, columnName)
    local count = Database.Scalar([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { tableName, columnName })

    return (tonumber(count) or 0) > 0
end

--- Aggiunge una colonna solo se manca. Portabile: nessun IF NOT EXISTS.
--- @param definition string es. "`status` VARCHAR(16) NOT NULL DEFAULT 'open'"
function Database.AddColumnIfMissing(tableName, columnName, definition)
    if not Database.TableExists(tableName) then
        return false
    end

    if Database.ColumnExists(tableName, columnName) then
        return false
    end

    local result = Database.Query(('ALTER TABLE `%s` ADD COLUMN %s'):format(tableName, definition))
    if result then
        print(('[KF_Police] Colonna aggiunta: %s.%s'):format(tableName, columnName))
        return true
    end

    return false
end

-- ============================================================================
--  Esecuzione di file .sql
-- ============================================================================

--- Divide uno script SQL in istruzioni, rispettando stringhe e commenti.
--- @param script string
--- @return string[]
local function splitStatements(script)
    local statements = {}
    local buffer = {}
    local quote = nil
    local i = 1
    local length = #script

    while i <= length do
        local char = script:sub(i, i)

        if quote then
            buffer[#buffer + 1] = char
            if char == '\\' then
                -- carattere di escape: consuma anche il successivo
                i = i + 1
                buffer[#buffer + 1] = script:sub(i, i)
            elseif char == quote then
                quote = nil
            end
        elseif char == "'" or char == '"' or char == '`' then
            quote = char
            buffer[#buffer + 1] = char
        elseif char == '-' and script:sub(i + 1, i + 1) == '-' then
            -- commento di riga: salta fino al newline
            local newline = script:find('\n', i) or (length + 1)
            i = newline
            buffer[#buffer + 1] = '\n'
        elseif char == '/' and script:sub(i + 1, i + 1) == '*' then
            local close = script:find('*/', i + 2, true)
            i = (close or length) + 1
        elseif char == ';' then
            local statement = Trim(table.concat(buffer))
            if statement ~= '' then
                statements[#statements + 1] = statement
            end
            buffer = {}
        else
            buffer[#buffer + 1] = char
        end

        i = i + 1
    end

    local tail = Trim(table.concat(buffer))
    if tail ~= '' then
        statements[#statements + 1] = tail
    end

    return statements
end

--- Esegue un file .sql della risorsa.
--- @param path string percorso relativo alla risorsa
--- @return boolean ok, number eseguite, number fallite
function Database.RunSqlFile(path)
    local script = LoadResourceFile(GetCurrentResourceName(), path)
    if not script then
        print(('^1[KF_Police] File SQL non trovato: %s^7'):format(path))
        return false, 0, 0
    end

    local statements = splitStatements(script)
    local executed, failed = 0, 0

    for _, statement in ipairs(statements) do
        if Database.Query(statement) then
            executed = executed + 1
        else
            failed = failed + 1
        end
    end

    return failed == 0, executed, failed
end

-- ============================================================================
--  Avvio
-- ============================================================================

function Database.Install()
    local ok, executed, failed = Database.RunSqlFile('sql/install.sql')

    if failed > 0 then
        print(('^1[KF_Police] Schema: %d istruzioni fallite su %d^7'):format(failed, executed + failed))
    else
        print(('[KF_Police] Schema verificato (%d istruzioni)'):format(executed))
    end

    return ok
end

--- Dati iniziali. Girano DOPO le migrazioni: su un database preesistente le
--- colonne che i seed usano (icon, category_id, jail_months) vengono aggiunte
--- proprio dalla migrazione.
function Database.Seed()
    local ok, executed, failed = Database.RunSqlFile('sql/seed.sql')

    if failed > 0 then
        print(('^1[KF_Police] Dati iniziali: %d istruzioni fallite su %d^7'):format(failed, executed + failed))
    end

    return ok
end

CreateThread(function()
    -- Un attimo per lasciare che oxmysql apra la connessione.
    Wait(500)

    Database.Install()

    if Migrations and Migrations.Run then
        Migrations.Run()
    end

    Database.Seed()

    markReady()
end)

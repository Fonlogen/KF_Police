--[[
    KF_Police - Contratto del bridge framework
    ----------------------------------------------------------------------------
    Definisce l'interfaccia che i file cl_<framework>.lua e sv_<framework>.lua
    devono implementare, piu' le utilita' che non dipendono dal framework.

    Client:
      Framework.IsLoaded()                -> boolean
      Framework.GetJob()                  -> name, grade, gradeName, gradeLabel, jobLabel
      Framework.HasAllowedJob()           -> boolean
      Framework.GetIdentifier()           -> string|nil
      Framework.GetPlayerData()           -> table
      Framework.Notify(message, type)
      Framework.GetClosestPlayer(dist)    -> playerIndex, distance
      Framework.GetSex()                  -> 'male'|'female'

    Server:
      Framework.GetPlayer(src)                    -> player|nil
      Framework.GetPlayerFromIdentifier(id)       -> player|nil
      Framework.GetIdentifier(player)             -> string|nil
      Framework.GetName(player)                   -> string
      Framework.GetJob(player)                    -> name, grade, gradeName, gradeLabel
      Framework.GetSsn(player)                    -> string|nil
      Framework.GetSex(player)                    -> 'male'|'female'
      Framework.Notify(src, message, type)
      Framework.GetOnlinePlayers()                -> player[]
      Framework.RegisterUsableItem(item, cb)
      Framework.AddAccountMoney(player, account, amount)
      Framework.RemoveAccountMoney(player, account, amount)
      Framework.GetSocietyAccount(society)        -> account|nil
]]

--- Nomi dei gradi di riserva, se `job_grades` non fosse leggibile.
Config.DefaultGradeNames = {
    police = { [0] = 'recruit', [1] = 'officer', [2] = 'sergeant', [3] = 'lieutenant', [4] = 'boss' },
    ambulance = { [0] = 'ambulance', [1] = 'doctor', [2] = 'chief_doctor', [3] = 'chief_doctor', [4] = 'boss' },
}

--- Nome del grado a partire dall'indice, con riserva sulla tabella di default.
--- @param jobName string
--- @param grade number
--- @param known string|nil nome fornito dal framework, se disponibile
--- @return string
function ResolveGradeName(jobName, grade, known)
    if known and known ~= '' then
        return known
    end

    local defaults = Config.DefaultGradeNames[jobName]
    if defaults then
        return defaults[tonumber(grade) or 0] or defaults[0] or 'recruit'
    end

    return 'recruit'
end

--- Vero se il lavoro puo' aprire il MDT.
function IsAllowedJob(jobName)
    return jobName ~= nil and Config.AllowedJobs[jobName] == true
end

--- Vero se il lavoro e' considerato forze dell'ordine.
function IsPoliceJob(jobName)
    return jobName ~= nil and Config.PoliceJobs[jobName] == true
end

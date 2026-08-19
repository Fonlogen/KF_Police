# modules/framework/sh_bridge.lua

**Ruolo:** contratto documentato del bridge framework, più le utilità che non dipendono
dal framework.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, ultimo degli `shared_scripts`

## Cosa fa

Non contiene implementazione: **dichiara in un commento l'interfaccia** che
`cl_<framework>.lua` e `sv_<framework>.lua` devono rispettare, e definisce tre funzioni
che valgono per qualunque framework.

## Contratto

### Client (`modules/framework/cl_esx.lua`)

```
Framework.IsLoaded()             -> boolean
Framework.GetJob()               -> name, grade, gradeName, gradeLabel, jobLabel
Framework.HasAllowedJob()        -> boolean
Framework.GetIdentifier()        -> string|nil
Framework.GetPlayerData()        -> table
Framework.Notify(message, type)
Framework.GetClosestPlayer(dist) -> playerIndex, distance
Framework.GetSex()               -> 'male'|'female'
```

L'implementazione ESX aggiunge anche `HasPoliceJob()`, `GetSsn()` e `HasItem()`: **non
sono nel contratto ma sono usate**, quindi un bridge nuovo deve fornirle.

### Server (`modules/framework/sv_esx.lua`)

```
Framework.GetPlayer(src)                -> player|nil
Framework.GetPlayerFromIdentifier(id)   -> player|nil
Framework.GetIdentifier(player)         -> string|nil
Framework.GetName(player)               -> string
Framework.GetJob(player)                -> name, grade, gradeName, gradeLabel
Framework.GetSsn(player)                -> string|nil
Framework.GetSex(player)                -> 'male'|'female'
Framework.Notify(src, message, type)
Framework.GetOnlinePlayers()            -> player[]
Framework.RegisterUsableItem(item, cb)
Framework.AddAccountMoney(player, account, amount)
Framework.RemoveAccountMoney(player, account, amount)
Framework.GetSocietyAccount(society)    -> account|nil
```

L'implementazione ESX aggiunge `RemoveSocietyMoney` e `AddSocietyMoney`, usate da armeria
e garage.

## API pubblica

| Funzione | Comportamento |
|---|---|
| `ResolveGradeName(jobName, grade, known)` | usa `known` se valorizzato, altrimenti `Config.DefaultGradeNames`, altrimenti `'recruit'` |
| `IsAllowedJob(jobName)` | `Config.AllowedJobs[jobName] == true` |
| `IsPoliceJob(jobName)` | `Config.PoliceJobs[jobName] == true` |

`Config.DefaultGradeNames` è la tabella di riserva se `job_grades` non fosse leggibile:
`police` 0-4 → recruit/officer/sergeant/lieutenant/boss; `ambulance` 0-4 →
ambulance/doctor/chief_doctor/chief_doctor/boss.

## Note e trappole

- **Il nome del grado è la chiave di tre configurazioni** (`Config.Uniforms`,
  `Config.AuthorizedWeapons`, `Config.AuthorizedVehicles`). Se ESX non restituisce
  `grade_name`, `ResolveGradeName` ricade sui default: un grado rinominato in database e
  non allineato qui riceve la divisa e l'arsenale del grado sbagliato, senza errore.
- Aggiungere un framework nuovo significa: un `cl_<nome>.lua` e un `sv_<nome>.lua` con
  `if Config.Framework ~= '<nome>' then return end` in cima, entrambi aggiunti a
  `fxmanifest.lua`.
- Questo file non fa `return` condizionale: le sue tre funzioni servono sempre.

## Correlati

[modules/framework-cl_esx.md](framework-cl_esx.md) ·
[modules/framework-sv_esx.md](framework-sv_esx.md) ·
[config/cfg_duty.md](../config/cfg_duty.md)

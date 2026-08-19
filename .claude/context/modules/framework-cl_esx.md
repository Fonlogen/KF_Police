# modules/framework/cl_esx.lua

**Ruolo:** implementazione ESX del bridge framework, lato client.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, **primo** dei `client_scripts`
**Attivo se:** `Config.Framework == 'esx'` (altrimenti `return` immediato)

## Cosa fa

Ottiene l'oggetto condiviso ESX con `exports['es_extended']:getSharedObject()` (colon-call
corretto) e implementa il contratto di [sh_bridge](framework-sh_bridge.md).

## API pubblica

| Funzione | Note di implementazione |
|---|---|
| `Framework.IsLoaded()` | `ESX.IsPlayerLoaded()` |
| `Framework.GetPlayerData()` | `ESX.GetPlayerData() or {}` |
| `Framework.GetJob()` | ritorna 5 valori; senza lavoro → `nil, 0, 'recruit', '', ''` |
| `Framework.HasAllowedJob()` | `IsAllowedJob` sul nome del lavoro |
| `Framework.HasPoliceJob()` | `IsPoliceJob` sul nome del lavoro |
| `Framework.GetIdentifier()` | dal player data |
| `Framework.GetSsn()` | `data.ssn` con ripiego su `identifier` |
| `Framework.Notify(msg, type)` | delega a `Notify()` di `modules/notify/cl_notify.lua` |
| `Framework.GetClosestPlayer(maxDistance)` | `lib.getClosestPlayer`; `-1, 999.0` se nessuno |
| `Framework.GetSex()` | `'female'` per `f`/`F`/`female`/`1`, altrimenti `'male'` |
| `Framework.HasItem(itemName, count)` | ox_inventory se avviato, altrimenti scorre `playerData.inventory` |

`GetJob()` passa `job.grade_name` a `ResolveGradeName`, che ricade sui default se ESX non
lo fornisce.

## Note e trappole

- **`Framework.GetJob()` ritorna cinque valori.** Chi ne prende meno con
  `local name, grade = Framework.GetJob()` va bene, ma chi vuole `gradeLabel` deve
  contare le posizioni: `local _, _, _, gradeLabel = ...`. In `cl_cloakroom.lua` si usa
  la terza (`gradeName`), in `cl_radio.lua` la prima e la seconda.
- `GetClosestPlayer` ritorna l'**indice di player locale**, non il server id. Va convertito
  con `GetPlayerServerId` prima di mandarlo al server: lo fanno `cl_actions_citizen.lua` e
  l'endpoint locale `client:nearby`.
- `HasItem` con ox_inventory usa `exports.ox_inventory:Search('count', item)`, che ritorna
  un numero; con l'inventario ESX scorre il player data, che può essere stantio.
- `Framework.Notify` esiste per compatibilità con il contratto ma nella pratica il codice
  client chiama direttamente `Notify()` o `NotifyLocale()`.

## Correlati

[modules/framework-sh_bridge.md](framework-sh_bridge.md) ·
[modules/notify-cl_notify.md](notify-cl_notify.md) ·
[client/cl_actions_citizen.md](../client/cl_actions_citizen.md)

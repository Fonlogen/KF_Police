# server/sv_duty.lua

**Ruolo:** servizio (in/out), roster con monte ore, elenco colleghi per i blip.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_penalcode.lua`

## Cosa fa

Servizio **interno**, senza `esx_service`: lo stato vive in memoria per la sessione (mappa
`onDuty` indicizzata per `identifier`) e ogni transizione lascia una riga su
`kf_police_duty_log`, da cui si ricava il monte ore.

## API pubblica

| Funzione | Uso |
|---|---|
| `IsOnDuty(identifier)` | usata da `sv_main.lua` (`bootstrap`) e `sv_garage.lua` |
| `CountOnDuty()` | badge `duty` dei contatori |
| `GetOnDutySources()` | definita, **nessuno la chiama** |
| `SetDuty(xPlayer, wanted)` → `nuovoStato, messaggio` | `wanted = nil` inverte |

`SetDuty` in ingresso: verifica `MaxInService`, registra `since = os.time()`, scrive `'in'`
nel log. In uscita: rimuove dalla mappa, scrive `'out'`, e **se configurato** manda
`KF_Police:Client:LeaveRadio` e `KF_Police:Client:DespawnServiceVehicle`.

Sempre: `KF_Police:Client:DutyChanged`, `Invalidate('roster')`, `PushCounters()`, audit.

## Endpoint

### `duty:toggle` — `duty.toggle`

Payload opzionale `onDuty`. Senza, inverte.

### `duty:state` — `mdt.view`

`{ onDuty, total }`. Chiamata da `client/cl_main.lua` all'ingresso in gioco per
sincronizzare lo stato locale.

### `duty:roster` — `mdt.view`

**È la pagina "Gestione agenti" del bug U9**, che nella vecchia UI era uno stub.

Filtra per lavoro (`payload.job` se è in `Config.AllowedJobs`, altrimenti il lavoro
dell'agente che chiede). Ordina per grado discendente.

Il **monte ore degli ultimi 30 giorni** è calcolato in Lua:

1. legge `kf_police_duty_log` degli ultimi 30 giorni per quel lavoro, ordinato per
   `identifier, at ASC`;
2. per ogni `'in'` memorizza il timestamp; a ogni `'out'` somma la differenza;
3. le sessioni **ancora aperte** vengono chiuse a `os.time()` usando `onDuty[identifier].since`.

Il parsing della data accetta sia un numero sia una stringa `YYYY-MM-DD[T ]HH:MM:SS`
(i driver MySQL restituiscono l'una o l'altra).

Ritorna anche `canManage` = `HasPermission(..., 'society.boss')`.

### `KF_Police:duty:colleagues` (callback diretto) — `mdt.view`

Colleghi da mostrare come blip: **solo stesso lavoro**, e solo in servizio se
`Config.ColleagueBlips.OnlyOnDuty`. Un agente non vede i civili.

## Ciclo di vita

| Evento | Effetto |
|---|---|
| `playerDropped` | rimuove dalla mappa e scrive `'out'` nel log |
| `esx:setJob` | se il lavoro nuovo non è autorizzato, `SetDuty(false)` |
| `esx:playerLoaded` | `SetDuty(true)` solo se `Config.Duty.AutoOnLoad` |
| `onResourceStop` | scrive `'out'` per tutte le sessioni aperte |

Le sessioni chiuse in `onResourceStop` sono ciò che impedisce al monte ore di contare un
riavvio del server come "sempre in servizio".

## Note e trappole

- **Lo stato è in RAM**: un restart della risorsa mette **tutti** fuori servizio, senza
  avvisare i client. Chi era in servizio deve rientrare.
- Il calcolo del monte ore assume che il log sia bilanciato. Un `'in'` senza `'out'`
  corrispondente (crash del server prima di `onResourceStop`) viene chiuso solo se quella
  sessione è ancora in `onDuty`; altrimenti quel periodo **non viene contato**.
- `online` nel roster è `duty ~= nil or Framework.GetPlayerFromIdentifier(...) ~= nil`: una
  chiamata per riga. Su un roster grande sono molte iterazioni sugli online.
- `duty:roster` **non richiede `mdt.roster.view`**, solo `mdt.view`: il permesso esiste ed è
  assegnato al `lieutenant`, ma non è applicato qui. Se serve la restrizione, va cambiata
  la registrazione dell'endpoint.
- `DutyPage`, la UI che consuma questo endpoint, **non è ancora scritta**.

## Correlati

[config/cfg_duty.md](../config/cfg_duty.md) · [client/cl_duty.md](../client/cl_duty.md) ·
[client/cl_blips.md](../client/cl_blips.md) ·
[web/pages/MANCANTI.md](../web/pages/MANCANTI.md)

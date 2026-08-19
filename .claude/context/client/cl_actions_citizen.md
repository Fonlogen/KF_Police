# client/cl_actions_citizen.lua

**Ruolo:** menu contestuale delle azioni su un cittadino. Tasto **F7**.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_objects.lua`

## Cosa fa

`OpenCitizenActions()`:

1. verifica `Framework.HasPoliceJob()`;
2. `requireNearbyCitizen()` — `Framework.GetClosestPlayer(Config.Actions.MaxDistance)`,
   convertito in **server id** con `GetPlayerServerId`. Se nessuno: `no_nearby_player`;
3. costruisce le opzioni iterando `Config.CitizenActions` e tenendo solo quelle con
   `HasPermission(...)` **e** un handler nella tabella `HANDLERS`;
4. se nessuna opzione resta: `no_permission`.

Comando `/poliziacittadino`, `RegisterKeyMapping` su **F7**.

## Gli handler

| `id` | Comportamento |
|---|---|
| `identity` | `actions:identify` → **`OpenMdtOnCitizen(identifier)`**: apre il fascicolo nel tablet, non un menu di testo |
| `cuff` | progresso 2 s con `mp_arrest_paired / cop_p2_back_left`, poi `actions:cuff` |
| `drag` | `actions:drag` diretto, senza progresso |
| `vehicle` | sottomenu: metti (con il `netId` del veicolo più vicino) / togli |
| `search` | progresso 3 s, poi `actions:search`; il risultato diventa un **menu di sequestro**: ogni item cliccabile chiama `actions:seize` |
| `fine` | `actions:identify` per l'identifier, poi `lib.inputDialog` (motivo, importo 1-100 000), poi l'endpoint MDT `fines:issue` con `location = GetCurrentStreet()` |
| `licenses` | `actions:licenses` → menu con conferma `lib.alertDialog` per ogni revoca |
| `jail` | `actions:pendingSentence` per proporre i mesi accumulati, poi `lib.inputDialog`, poi `actions:jail` |

`notifyResponse(response)` è l'interprete comune: mostra `response.message` con tono
success/error secondo `response.ok`, o `invalid_data` se la risposta è nil.

## Note e trappole

- **Il bersaglio viene risolto una volta sola**, all'apertura del menu, e il `targetId`
  resta valido per tutta la navigazione. Se il cittadino si allontana, il server rifiuta
  con `too_far`: corretto, ma il messaggio arriva solo al momento dell'azione.
- `actionFine` fa **due chiamate**: `identify` per ottenere l'identifier (il server non
  accetta un server id per le multe) e poi `fines:issue`. Un `identify` fallito blocca la
  multa.
- Il menu di perquisizione non si aggiorna dopo un sequestro: la quantità mostrata resta
  quella iniziale. Bisogna riperquisire.
- **F7 e F8** (azioni veicolo) sono cablati con `RegisterKeyMapping` e non sono
  configurabili da `Config`, a differenza di F5 per il MDT.
- `identity` è l'unica azione che il `recruit` può fare, ed è il ponte principale fra campo
  e MDT.
- Nessuna delle azioni verifica lo stato di servizio.

## Correlati

[config/cfg_actions.md](../config/cfg_actions.md) ·
[server/sv_actions.md](../server/sv_actions.md) · [client/cl_nui.md](cl_nui.md) ·
[client/cl_main.md](cl_main.md)

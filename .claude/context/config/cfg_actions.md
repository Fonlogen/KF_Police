# config/cfg_actions.lua

**Ruolo:** azioni di campo — distanze, item richiesti, voci dei menu contestuali,
oggetti piazzabili, sequestro.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

Ogni azione dichiara il **permesso richiesto**: se il grado non lo ha, la voce non viene
nemmeno mostrata dal client, e il server la rifiuta comunque.

### `Config.Actions`

| Chiave | Valore | Effetto |
|---|---|---|
| `MaxDistance` | `2.5` | distanza massima per agire su un giocatore |
| `MaxVehicleDistance` | `4.0` | distanza massima per agire su un veicolo |
| `HandcuffItem` | `'handcuffs'` | vuoto = nessun item richiesto |
| `HandcuffTimer` | 10 min in ms | `0` = fino allo slega manuale |
| `LockpickItem` | `'lockpick'` | |
| `SearchRequiresRestraint` | `true` | il cittadino deve essere ammanettato o incosciente |

`MaxDistance` e `MaxVehicleDistance` sono verificati **sul server** in `ValidateTarget`
(`server/sv_actions.lua`) con `GetEntityCoords`: il client non dichiara la distanza.

### `Config.CitizenActions`

Otto voci, ognuna `{ id, label, icon, permission }`:

| `id` | Permesso | Handler client |
|---|---|---|
| `identity` | `field.identify` | apre il fascicolo nel MDT |
| `cuff` | `field.cuff` | ammanetta / slega |
| `drag` | `field.cuff` | scorta |
| `vehicle` | `field.cuff` | carica / scarica dal veicolo |
| `search` | `field.search` | perquisisce e permette il sequestro |
| `fine` | `field.fine` | multa (passa da `fines:issue`) |
| `licenses` | `field.license` | elenca e revoca |
| `jail` | `jail.send` | porta in cella |

### `Config.VehicleActions`

Cinque voci: `plate` (`mdt.view`), `lockpick` (`field.lockpick`), `impound`
(`field.impound`), `stolen` (`mdt.vehicle.flag`), `search` (`field.search`).

### Oggetti piazzabili

`Config.PlaceableObjects`: cono, barriera, chiodi (`spikes = true`), nastro, faro. Tutti
con `item = ''`, quindi non consumano nulla. `Config.PlaceableLifetime` = 1 ora: oltre
quella, `client/cl_objects.lua` li rimuove da solo.

### Sequestro

`Config.Impound`: `Fee = 500` (prezzo di riscatto), `Duration = 8000` ms (animazione).

## Note e trappole

- **`Config.Impound.Fee` è dichiarato ma non usato**: nessun codice lo addebita oggi. Il
  dissequestro da `cl_impound.lua` è gratuito.
- Gli `id` delle azioni devono avere un handler nella tabella `HANDLERS` di
  `client/cl_actions_citizen.lua` / `cl_actions_vehicle.lua`: una voce senza handler
  viene silenziosamente saltata (`HANDLERS[action.id]` falso).
- Gli oggetti piazzabili sono **locali** al client che li piazza: gli altri giocatori non
  li vedono. È una limitazione nota, non un bug da cercare.
- `objects.place` è il permesso per il menu oggetti, e `recruit` lo ha già.

## Correlati

[server/sv_actions.md](../server/sv_actions.md) ·
[client/cl_actions_citizen.md](../client/cl_actions_citizen.md) ·
[client/cl_actions_vehicle.md](../client/cl_actions_vehicle.md) ·
[client/cl_objects.md](../client/cl_objects.md)

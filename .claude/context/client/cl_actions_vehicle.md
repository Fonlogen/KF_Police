# client/cl_actions_vehicle.lua

**Ruolo:** menu contestuale delle azioni su un veicolo. Tasto **F8**.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_actions_citizen.lua`

## Cosa fa

`OpenVehicleActions()`: verifica il lavoro `police`, prende `GetNearestVehicle` entro
`Config.Actions.MaxVehicleDistance` (4 m), poi filtra `Config.VehicleActions` per permesso e
presenza dell'handler. Titolo del menu: `Veicolo <targa>`.

Comando `/poliziaveicolo`, `RegisterKeyMapping` su **F8**.

## Gli handler

| `id` | Comportamento |
|---|---|
| `plate` | `actions:plateCheck` → **`OpenMdtOnVehicle(plate)`**: apre la scheda nel tablet |
| `lockpick` | `actions:lockpick` (verifica l'item), poi progresso 8 s con `veh@break_in@0h@p_m_one@ / low_force_entry_ds`; al successo `SetVehicleDoorsLocked(vehicle, 1)` + `SetVehicleDoorsLockedForAllPlayers(false)` |
| `impound` | delega a `ImpoundVehicle(vehicle)` di `cl_impound.lua` |
| `stolen` | `lib.inputDialog` per il motivo, poi `actions:markStolen` |
| `search` | progresso 4 s, poi apre il **bagagliaio con ox_inventory** (`openInventory('trunk', { id = 'trunk<targa>', entity })`); senza ox_inventory notifica solo `search_done` |

## Note e trappole

- **Il lockpick apre la porta lato client**, dopo che il server ha solo verificato il
  permesso e l'item. Un client modificato può aprire senza il progresso: la validazione
  server è debole per questa azione.
- `actionStolen` marca sempre `true`: non c'è un toggle per rimuovere il flag "rubato" dal
  campo. La rimozione passa dal MDT (`VehicleSheet`).
- La perquisizione del bagagliaio usa la convenzione `trunk<targa>` di ox_inventory: se il
  server usa un'altra convenzione, l'inventario aperto è vuoto o sbagliato.
- Il progresso della perquisizione (4 s) non ha animazione: `PoliceProgress` senza `anim`.
- La targa non viene ricontrollata dopo il progresso: se il veicolo viene distrutto durante
  la perquisizione, `plateOf` su un'entità inesistente ritorna `nil`.
- **F8** è cablato, non configurabile.

## Correlati

[config/cfg_actions.md](../config/cfg_actions.md) ·
[server/sv_actions.md](../server/sv_actions.md) ·
[client/cl_impound.md](cl_impound.md) · [client/cl_nui.md](cl_nui.md)

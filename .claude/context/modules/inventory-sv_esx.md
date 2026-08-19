# modules/inventory/sv_esx.lua

**Ruolo:** bridge inventario su ESX classico. Ripiego se non si usa ox_inventory.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_ox.lua`
**Attivo se:** `Config.Inventory == 'esx'`

## Cosa fa

Stesso contratto di [sv_ox.lua](inventory-sv_ox.md), implementato su `xPlayer`.
Differenza concettuale: in ESX classico **armi e item sono due mondi separati**
(`getInventory()` e `getLoadout()`).

| Funzione | Implementazione |
|---|---|
| `Count` | `xPlayer.getInventoryItem(item).count` |
| `CanCarry` | `xPlayer.canCarryItem` |
| `AddItem` | verifica `CanCarry` **prima**, poi `addInventoryItem` in `pcall` |
| `RemoveItem` | verifica `Count >= count` **prima**, poi `removeInventoryItem` |
| `AddWeapon` | `addWeapon` con nome **MAIUSCOLO**, poi un `addWeaponComponent` per componente |
| `RemoveWeapon` | `removeWeapon` maiuscolo |
| `GetInventory` | unisce `getInventory()` (`weapon = false`) e `getLoadout()` (`weapon = true`), ordina per label |
| `StripWeapons` | itera `getLoadout()` e chiama `removeWeapon` |

## Note e trappole

- **Il case delle armi è opposto a ox_inventory**: qui `weapon:upper()`, là
  `string.lower(weapon)`. È la ragione per cui il case non va mai deciso dal chiamante:
  `sv_armory.lua` e `sv_actions.lua` passano il nome così com'è in configurazione
  (`WEAPON_APPISTOL`) e ogni bridge lo adatta.
- `GetInventory` filtra gli item con `count > 0`: ESX tiene le righe a zero.
- `AddItem` fa il controllo di spazio a mano perché `addInventoryItem` di ESX non
  fallisce: sovraccaricherebbe l'inventario.
- **Non è il bridge attivo** nella configurazione corrente
  (`Config.Inventory = 'ox_inventory'`): fa `return` in cima.
- I `components` delle armi in `Config.AuthorizedWeapons` sono hash: funzionano con
  `addWeaponComponent` di ESX e come metadata in ox. Non serve tradurli.

## Correlati

[modules/inventory-sv_ox.md](inventory-sv_ox.md) ·
[config/cfg_armory.md](../config/cfg_armory.md)

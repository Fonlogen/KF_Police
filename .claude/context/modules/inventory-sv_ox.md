# modules/inventory/sv_ox.lua

**Ruolo:** bridge inventario su `ox_inventory`. Implementazione predefinita.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, fra i bridge server
**Attivo se:** `Config.Inventory == 'ox_inventory'`

## Contratto

Implementato anche da [sv_esx.lua](inventory-sv_esx.md):

```lua
Inventory.Count(src, item)                        -> number
Inventory.AddItem(src, item, count, metadata)     -> boolean
Inventory.RemoveItem(src, item, count)            -> boolean
Inventory.AddWeapon(src, weapon, ammo, components)-> boolean
Inventory.RemoveWeapon(src, weapon)               -> boolean
Inventory.CanCarry(src, item, count)              -> boolean
Inventory.GetInventory(src)                       -> table  (per la perquisizione)
Inventory.StripWeapons(src)
```

## Cosa fa

Wrapper su `exports.ox_inventory`. Tre accortezze ripetute in ogni funzione:

1. `available()` verifica che `ox_inventory` sia `started`; se no, ritorna un valore
   neutro (`0`, `false`, `{}`) invece di lanciare;
2. ogni chiamata è in `pcall`;
3. il **self è esplicito**: `pcall(ox().AddItem, ox(), src, ...)`, equivalente al
   colon-call (vedi bug L1 in [voice-cl_pma](voice-cl_pma.md)).

### Armi come item

In ox_inventory le armi sono item con metadata. `AddWeapon` costruisce:

```lua
{ ammo = ammo or 0, components = components or {}, registered = false }
```

e chiama `AddItem` con il nome **minuscolo** (`weapon_appistol`). `RemoveWeapon` fa
l'inverso.

### `GetInventory`

Appiattisce `GetInventoryItems` in una lista `{ name, label, count, weapon }` ordinata per
`label`. Il flag `weapon` è vero se `item.weapon == true` **oppure** se il nome comincia
per `weapon_`: serve alla perquisizione, che mostra un'icona diversa e chiama
`RemoveWeapon` invece di `RemoveItem`.

### `StripWeapons`

Itera `GetInventory` e rimuove tutto ciò che ha `weapon = true`. Chiamata da
`server/sv_jail.lua` all'ingresso in cella.

## Note e trappole

- **I nomi vanno in minuscolo.** `Config.AuthorizedWeapons` usa `WEAPON_APPISTOL`, gli
  item di ox sono `weapon_appistol`. La conversione la fa questo bridge; lo stock in
  `kf_police_armory_stock` è anch'esso minuscolo (`sv_armory.lua` normalizza).
- `AddItem` ritorna `ok and result ~= false`: ox_inventory può ritornare `nil` in caso di
  successo, quindi non si può testare `result == true`.
- Se `ox_inventory` non è avviato, `Count` ritorna `0` e `AddItem` ritorna `false`: il
  prelievo dall'armeria fallisce con `armory_full`, che è un messaggio fuorviante.
- `CanCarry` è usata solo dal bridge ESX; qui esiste per il contratto ma `AddItem` di ox
  fa già il controllo di spazio.

## Correlati

[modules/inventory-sv_esx.md](inventory-sv_esx.md) ·
[server/sv_armory.md](../server/sv_armory.md) ·
[server/sv_actions.md](../server/sv_actions.md)

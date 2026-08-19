# modules/target/cl_ox.lua

**Ruolo:** bridge interazioni su `ox_target`. Implementazione predefinita.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, fra i bridge client
**Attivo se:** `Config.Target == 'ox_target'`

## Contratto

Implementato anche da [cl_marker.lua](target-cl_marker.md):

```lua
Target.AddZone(opts)   -- opts = { name, coords, radius, label, faIcon, marker,
                       --          permission, canInteract, onSelect }
Target.RemoveZone(name)
Target.RemoveAll()
Target.Available()     -- -> boolean
```

## Cosa fa

Ogni zona diventa una `addSphereZone` di `ox_target` con **una sola opzione**. Il
`canInteract` generato incapsula tre controlli, in quest'ordine:

1. `Framework.HasAllowedJob()` — non sei polizia o ambulanza, la zona non esiste;
2. `HasPermission(job, grade, opts.permission)` se `opts.permission` è dato;
3. `opts.canInteract()` del chiamante, se dato (es. "solo in servizio").

`onSelect` inoltra a `opts.onSelect`.

Le maniglie restituite da `addSphereZone` sono conservate in una tabella locale `zones`
indicizzata per nome, così `RemoveZone` può passare la maniglia a `removeZone`.

`debug = Config.Debug` disegna le sfere in gioco quando il debug è attivo.

## Ciclo di vita

`onResourceStop` chiama `Target.RemoveAll()`: nessuna zona orfana dopo un restart della
risorsa.

## Chi lo usa

`cl_cloakroom`, `cl_armory`, `cl_garage`, `cl_boss`, `cl_impound`. Tutti aspettano che
`Target` esista prima di registrare:

```lua
CreateThread(function()
    while not Target do Wait(200) end
    -- ... Target.AddZone(...)
end)
```

## Note e trappole

- **Il nome della zona deve essere univoco.** `AddZone` chiama `RemoveZone(opts.name)`
  prima di creare: un nome ripetuto sostituisce silenziosamente la zona precedente. La
  convenzione è `kf_police_<funzione>_<chiaveStazione>_<indice>`.
- `removeZone` è chiamato con `pcall(exports.ox_target.removeZone, exports.ox_target, ...)`:
  self esplicito, come richiede FiveM (vedi bug L1 in
  [voice-cl_pma](voice-cl_pma.md)).
- `opts.marker` è ignorato qui: serve solo al ripiego a marker. Va passato comunque, così
  cambiare `Config.Target` non richiede di toccare i file che registrano le zone.
- `faIcon` è la stringa FontAwesome di `ox_target` (`'fa-solid fa-gun'`), diversa dalle
  chiavi del registro `ICONS` della NUI. Non confonderle.
- `Target.Available()` verifica che `ox_target` sia `started`, ma nessuno la chiama: se
  la risorsa manca, `AddZone` lancia dentro un thread e la zona semplicemente non compare.

## Correlati

[modules/target-cl_marker.md](target-cl_marker.md) ·
[config/cfg_stations.md](../config/cfg_stations.md) ·
[client/cl_cloakroom.md](../client/cl_cloakroom.md)

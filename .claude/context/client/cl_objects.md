# client/cl_objects.lua

**Ruolo:** oggetti piazzabili: coni, barriere, chiodi, nastro, faro.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_impound.lua`

## Cosa fa

Menu `ox_lib` aperto dal comando `/poliziaoggetti`. Richiede lavoro `police` e permesso
`objects.place` (che `recruit` ha già).

`placeObject(definition)`:

1. `loadModel` — `RequestModel` + attesa fino a 5 s;
2. crea l'oggetto 1.2 m davanti al ped, un po' più in basso
   (`GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.2, -0.98)`);
3. eredita l'heading del ped, `PlaceObjectOnGroundProperly`, `FreezeEntityPosition`;
4. per i chiodi (`spikes = true`) attiva le collisioni;
5. registra in `placed` con `placedAt = GetGameTimer()`.

`removeNearest()` cancella l'oggetto piazzato più vicino entro 3.5 m; se non ne trova,
`object_none`.

## Pulizia automatica

Un thread ogni 60 s cancella gli oggetti più vecchi di `Config.PlaceableLifetime` (1 ora):
nessun prop resta sulla mappa per sempre.

`onResourceStop` chiama `cleanup()` e cancella tutto: nessun prop orfano.

## Note e trappole

- **Gli oggetti sono locali al client che li piazza.** `CreateObject` con `isNetwork =
  false`: gli altri giocatori **non li vedono**. È una limitazione strutturale, non un bug.
  Renderli visibili richiede oggetti di rete e gestione lato server.
- `removeNearest` cerca solo fra gli oggetti **piazzati da questo client**: non si può
  rimuovere il cono di un collega (non lo si vede nemmeno).
- Il menu usa `Locale('object_removed')` come **titolo della voce di rimozione**: la chiave
  è "Oggetto rimosso", che come etichetta di un pulsante è impropria. Refuso minore.
- Nessun oggetto consuma item (`item = ''` per tutti): il campo esiste in configurazione ma
  non viene letto da nessuna parte.
- Il comando non ha `RegisterKeyMapping`: si apre solo digitandolo.
- `SetModelAsNoLongerNeeded` è chiamata subito dopo la creazione: corretto, il modello resta
  caricato finché l'oggetto esiste.

## Correlati

[config/cfg_actions.md](../config/cfg_actions.md) ·
[shared/sh_permissions.md](../shared/sh_permissions.md)

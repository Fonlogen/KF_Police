# client/cl_cuffs.lua

**Ruolo:** rappresentazione locale delle manette: animazione, controlli disabilitati,
scadenza del timer.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_boss.lua`

## Cosa fa

**Lo stato autorevole è sul server** (`sv_actions.lua`). Questo file si limita a
rappresentarlo.

`RegisterNetEvent('KF_Police:Client:SetRestrained', function(state, timer))` imposta
`restrained` e calcola `restrainedUntil` se il timer è `> 0`.

`applyRestraint(state)`:

- **vero**: carica `mp_arresting`, `TaskPlayAnim('idle', flag 49)`, `SetEnableHandcuffs`,
  disabilita i gesti e `DisablePlayerFiring`;
- **falso**: `ClearPedSecondaryTask`, `StopAnimTask`, riabilita tutto.

## Il ciclo

Mentre `restrained` è vero, gira **ogni frame** (`Wait(0)`) e:

1. disabilita i controlli: sprint (21), attacco (24), mira (25), armi (47, 58, 140-143),
   melee (263, 264, 257), uscita dal veicolo (75);
2. **riapplica l'animazione** se non è più in esecuzione (`IsEntityPlayingAnim`): impedisce
   di liberarsi facendo qualcosa che la interrompe;
3. a scadenza di `restrainedUntil` si libera, notifica `uncuffed` e manda
   `KF_Police:Server:CuffExpired` così il server pulisce il suo stato.

A `restrained` falso il ciclo dorme 500 ms.

## Metti / togli dal veicolo

`KF_Police:Client:PutInVehicle(netId, seat)`: se `seat` è `-2` cerca il **primo posto
passeggero libero** iterando `GetVehicleMaxNumberOfPassengers`. Se non ne trova:
`vehicle_no_seat`.

`KF_Police:Client:OutOfVehicle`: `TaskLeaveVehicle(ped, vehicle, 16)`.

Sono comandati dall'agente ma **eseguiti dal client del bersaglio**, dopo che il server ha
validato distanza e permesso.

## Note e trappole

- **`Wait(0)` è costoso**: gira a frame rate pieno per tutta la durata delle manette (10
  minuti di default). È il prezzo di un vincolo che non si aggira facilmente.
- La scadenza è **client-side**: un client modificato può liberarsi. Il server pulisce lo
  stato solo quando riceve `CuffExpired`, e non ha un timer proprio. Chi vuole indurirlo deve
  aggiungere il timer lato server.
- `onResourceStop` rimuove l'animazione: senza, il ped resterebbe ammanettato dopo un
  restart della risorsa.
- `IsLocalPlayerRestrained()` è esposta ma **nessuno la chiama**: è un aggancio per altri
  script (es. impedire di usare item mentre si è ammanettati).
- Un restart della risorsa **lato server** azzera `restrained` là ma non qui: il client
  resta ammanettato fino alla scadenza del timer locale.

## Correlati

[server/sv_actions.md](../server/sv_actions.md) ·
[config/cfg_actions.md](../config/cfg_actions.md) · [client/cl_drag.md](cl_drag.md)

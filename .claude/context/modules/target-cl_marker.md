# modules/target/cl_marker.lua

**Ruolo:** ripiego del bridge interazioni con marker classici e tasto E.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, fra i bridge client
**Attivo se:** `Config.Target == 'marker'`

## Cosa fa

Stesso contratto di [cl_ox.lua](target-cl_ox.md), implementato a mano: `AddZone`
memorizza le opzioni in una tabella, e un thread unico disegna e gestisce l'input.

### Il thread

Ciclo con `sleep` adattivo:

- `sleep = 750` di base (nessuna zona vicina);
- `sleep = 0` appena una zona è entro `Config.Marker.drawDistance` (10 m) **e** il
  giocatore ha i permessi.

Per ogni zona visibile disegna un `DrawMarker` con tipo preso da
`Config.Marker.type[opts.marker]` (ripiego `21`), dimensione e colore da `Config.Marker`.

Traccia la zona **più vicina entro il raggio** in `activeZone`. Al cambio di `activeZone`
mostra o nasconde `lib.showTextUI('[E] <label>')`. Con `activeZone` attiva, il controllo
38 (E) rilasciato chiama `opts.onSelect()`.

### Permessi

La funzione locale `allowed(opts)` replica esattamente i tre controlli di `cl_ox.lua`:
lavoro autorizzato, permesso di grado, `canInteract` del chiamante.

## Note e trappole

- **`RemoveZone` non gestisce il caso in cui la zona rimossa sia `activeZone` di un altro
  nome**: nasconde il TextUI solo se il nome coincide. Corretto, ma fragile se si
  rimuovono zone durante il ciclo.
- Il costo di `sleep = 0` è reale: con una zona vicina il thread gira ogni frame. Con
  poche zone per stazione va bene; con decine di zone diventa un problema di prestazioni.
- `lib.hideTextUI()` è chiamato anche in `onResourceStop`: senza, il suggerimento
  resterebbe a schermo dopo un restart.
- La distanza per il marker (`drawDistance`) e quella per l'interazione (`opts.radius` o
  `Config.TargetRadius`) sono **diverse**: si vede il marker da 10 m, si interagisce da
  1.2 m.
- Questo file **non è quello attivo** nella configurazione corrente
  (`Config.Target = 'ox_target'`): fa `return` in cima. Va comunque tenuto allineato al
  contratto, perché è il ripiego per i server senza ox_target.

## Correlati

[modules/target-cl_ox.md](target-cl_ox.md) ·
[config/cfg_stations.md](../config/cfg_stations.md)

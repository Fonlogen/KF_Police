# client/cl_armory.lua

**Ruolo:** menu dell'armeria: catalogo, prelievo, deposito, rifornimento.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_cloakroom.lua`

## Cosa fa

Registra una zona target per ogni `armories` di ogni stazione (permesso `armory.use`, e
`canInteract` che richiede di essere **in servizio** se `Config.Duty.Enabled`).

Menu a due livelli con `lib.registerContext` / `lib.showContext`:

1. **`kf_police_armory`** — elenco di armi (icona `gun`) e oggetti (icona `box`), ognuno con
   `Scorte: N` nella descrizione;
2. **`kf_police_armory_entry`** — per la voce scelta: Prendi (disabilitato se scorta 0),
   Deposita, e Rifornisci se `catalog.canBuy`.

`menu = 'kf_police_armory'` nel secondo contesto abilita il tasto "indietro" di ox_lib.

Ogni azione riapre il menu principale (`openArmory()`) per mostrare le scorte aggiornate.

Il rifornimento chiede la quantità con `lib.inputDialog` (1-50), mostrando il prezzo
unitario.

## Note e trappole

- **`openArmory` è dichiarata `local openArmory` prima di `openEntry`** e assegnata dopo:
  serve perché le due funzioni si chiamano a vicenda. Non trasformarla in
  `local function openArmory` o `openEntry` non la vedrà.
- Il catalogo mostra **solo ciò che il grado può prendere**, perché è il server a filtrarlo.
  Il client non fa selezione.
- Le scorte visualizzate sono quelle del momento in cui il menu si è aperto: fra
  l'apertura e il click possono cambiare. Il server rifiuta con `armory_out_of_stock`,
  quindi non è un problema di correttezza.
- Il **deposito non verifica** che l'item sia dell'armeria: si può depositare qualunque
  cosa presente nel catalogo. Vedi la nota corrispondente in
  [server/sv_armory.md](../server/sv_armory.md).
- Se il catalogo è vuoto (grado senza armi né oggetti) mostra
  `armory_out_of_stock`, che è il messaggio meno adatto disponibile.

## Correlati

[server/sv_armory.md](../server/sv_armory.md) ·
[config/cfg_armory.md](../config/cfg_armory.md) ·
[modules/target-cl_ox.md](../modules/target-cl_ox.md)

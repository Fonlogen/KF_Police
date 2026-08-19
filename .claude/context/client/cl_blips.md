# client/cl_blips.lua

**Ruolo:** blip dei colleghi in servizio e blip temporanei delle allerte.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, **ultimo** dei file client

## Blip dei colleghi

L'elenco arriva **dal server** (`KF_Police:duty:colleagues`): solo stesso lavoro, e solo in
servizio se `Config.ColleagueBlips.OnlyOnDuty`. Il client **non deduce nulla** dai giocatori
intorno: senza questo vincolo un agente vedrebbe la posizione di tutti.

Il ciclo, ogni `Config.ColleagueBlips.Refresh` (5 s):

1. se il framework è caricato e il lavoro è autorizzato, chiede l'elenco;
2. `upsertBlip(entry)` per ognuno: risolve il player locale con `GetPlayerFromServerId`,
   crea `AddBlipForEntity` sul ped se non esiste, aggiorna sprite/colore/scala,
   `ShowHeadingIndicatorOnBlip`, e il nome `"<nome> (<grado>)"`;
3. rimuove i blip di chi non è più nell'elenco;
4. se il lavoro non è autorizzato: `clearBlips()` e intervallo a 10 s.

`upsertBlip` ritorna `false` se il collega non è nello streaming del client: quel blip non
viene creato e viene rimosso al giro successivo.

## Allerte

`KF_Police:Client:Alert(data)`:

1. notifica `data.message` con tono `warning`;
2. se `data.blip ~= false` e ci sono coordinate: crea un blip sprite `161`, colore `1`,
   scala `1.1`, **lampeggiante**, con il messaggio come nome;
3. `SetTimeout(120000, ...)` lo rimuove dopo 2 minuti: nessun blip resta sulla mappa a vita.

L'evento è emesso dal server in risposta a `KF_Police:Server:Alert`, che altre risorse
(telefono, negozi, rapine) possono chiamare.

## Note e trappole

- **I blip seguono il ped, non le coordinate**: `AddBlipForEntity`. Escono dallo streaming
  con il giocatore.
- Il ciclo chiama il server ogni 5 s **per ogni client con lavoro autorizzato**: con molti
  agenti online sono molte callback. `KF_Police:duty:colleagues` fa `RequirePermission`
  (quindi conta nel rate limit, come lettura) e itera tutti gli online: è il punto più
  caldo del server.
- `onResourceStop` chiama `clearBlips()`, ma **non** rimuove i blip delle allerte già
  creati: quelli scadono da soli dopo 2 minuti.
- I blip delle **stazioni** stanno in `cl_main.lua`, non qui.
- `Config.ColleagueBlips.Enabled = false` fa uscire il thread all'avvio: cambiarla a
  runtime non riattiva nulla.

## Correlati

[config/cfg_stations.md](../config/cfg_stations.md) ·
[server/sv_duty.md](../server/sv_duty.md) · [server/sv_main.md](../server/sv_main.md)

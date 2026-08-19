# web/src/lib/mock.ts

**Ruolo:** dati finti per lo sviluppo in browser (`npm run dev`). Sostituisce il vecchio
`debugDataList.ts`.
**Contesto:** UI (solo sviluppo)

## Come si attiva

`callMdt` in `lib/nui.ts` instrada qui quando `isBrowser()` è vero, con un **import
dinamico**: il mock non entra nel bundle di produzione.

Nessun accesso al gioco: l'interfaccia si costruisce e si misura contro il mockup senza
avviare il server.

## Contenuto

| Costante | Contenuto |
|---|---|
| `OFFICER` | `Fonlogen Dev`, `boss` grado 4, in servizio |
| `PERMISSIONS` | **tutti** i permessi: in sviluppo si vede l'interfaccia completa |
| `CITIZENS` | 8 cittadini, di cui **1 ricercato** (`char3:franchito`) e **1 detenuto** (`char4:lady`) |
| `VEHICLES` | 3 veicoli: uno rubato+BOLO, uno in garage, uno sequestrato |
| `TAGS` | 4 tag con icone e colori |
| `REPORTS` | 4 rapporti: open, closed, **draft riservato**, open |
| `PENAL` | 3 categorie con 6 articoli |
| `JAIL_CELLS` | le 6 celle di `Config.Jail.Cells` **senza le coordinate**: alla UI servono solo `id`, `label` e `capacity` |
| `RADIO` | connesso a `lspd_main`, 4 in ascolto, **`talking: true`** |

I dati sono scelti per **esercitare gli stati**: il timbro RICERCATO, il timbro DETENUTO, i
chip dei flag veicolo, il lucchetto del rapporto riservato, l'animazione dell'istogramma
radio.

## `mockEndpoint(endpoint, payload)`

Uno `switch` sull'endpoint. Implementa: `bootstrap`, `citizens:search` (con filtri e
`wantedCount`), `citizens:get`, `vehicles:search`, `vehicles:get`, `vehicles:impounded`,
`reports:list`, `reports:get`, `reports:save`, `reports:delete`, `tags:list`,
`penalcode:list`, `wanted:list`, `jail:list`, `duty:roster`, `duty:state`, `duty:toggle`,
`radio:*`, `client:context`, `client:nearby`.

Default: `{ ok: true }`.

Helper: `paginate(rows, payload)` e `matches(campi, query)` per ricerca case-insensitive.
`dossier(identifier)` costruisce un `CitizenDossier` completo con 3 reati (uno **annullato**),
una nota, veicoli, licenze, proprietà, rapporti e stato carcere. Se il cittadino è ricercato
valorizza anche `wantedBy` e `wantedAt`, così il pannello "Ricerca attiva" di `CitizenSheet`
non mostra tre trattini in sviluppo.

`jail:list` restituisce `cells: JAIL_CELLS`: serve a esercitare il pannello "Occupazione
celle" di `JailPage`, che senza celle non compare affatto.

## Note e trappole

- **Le forme delle risposte devono rispecchiare esattamente quelle di `server/sv_*.lua`.**
  Un mock divergente fa sviluppare contro un contratto che non esiste: la pagina funziona in
  browser e si rompe in gioco. È il rischio principale di questo file.
- `PERMISSIONS` contiene tutto: in browser **non si può testare** come appare l'interfaccia
  a un `recruit`. Per farlo bisogna ridurre l'array a mano.
- Le scritture (`reports:save`, `duty:toggle`, ...) rispondono `ok` ma **non mutano** i dati:
  ricaricare mostra ancora lo stato iniziale.
- `client:nearby` risponde deliberatamente `{ ok: false, error: 'no_nearby_player' }`: è lo
  stato più comune e va gestito dalla UI.
- Il default `{ ok: true }` significa che un endpoint non implementato **non fallisce**: una
  pagina nuova può sembrare funzionante in browser pur non ricevendo dati. Meglio aggiungere
  il caso al mock.
- Nessuna emoji, come nel resto del progetto.

## Correlati

[web/lib/nui.md](nui.md) · [web/lib/types.md](types.md) ·
[web/legacy-ui.md](../legacy-ui.md) (per `debugDataList.ts`, il predecessore)

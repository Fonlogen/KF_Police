# server/sv_reports.lua

**Ruolo:** rapporti di servizio con coinvolti, veicoli e tag su tabelle di giunzione. Più
la gestione dei tag.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_wanted.lua`

## Cosa fa

Coinvolti, veicoli e tag stanno in **tabelle di giunzione**: niente più liste JSON dentro
la riga del rapporto. Il salvataggio è una transazione, quindi un rapporto non resta mai a
metà (testata salvata e collegamenti persi).

Vincoli: `ROLES = { suspect, victim, witness }`, `STATUSES = { draft, open, closed }`. Un
valore fuori lista viene sostituito con il default (`suspect`, `open`), non rifiutato.

## Endpoint

### `reports:list` — `mdt.view`

Paginato, ricerca su `title`, `officer`, `location`, filtro opzionale per `status`.

**Riservatezza:** chi non ha `mdt.report.delete` vede solo
`(is_confidential = 0 OR officer_id = <proprio>)`. Il filtro è nella `WHERE`, non nel
post-processing: i rapporti riservati di altri non arrivano nemmeno al client.

Ogni riga porta `involvedCount` (sottoquery) e `tags` (una query `loadTags` per riga).

Ordinamento fisso `created_at DESC, id DESC`.

### `reports:get` — `mdt.view`

Rapporto completo: testata + `loadInvolved` + `loadVehicles` + `loadTags`.

Ricontrolla la riservatezza sul singolo rapporto: non basta che `reports:list` l'abbia
filtrato, perché la NUI può chiedere un id qualunque.

### `reports:save` — `mdt.report.create`

Insert o update secondo la presenza di `payload.id`.

Per un update su un rapporto **di altri** serve `mdt.report.edit` (che comunque `recruit`
ha già: la barriera è debole, è la riservatezza a fare il lavoro).

`linkStatements(reportId, payload)` costruisce la lista di query dei collegamenti:
prima tre `DELETE` (coinvolti, veicoli, tag), poi gli `INSERT IGNORE`. È una
**sostituzione completa**, non un merge. Le tre liste sono deduplicate in memoria
(`seenInvolved` con chiave `identifier:role`, `seenPlates`, `seenTags`).

Dopo il salvataggio: `Invalidate('reports', id)`, `PushCounters()`, e un
`Invalidate('citizen', identifier)` **per ogni coinvolto**, così i fascicoli aperti si
aggiornano.

### `reports:delete` — `mdt.report.delete`

Transazione: cancella le tre giunzioni, mette a `NULL` il `report_id` dei reati collegati
(**i reati sopravvivono al rapporto**), poi cancella la testata.

### Tag

| Endpoint | Permesso | Note |
|---|---|---|
| `tags:list` | `mdt.view` | ripieghi: `icon` → `warning`, `color` → `#A8322A` |
| `tags:save` | `mdt.tag.edit` | **`StripEmoji`** sull'etichetta; colore validato con `^#%x%x%x%x%x%x$` |
| `tags:delete` | `mdt.tag.edit` | transazione: prima la giunzione, poi il tag |

`tags:save` è il punto di applicazione del bug L11 lato scrittura: l'etichetta di un tag
non contiene mai caratteri Unicode decorativi, l'icona sta nella colonna `icon`.

## Note e trappole

- **`loadTags` è chiamata una volta per riga** in `reports:list`: una pagina da 25 fa 25
  query in più. Con `pageSize` alto diventa pesante; un `IN` con tutti gli id sarebbe
  meglio.
- Se `linkStatements` fallisce, il rapporto **è già salvato**: si prende un
  `Logger.Warn('Collegamenti del rapporto %s non salvati')` e la risposta è comunque `ok`.
  Testata e collegamenti non sono nella stessa transazione.
- `location` vuoto diventa `'Sconosciuto'`, non `NULL`.
- **`mdt.report.edit` è di grado 0**, quindi in pratica chiunque può modificare un rapporto
  non riservato di un altro. Se serve una barriera vera, va cambiato
  `shared/sh_permissions.lua`.
- Le targhe dei veicoli coinvolti sono normalizzate con `NormalizePlate` e limitate a
  `Config.Limits.plate` (12): una targa più lunga viene scartata silenziosamente.
- `ReportSheet.tsx`, la UI che consuma `reports:get`/`save`/`delete`, **non è ancora
  scritta**.

## Correlati

[server/sv_citizens.md](sv_citizens.md) · [sql/install.md](../sql/install.md) ·
[web/pages/ReportsPage.md](../web/pages/ReportsPage.md) ·
[web/pages/MANCANTI.md](../web/pages/MANCANTI.md)

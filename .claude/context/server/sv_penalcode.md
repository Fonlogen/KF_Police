# server/sv_penalcode.lua

**Ruolo:** codice penale: articoli raggruppati per categoria, con i valori numerici.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_vehicles.lua`

## Cosa fa

Gli articoli contengono i campi **numerici** `fine` e `jail_months`: niente più stringhe
`sanction` da cui riestrarre la multa con una regex (bug L10).

Le ex `fine_types` di `esx_policejob` (52 righe, in inglese) sono state tradotte e
riversate come **articoli come tutti gli altri**, con la loro categoria: una sola fonte per
multe e reati. `fine_types` resta in database ma non è più letta.

## Endpoint

### `penalcode:list` — `mdt.view`

Due query (categorie e articoli), poi raggruppa in memoria.

Ritorna:

- `categories`: array di `{ id, label, icon, sortOrder, articles[] }`, ordinato per
  `sort_order, label`;
- `articles`: la lista **piatta** di tutti gli articoli.

Gli articoli senza categoria (`category_id NULL` → chiave `'0'`) finiscono in una categoria
sintetica **"Senza categoria"** con `sortOrder 9999`, in fondo: non scompaiono mai dalla
vista.

Il doppio formato è comodo: `categories` per la pagina raggruppata, `articles` per una
ricerca piatta (la usa la modale "Contesta reati" di `CitizenSheet`).

### `penalcode:save` — `mdt.penalcode.edit`

Insert o update secondo `payload.id`. Limiti: `title` obbligatorio
(`Config.Limits.penalTitle`, 160), `code` 16, `description`
(`Config.Limits.penalDescription`, 2000), `fine` 0-10 000 000, `jailMonths` 0-10 000.

Se `categoryId` non esiste in `kf_police_penalcode_categories` viene messo a `nil`: il
salvataggio riesce e l'articolo finisce in "Senza categoria", invece di fallire.

### `penalcode:delete` — `mdt.penalcode.edit`

Transazione in due passi:

```sql
UPDATE kf_police_charges SET penalcode_id = NULL WHERE penalcode_id = ?;
DELETE FROM kf_police_penalcode WHERE id = ?;
```

**I reati già contestati conservano il testo** (la colonna `crime` è una copia, non un
riferimento) ma perdono il collegamento all'articolo. Lo storico non deve cambiare quando
il codice penale viene riscritto.

### `penalcode:saveCategory` — `mdt.penalcode.edit`

Insert o update di una categoria. `icon` vuota → `'penalcode'`. `sortOrder` 0-9999.

## Note e trappole

- **`code` ha un vincolo `UNIQUE`** in `install.sql`. Salvare un articolo con un `code` già
  usato fa fallire l'`INSERT`: `Database.Insert` ritorna `nil` e l'endpoint risponde
  `invalid_data`, senza dire che il problema è il codice duplicato.
- Non esiste `penalcode:deleteCategory`: le categorie si creano e si modificano, non si
  cancellano dalla UI.
- `Invalidate('penalcode')` non ha `id`: qualunque modifica ricarica l'intero codice penale
  su tutti i client con il tablet aperto. Accettabile, il codice penale cambia raramente.
- La UI che consuma questi endpoint (`PenalCodePage`) **non è ancora scritta**. Oggi solo
  `CitizenSheet` chiama `penalcode:list`.
- I 59 articoli iniziali (id 1-7 e 101-152) arrivano da `sql/seed.sql`: modificarli dalla
  UI e poi rieseguire il seed li **riporta ai valori iniziali**, perché il seed usa
  `ON DUPLICATE KEY UPDATE`.

## Correlati

[sql/seed.md](../sql/seed.md) · [server/sv_charges.md](sv_charges.md) ·
[web/pages/MANCANTI.md](../web/pages/MANCANTI.md)

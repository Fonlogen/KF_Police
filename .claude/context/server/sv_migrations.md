# server/sv_migrations.lua

**Ruolo:** porta il database dal vecchio schema monolitico a quello normalizzato, senza
perdere dati.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, **prima** di `sv_database.lua` (che la esegue)

## Da dove a dove

- **Prima:** `kf_police_citizens`, chiave su SSN (`citizenid`), con blob JSON
  `criminalRecords`, `notes`, più `wanted`, `wantedReason`, `image`.
- **Dopo:** `kf_police_profiles` (chiave `identifier`), `kf_police_charges`,
  `kf_police_notes`, e giunzioni per i rapporti.

## Garanzie

1. **Backup automatico** della tabella di partenza in
   `kf_police_citizens_backup_20260819`. Se il backup non riesce, la migrazione **si
   ferma**.
2. **Nessuna perdita**: le righe il cui SSN non corrisponde a nessun utente finiscono in
   `kf_police_orphan_records` con il JSON originale, non vengono cancellate.
3. **Idempotenza**: `kf_police_schema_version` fa girare la parte distruttiva una volta
   sola (`SCHEMA_VERSION = 1`).
4. **Verifica dei conteggi** prima/dopo stampata in console.

## I passi

### `alignExistingTables()` — sempre eseguito

`AddColumnIfMissing` per le colonne nuove su tabelle create dal vecchio codice:

- `kf_police_reports`: `status`, `is_confidential`, `created_at`, `updated_at`; poi copia
  `date` → `created_at` se la vecchia colonna esiste;
- `kf_police_tags`: `icon`;
- `kf_police_penalcode`: `code`, `category_id`, `jail_months`, `is_felony`; poi
  `jailTime` → `jail_months`, e **`sanction` → `fine`** estraendo il primo numero con
  `match('(%d+)')`.

Quest'ultima è la correzione del bug L10: la multa era una stringa già formattata da cui
il codice riestraeva il numero con una regex a ogni lettura. Ora la conversione avviene
**una volta**, in migrazione.

### `cleanTagLabels()` — sempre eseguito

Correzione del bug L11. Per ogni tag: `StripEmoji(label)`, e se `icon` è vuota o è il
default `warning`, la indovina da parole chiave (`ICON_BY_KEYWORD`: `arm` → `weapon`,
`rapin` → `money`, `droga` → `drug`, ...). Se l'etichetta ripulita è vuota diventa
`Tag <id>`.

### `seedArmoryStock()` — sempre eseguito

Se `kf_police_armory_stock` è vuota, la popola da `Config.Armory.InitialStock` (in
minuscolo). Non è nel seed SQL perché la fonte è la configurazione Lua.

### `migrateLegacyCitizens()` — una volta sola

Costruisce un indice `ssn → identifier` **e** `identifier → identifier` da `users` in una
sola query (`buildIdentifierIndex`), poi per ogni riga di `kf_police_citizens`:

- **SSN non risolto** → riga in `kf_police_orphan_records` (se non già presente);
- **risolto** → upsert in `kf_police_profiles`, poi `NormalizeList(criminalRecords)` e
  `NormalizeList(notes)` esplosi in righe.

`NormalizeList` gestisce entrambe le forme storiche del blob (mappa indicizzata e array).
Le vittime dei reati vengono risolte con lo stesso indice.

### `migrateLegacyReports()` — una volta sola

Se `kf_police_reports` ha ancora le colonne `involved`, `involved_vehicles` o `tags`, le
esplode nelle tre tabelle di giunzione con `INSERT IGNORE`.

## Note e trappole

- I primi tre passi girano **a ogni avvio**: sono controlli, non trasformazioni
  distruttive. Solo i due `migrateLegacy*` sono protetti dalla versione.
- **Le colonne legacy non vengono droppate.** `kf_police_citizens` resta in sola lettura
  per due release, come da piano.
- La verifica finale confronta i reati contati nel blob con le righe in
  `kf_police_charges` e stampa un avviso se sono meno dell'atteso. È un avviso, non un
  rollback.
- Per **ricollaudare** la migrazione: svuotare `kf_police_schema_version` e rimuovere la
  tabella di backup. Vedi `.claude/handoff.md` §4 per il dato di prova sintetico
  attualmente inserito.
- `sql/migrations/001_normalize.sql` è la versione **manuale/di riferimento** dello stesso
  lavoro: non viene eseguita automaticamente e non contiene l'esplosione dei blob (che
  richiede Lua).

## Correlati

[server/sv_database.md](sv_database.md) ·
[sql/migrations-001_normalize.md](../sql/migrations-001_normalize.md) ·
[shared/sh_utils.md](../shared/sh_utils.md)

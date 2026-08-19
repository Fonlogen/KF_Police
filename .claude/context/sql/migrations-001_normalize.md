# sql/migrations/001_normalize.sql

**Ruolo:** versione **manuale / di riferimento** della migrazione di normalizzazione.
**Eseguito da:** nessuno automaticamente.

## Cosa è, e cosa non è

In esecuzione normale la migrazione la fa `server/sv_migrations.lua`, che compie le stesse
operazioni in modo **portabile** (controlli su `information_schema` invece di
`ADD COLUMN IF NOT EXISTS`, che MySQL non supporta) **e in più** esplode i blob JSON di
`kf_police_citizens` nelle tabelle normalizzate.

Questo file serve a:

- documentare in SQL leggibile cosa fa la migrazione;
- permettere un'esecuzione manuale su MariaDB (che `IF NOT EXISTS` lo supporta);
- essere il riferimento se la versione Lua va rifatta.

**Non è idempotente al 100% su MySQL**: `ADD COLUMN IF NOT EXISTS` è una estensione
MariaDB.

## I passi

1. **Backup** — `CREATE TABLE IF NOT EXISTS kf_police_citizens_backup_20260819 AS SELECT *`.
2. **Adeguamento** — `ALTER` su `kf_police_reports` (`status`, `is_confidential`,
   `created_at`, `updated_at`, poi `date` → `created_at`), `kf_police_tags` (`icon`),
   `kf_police_penalcode` (`code`, `category_id`, `jail_months`, `is_felony`, poi
   `jailTime` → `jail_months` e **`sanction` → `fine`** con
   `CAST(REGEXP_SUBSTR(sanction, '[0-9]+') AS UNSIGNED)`).
3. **Profili** — `INSERT ... SELECT` da `kf_police_citizens` con
   `INNER JOIN users ON u.ssn = c.citizenid OR u.identifier = c.citizenid`.
4. **Orfani** — `INSERT ... SELECT` con `LEFT JOIN` e `WHERE u.identifier IS NULL`, payload
   costruito con `JSON_OBJECT`. Protetto da `NOT EXISTS` per non duplicare.
5. **Reati e note** — **non fatti qui.** Il commento lo dice esplicitamente: l'esplosione
   dei blob avviene in `sv_migrations.lua`, che sa decodificare le due forme storiche
   (mappa e lista).
6. **Versione** — `INSERT IGNORE INTO kf_police_schema_version VALUES (1)`.

## Note e trappole

- **Se esegui questo file a mano, il passo 6 marca lo schema come migrato** e la versione
  Lua salta i passi 4-5 al prossimo avvio: i reati e le note dei blob **non vengono mai
  esplosi**. Per un'esecuzione manuale completa, o si evita l'ultima riga, o si svuota
  `kf_police_schema_version` dopo.
- `REGEXP_SUBSTR` richiede MySQL 8 / MariaDB 10.0.5+. La versione Lua usa
  `match('(%d+)')`, che funziona sempre.
- Il nome della tabella di backup contiene la data `20260819`: è lo stesso valore hardcoded
  in `sv_migrations.lua` (`BACKUP_TABLE`). **Se cambi uno, cambia l'altro.**
- Dichiarato nei `files` di `fxmanifest.lua` come `sql/migrations/*.sql` ma
  `Database.RunSqlFile` non lo carica mai.

## Correlati

[server/sv_migrations.md](../server/sv_migrations.md) ·
[sql/install.md](install.md) · [server/sv_database.md](../server/sv_database.md)

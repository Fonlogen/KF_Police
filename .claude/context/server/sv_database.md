# server/sv_database.lua

**Ruolo:** accesso al database. Wrapper con errori **visibili**, introspezione, esecuzione
di file `.sql`, sequenza di avvio.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_migrations.lua`

## Il bug L9

Il vecchio `safeQuery` inghiottiva gli errori e ritornava `{}`: un errore SQL diventava
**indistinguibile da "nessun dato"**. Qui:

- errore → `nil` + due righe in console (messaggio e primi 160 caratteri della query);
- nessun dato → `{}`.

Conseguenza per chi chiama: `if result == nil then` è "errore", `#result == 0` è "vuoto".
Diversi endpoint lo sfruttano (`sv_citizens.lua` ritorna `invalid_data` se il `COUNT` è
`nil`).

## API pubblica

### Stato

| Funzione | Uso |
|---|---|
| `Database.IsReady()` | vero dopo install + migrate + seed |
| `Database.WaitReady(timeout)` | blocca fino a pronto, default 15 s |
| `Database.OnReady(cb)` | esegue subito se già pronto, altrimenti accoda |

`sv_main.lua` e `sv_jail.lua` usano `WaitReady(30000)`; `sv_citizens.lua` e `sv_jail.lua`
usano `OnReady` per popolare cache e ripristinare i detenuti.

### Query

`Database.Query`, `Scalar`, `Single`, `Insert`, `Update` — wrapper `pcall` su
`MySQL.*.await`. `Database.Transaction(queries)` esegue una lista di `{ query, params }`
in modo atomico e ritorna un booleano.

### Introspezione

`TableExists(nome)`, `ColumnExists(tabella, colonna)` via `information_schema`.
`AddColumnIfMissing(tabella, colonna, definizione)` — portabile, nessun
`ADD COLUMN IF NOT EXISTS` (che MySQL non supporta).

L'introspezione è quello che rende la migrazione Lua idempotente su qualunque versione di
MySQL/MariaDB.

### Esecuzione di file

`Database.RunSqlFile(path)` → `ok, eseguite, fallite`.

Legge con `LoadResourceFile` e divide con `splitStatements`, uno splitter scritto a mano
che rispetta:

- stringhe fra `'`, `"` e backtick, con gestione dell'escape `\`;
- commenti di riga `--` (salta fino al newline);
- commenti a blocco `/* */`.

Un `split(';')` ingenuo spezzerebbe le stringhe dei seed che contengono `;` o apostrofi
(`'Porto d\'armi assente'`).

## Sequenza di avvio

Un `CreateThread` con `Wait(500)` iniziale (per dare a oxmysql il tempo di aprire la
connessione), poi:

1. `Database.Install()` → `sql/install.sql`
2. `Migrations.Run()` (se `Migrations` esiste)
3. `Database.Seed()` → `sql/seed.sql`
4. `markReady()`

**L'ordine conta.** I seed usano colonne (`icon`, `category_id`, `jail_months`) che su un
database preesistente le aggiunge il passo 2. Invertendo si prende
`ERROR 1054 Unknown column 'icon'`: è già successo, è la ragione della separazione fra
`install.sql` e `seed.sql`.

## Note e trappole

- **Nessuna query è tipizzata.** `Database.Scalar('SELECT COUNT(*)...')` può ritornare
  numero o stringa secondo il driver: il codice fa sempre `tonumber(...) or 0`.
- `Wait(500)` è una scommessa, non una garanzia. Se oxmysql è lento il primo `Install`
  fallisce e la risorsa resta con `IsReady()` falso; gli endpoint rispondono
  `mdt_not_ready`. Non c'è retry.
- `RunSqlFile` esegue le istruzioni **una per una**, non in transazione: un file a metà
  lascia il database a metà. Per `install.sql` (solo `CREATE TABLE IF NOT EXISTS`) e
  `seed.sql` (solo `INSERT ... ON DUPLICATE KEY UPDATE`) è innocuo perché entrambi sono
  idempotenti.
- I file SQL vanno dichiarati nei `files` di `fxmanifest.lua`, altrimenti
  `LoadResourceFile` ritorna `nil`.

## Correlati

[server/sv_migrations.md](sv_migrations.md) · [sql/install.md](../sql/install.md) ·
[sql/seed.md](../sql/seed.md) · [ARCHITECTURE.md](../ARCHITECTURE.md) §5

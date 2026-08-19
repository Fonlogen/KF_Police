# server/sv_logger.lua

**Ruolo:** tracciabilità su `kf_police_audit` e stampa in console. Scritture accodate e
svuotate a lotti.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, **primo** dell'infrastruttura server

## Perché esiste

Due scopi concreti: ricostruire chi ha fatto cosa dopo una segnalazione, e accorgersi di
un exploit guardando la frequenza delle azioni di un singolo identifier.

## API pubblica

### Console

`Logger.Info`, `Logger.Warn` (giallo), `Logger.Error` (rosso), `Logger.Debug` (ciano, solo
se `Config.Debug`). Tutte accettano un formato `string.format` e i suoi argomenti.

### Audit

```lua
Logger.Audit(actor, action, target, payload)
```

- `actor`: `xPlayer` (estrae `identifier` e `Framework.GetName`), oppure una stringa
  (identifier grezzo), oppure `nil` (azione di sistema, es. rilascio automatico).
- `action`: stringa breve, convenzione `dominio.verbo` (`charge.add`, `jail.release`,
  `permission.denied`). Tagliata a 64 caratteri.
- `target`: identifier, targa, id rapporto. Tagliato a 128.
- `payload`: tabella, serializzata in JSON.

Non scrive subito: accoda. `Logger.Flush()` svuota in una **transazione** quando la coda
raggiunge 50 righe, ogni 2 s dal thread, o in `onResourceStop`. Così l'audit non aggiunge
latenza al callback che lo ha generato.

### Lettura

```lua
Logger.List({ actor = ..., action = ..., limit = ... })
```

Filtri opzionali, `limit` tra 1 e 200 (default 50), ordinati per data discendente.

## Pulizia

Un secondo thread parte dopo 30 s e poi gira ogni 6 ore: cancella le righe più vecchie di
`Config.Audit.KeepDays` (60 giorni). L'audit non deve crescere all'infinito.

## Note e trappole

- **`Logger.List` non è esposta da nessun endpoint.** Il permesso `mdt.audit.view` esiste
  e il `boss` lo ha, ma la pagina audit non è mai stata scritta. Chi la vuole deve
  aggiungere un `RegisterMdtEndpoint('audit:list', 'mdt.audit.view', ...)`.
- **Dipende da `Database.Transaction` e `Database.Update`**, definite in `sv_database.lua`
  che è caricato **dopo**. Funziona perché le chiamate avvengono a runtime, quando entrambi
  esistono. Il primo `Flush` del thread arriva 2 s dopo l'avvio, ben oltre.
- Se `Config.Audit.Enabled` è falso, `Logger.Audit` esce subito: la coda resta vuota e non
  si scrive nulla. Le stampe in console continuano.
- Un `Flush` in `onResourceStop` può perdere righe se la transazione non completa prima
  che la risorsa muoia: è un rischio accettato.
- `Logger.Warn('Rate limit superato...')` in `sv_permissions.lua` è il segnale più utile
  per accorgersi di un client che martella gli endpoint.

## Correlati

[server/sv_database.md](sv_database.md) · [server/sv_permissions.md](sv_permissions.md) ·
[sql/install.md](../sql/install.md)

# server/sv_main.lua

**Ruolo:** nucleo server. Registra il dispatcher degli endpoint MDT, le invalidazioni, il
`bootstrap`, gli item usabili e i servizi ereditati da `esx_policejob`.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo l'infrastruttura e **prima** dei moduli di dominio

## Il bug L4

Il vecchio `ServerDataInit` caricava **tutti** gli utenti e **tutti** i veicoli in RAM, e
`UpdateMDTData()` li ribroadcastava a `-1` a ogni reato, nota o rapporto. Con 3000
cittadini è insostenibile, e comunque è una fuga di dati verso ogni client.

Qui non esiste nessuna cache globale: ogni schermata chiede solo la propria pagina, e le
scritture emettono un'**invalidazione mirata**.

## API pubblica

### `RegisterMdtEndpoint(name, permission, handler)`

Registra un endpoint nella tabella locale `endpoints`.
`handler(officer, payload, src)` deve ritornare `MdtOk(...)` o `MdtError(...)`.

### `MdtOk(data)` / `MdtError(key, extra)`

Risposte uniformi. `MdtOk` aggiunge `ok = true` alla tabella passata (o la incapsula in
`{ ok = true, data = ... }` se non è una tabella). `MdtError` produce
`{ ok = false, error = key, message = Locale(key) }`, più le chiavi di `extra`.

### `Invalidate(scope, id)`

`TriggerClientEvent('KF_Police:Client:Invalidate', -1, { scope, id })`. Broadcast a tutti,
ma il payload è **due campi**, non il database.

### `PushCounters()` / `GetMdtCounters()`

I quattro numeri dei badge della sidebar: `wanted`, `jail`, `reports` (solo `open`),
`duty`. Tre `COUNT(*)` più `CountOnDuty()`.

## Il dispatcher

`lib.callback.register('KF_Police:mdt', function(src, endpoint, payload)` — **unico punto**
di ingresso. Nell'ordine:

1. `endpoint` è una stringa → altrimenti `invalid_data`
2. l'endpoint è registrato → altrimenti `Logger.Warn` + `invalid_data`
3. `Database.IsReady()` → altrimenti `mdt_not_ready`
4. `RequirePermission(src, definition.permission)` → altrimenti il motivo del rifiuto
5. `payload` non tabella → sostituito con `{}`
6. `pcall(handler, ...)` → un errore diventa `Logger.Error` + `invalid_data`

Un handler che va in errore **non** propaga l'eccezione al callback: la NUI riceve sempre
una risposta.

## `bootstrap`

Permesso `mdt.view`. È la prima chiamata che fa la NUI all'apertura. Ritorna:

- `officer`: identifier, nome, `firstName`/`lastName`, ssn, job, `jobLabel`, grade,
  `gradeName`, `gradeLabel`, `mugshot` (da `kf_police_profiles`), `onDuty`;
- `permissions`: array piatto da `PermissionList`;
- `pages`: copia di `Config.EnabledPages`;
- `counters`: `GetMdtCounters()`;
- `ui`: `pageSize`, `defaultImage`, `locale`;
- `radio`: `{ enabled }`.

## Avvio

Un thread aspetta `Database.WaitReady(30000)`. Se il database non è pronto stampa un
errore e **esce**: il MDT resta chiuso. Altrimenti registra come item usabile
`Config.OpenItem` e tutti gli `OpenItemAliases`; l'handler verifica `GetOfficer(src)` e
manda `KF_Police:Client:OpenMDT`.

## Servizi ereditati da esx_policejob

Un secondo thread, dopo 2 s, emette in `pcall`:

- `esx_phone:registerNumber('police', 'Polizia', true, true)` — contatto di allerta;
- `esx_society:registerSociety('police', 'LSPD', ...)` — conto, assunzioni, salari.

**Vanno mantenuti anche dopo la dismissione di `esx_policejob`**, altrimenti il telefono
perde il contatto e la società perde il conto.

`RegisterNetEvent('KF_Police:Server:Alert', ...)` è l'allerta polizia da altre risorse
(telefono, negozi, rapine): sanifica il messaggio a 200 caratteri e lo inoltra a tutti i
giocatori con lavoro `police` come `KF_Police:Client:Alert`.

## Note e trappole

- **`Invalidate` è un broadcast a `-1`.** Il filtro è lato client: `cl_nui.lua` inoltra
  alla NUI solo se il tablet è aperto. Costo trascurabile (due stringhe), ma tutti i client
  ricevono l'evento.
- `GetMdtCounters` fa tre query a ogni `PushCounters()`. Le scritture frequenti (aggiunta
  reati in serie) la chiamano ripetutamente: se diventa un problema, va messa in debounce.
- `CountOnDuty` e `IsOnDuty` vengono da `sv_duty.lua`, caricato **dopo**. I riferimenti
  sono difensivi (`CountOnDuty and CountOnDuty() or 0`), quindi un `bootstrap` durante
  l'avvio ritorna `0` invece di lanciare.
- Registrare due volte lo stesso nome di endpoint **sovrascrive** silenziosamente il primo.
- `KF_Police:Server:Alert` non ha rate limit: è un evento di rete aperto. Una risorsa
  compromessa può spammarlo.

## Correlati

[ARCHITECTURE.md](../ARCHITECTURE.md) §1-§2 ·
[server/sv_permissions.md](sv_permissions.md) · [client/cl_nui.md](../client/cl_nui.md)

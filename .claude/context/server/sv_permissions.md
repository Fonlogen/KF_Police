# server/sv_permissions.lua

**Ruolo:** validazione autorevole di ogni operazione. **Correzione del bug L12.**
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_logger.lua`

## Il bug L12

Prima **nessun callback controllava il grado**: qualunque agente `police` poteva marcare
ricercati, cancellare rapporti o sequestrare veicoli. Da qui in avanti ogni callback passa
da `RequirePermission`.

## API pubblica

### `GetOfficer(src)` → `xPlayer|nil`

Il giocatore, se esiste e ha un lavoro in `Config.AllowedJobs`. Nessun controllo di grado
né rate limit. Usata solo da `sv_main.lua` per l'item usabile che apre il tablet.

### `RequirePermission(src, permission)` → `xPlayer|nil, motivo|nil`

La validazione completa, nell'ordine:

1. il giocatore esiste → `no_player`
2. il lavoro è autorizzato → `not_allowed_job`
3. il rate limit non è saturo → `rate_limited`
4. il grado ha il permesso → `no_permission`

Il rate limit è controllato **prima** del permesso: un client che martella endpoint non
autorizzati viene fermato dal limite, non solo respinto.

Un rifiuto per permesso scrive `Logger.Audit(officer, 'permission.denied', permission, ...)`.
Un rifiuto per rate limit scrive `Logger.Warn`.

### `RequirePermissionNotify(src, permission)` → `xPlayer|nil`

Come sopra, ma notifica il giocatore con `Locale(reason)` in caso di rifiuto. Usata dove
non c'è una risposta strutturata da riempire.

### `OfficerInfo(xPlayer)` → tabella

Descrittore riutilizzato in tutte le scritture:
`{ identifier, name, job, grade, gradeName, gradeLabel, ssn, source }`.

`gradeName` è la chiave per `Config.AuthorizedWeapons` e `Config.AuthorizedVehicles`;
`name` finisce in `officer_name` sulle righe di reati, note e rapporti.

## Rate limit

Stato in memoria per `source`, finestra scorrevole di `Config.RateLimit.Window` (10 s):

- `MaxCalls` 120 per finestra;
- `MaxWrites` 30 per finestra, contate solo se il permesso è in
  `Config.WritePermissions`.

`playerDropped` azzera lo stato di quel source.

## Note e trappole

- **Lo stato del rate limit è per `source`, non per identifier.** Un giocatore che si
  riconnette ottiene un source nuovo e un contatore pulito. Accettabile: riconnettersi
  costa più di 10 s.
- `RequirePermission(src, nil)` supera il controllo di grado ma **applica ancora** giocatore,
  lavoro e rate limit (contato come lettura). È il caso degli endpoint senza permesso
  dichiarato.
- La finestra non è veramente scorrevole: è a **blocchi**. Alla scadenza il contatore
  riparte da zero, quindi un burst a cavallo di due finestre passa il doppio del limite.
  Sufficiente per l'anti-abuso, non per un rate limit rigoroso.
- **`Config.Duty.ReadOnlyOffDuty` non è applicato qui.** Un agente fuori servizio può
  ancora scrivere sul MDT. Se serve, il posto giusto è questa funzione.
- `OfficerInfo` chiama `Framework.GetName`, che a sua volta può fare più `get()`: non
  chiamarla in un ciclo su molte righe.

## Correlati

[shared/sh_permissions.md](../shared/sh_permissions.md) ·
[ARCHITECTURE.md](../ARCHITECTURE.md) §4 · [server/sv_main.md](sv_main.md)

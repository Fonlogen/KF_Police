# server/sv_jail.lua

**Ruolo:** carcere. Tempo residuo persistente, timer server, rilascio automatico.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_duty.lua`

## Cosa fa

Il tempo residuo vive su **`kf_police_jail` in secondi**, quindi sopravvive a
disconnessione e restart della risorsa. Il rilascio automatico **non dipende dall'agente
che ha arrestato**: lo esegue il server anche se quell'agente è offline.

Stato in memoria: mappa `jailed` indicizzata per `identifier`, con
`{ seconds, total, reason, cell, source, ticks, officerId, officerName, jailedAt }`.

## API pubblica

### `GetJailStatus(identifier)` → tabella|nil

Prima guarda la memoria (dato **vivo**, aggiornato dal tick), poi il database. Ritorna
`{ jailed, secondsRemaining, totalSeconds, reason, cell, officer, jailedAt, label }`.
Usata da `sv_citizens.lua` per il dossier.

### `GetCellById(cellId)` → cella|nil

Cerca in `Config.Jail.Cells`.

### `JailPlayer(officer, identifier, seconds, reason, cellId)` → `ok, messaggio`

1. `Config.Jail.Enabled` → altrimenti `jail_disabled`;
2. non già detenuto → altrimenti `jail_already`;
3. `ClampInt(seconds, 1, Config.Jail.MaxSeconds, 60)`;
4. cella: quella richiesta, oppure `pickCell()` (prima con posto libero) → altrimenti
   `jail_no_cell`;
5. scrive in memoria e `persist()` su database;
6. se il bersaglio è **online**: `Inventory.StripWeapons`, `KF_Police:Client:Jailed`,
   notifica;
7. audit, `Invalidate('jail')`, `Invalidate('citizen', ...)`, `PushCounters()`.

`officer` può essere `nil` (azione di sistema): `officer_name` diventa `'Sistema'`.

L'upsert di `persist()` preserva `jailed_at` se la detenzione era già attiva, e azzera
`released_at`.

### `ReleasePlayer(officer, identifier, automatic)` → boolean

Funziona anche se il detenuto **non è in memoria** (controlla il database). Azzera
`seconds_remaining`, imposta `released_at = NOW()`, e se il bersaglio è online manda
`KF_Police:Client:Released` con le coordinate di rilascio.

Audit come `jail.release` o `jail.auto_release`.

## Endpoint

| Endpoint | Permesso | Note |
|---|---|---|
| `jail:list` | `mdt.jail.view` | detenzioni attive; il residuo viene dalla **memoria** se presente, così è aggiornato al secondo |
| `jail:send` | `jail.send` | accetta `months` **oppure** `seconds`; `months × SecondsPerMonth` |
| `jail:release` | `jail.release` | |

## Il timer

Un thread aspetta `Database.WaitReady(30000)`, poi gira ogni `Config.Jail.Tick` (5 s):

- per ogni detenuto aggiorna `source` (online/offline);
- scala i secondi **solo se** è online oppure `Config.Jail.CountOffline`;
- se online manda `KF_Police:Client:JailTick` con il residuo;
- a `<= 0` chiama `ReleasePlayer(nil, identifier, true)`;
- ogni `PersistEvery` tick (6 → 30 s) scrive il residuo su database.

## Persistenza e ripristino

| Momento | Azione |
|---|---|
| `Database.OnReady` | ricarica i detenuti attivi dal database in memoria, stampa quanti |
| `esx:playerLoaded` | dopo 4 s rimanda in cella (se `TeleportOnJoin`) |
| `playerDropped` | scrive il residuo su database, azzera `source` |
| `onResourceStop` | scrive il residuo di tutti |

I 4 s di attesa su `playerLoaded` servono a far finire di caricare il personaggio prima
del teletrasporto.

## Note e trappole

- **Il residuo su database è aggiornato ogni 30 s, non ogni tick.** Un crash del server
  (non uno stop pulito) regala fino a 30 s di pena. Accettabile.
- `jail:list` mostra `online` come `live ~= nil and live.source ~= nil`: un detenuto in
  database ma non in memoria (mai caricato) appare offline anche se è connesso.
- `pickCell()` conta solo i detenuti **in memoria**. Dopo il ripristino da database la
  memoria è completa, quindi il conto è corretto.
- `JailPlayer` non verifica che il cittadino esista in `users`: lo fa l'endpoint
  `jail:send`. Chiamandola da codice (es. `sv_actions.lua`) il controllo è la validazione
  del bersaglio.
- Il confinamento nell'area è **client-side** (`cl_jail.lua`): un client modificato può
  uscire. Il server non verifica la posizione del detenuto.
- `JailPage`, la UI che consuma `jail:list`, **non è ancora scritta**.

## Correlati

[config/cfg_jail.md](../config/cfg_jail.md) · [client/cl_jail.md](../client/cl_jail.md) ·
[server/sv_actions.md](sv_actions.md) ·
[web/pages/MANCANTI.md](../web/pages/MANCANTI.md)

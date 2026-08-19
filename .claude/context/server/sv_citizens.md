# server/sv_citizens.lua

**Ruolo:** anagrafica: ricerca paginata e dossier completo del cittadino.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, primo dei moduli di dominio

## Cosa fa

La ricerca è **SQL e paginata**: nessun elenco completo viene mai inviato alla NUI. Le
colonne ordinabili sono su **lista bianca**, quindi la NUI non può iniettare SQL passando
un nome di colonna arbitrario.

## Etichette dei lavori

`RefreshJobLabels()` carica `jobs` e `job_grades` in due mappe locali, popolate con
`Database.OnReady`. `GetJobLabel(jobName, grade)` produce `"LSPD - Captain"`, e
`"Disoccupato"` per lavoro vuoto o `unemployed`.

Cache **mai invalidata a runtime**: un lavoro rinominato in database richiede una chiamata
manuale a `RefreshJobLabels()` o un restart.

## Endpoint

### `citizens:search` — `mdt.citizen.view`

Payload: `query`, `filter` (`wanted`|`jailed`), `sortBy`, `sortDir`, `page`, `pageSize`.

Join fisso su `users` + `kf_police_profiles` + `kf_police_jail` (solo detenzioni attive).

La ricerca copre `firstname`, `lastname`, il nome completo concatenato, `ssn`,
`phone_number`.

Lista bianca `SORTABLE`: `firstname`, `lastname`, `nationality`, `job`, `ssn`. Qualunque
altro valore ricade su `u.lastname`.

Ritorna `rows`, `total`, `page`, `pageSize` e **`wantedCount`** (usato
dall'intestazione della pagina per "8 - 1 ricercato").

Se il `COUNT(*)` ritorna `nil` (errore SQL, non zero righe) risponde `invalid_data`: è
l'uso pratico della distinzione introdotta dal bug L9.

### `citizens:get` — `mdt.citizen.view`

Dossier completo di un `identifier`. Compone:

| Sezione | Fonte |
|---|---|
| `citizen` | `users` + `EnsureProfile` |
| `charges`, `totals` | `GetCitizenCharges` |
| `notes` | `GetCitizenNotes` |
| `vehicles` | `owned_vehicles` LEFT JOIN `kf_police_vehicle_flags` |
| `licenses` | `user_licenses` LEFT JOIN `licenses` |
| `properties` | `coin_system_items` |
| `reports` | `kf_police_report_involved` INNER JOIN `kf_police_reports`, max 50 |
| `jail` | `GetJailStatus` da `sv_jail.lua` |

Licenze e proprietà sono protette da `Database.TableExists`: su un server senza quelle
tabelle il dossier esce comunque, con le liste vuote.

### `citizens:setMugshot` — `mdt.note.create`

Scrive `mugshot` su `kf_police_profiles` (max 512 caratteri, `nil` se vuoto).

## Funzioni globali riusate da altri moduli

| Funzione | Usata da |
|---|---|
| `GetCitizenCharges(identifier)` → `lista, totali` | `sv_charges.lua`, `sv_actions.lua` |
| `GetCitizenNotes(identifier)` | `sv_notes.lua` |
| `EnsureProfile(identifier, ssn)` | `sv_wanted.lua`, `sv_citizens.lua` |
| `GetJobLabel(jobName, grade)` | `sv_duty.lua`, `sv_wanted.lua` |
| `DecodeVehicleModel(vehicleJson)` | `sv_vehicles.lua`, `sv_reports.lua` |

`GetCitizenCharges` calcola i totali **escludendo i reati annullati**: `totalFine`,
`totalMonths`, `unpaidFine`, `count`. `totalMonths` è quello che `cl_actions_citizen.lua`
propone come pena predefinita.

## Note e trappole

- `pageSize` e `offset` sono interpolati nella query con `format`, non passati come
  parametri: sono passati da `ClampInt` con limiti duri, quindi non sono un vettore di
  iniezione. Ma **non aggiungere altri valori interpolati** senza lo stesso trattamento.
- `DecodeVehicleModel` legge il blob `vehicle` di `owned_vehicles` e prende `model` o
  `name`: ritorna il nome tecnico (`sultan`), non un'etichetta leggibile. La UI mostra
  quello.
- `is_wanted` è testato sia con `ToBool` sia con `tonumber(...) == 1`: i driver MySQL
  ritornano `TINYINT(1)` in modi diversi.
- `EnsureProfile` non è transazionale: due chiamate in parallelo fanno due
  `INSERT IGNORE`, la seconda no-op. Innocuo.
- Le proprietà arrivano da `coin_system_items`, una tabella **specifica di questo server**:
  su un'installazione diversa non esiste e la lista resta vuota.

## Correlati

[server/sv_charges.md](sv_charges.md) · [server/sv_jail.md](sv_jail.md) ·
[web/pages/CitizensPage.md](../web/pages/CitizensPage.md) ·
[web/pages/CitizenSheet.md](../web/pages/CitizenSheet.md)

# sql/install.sql

**Ruolo:** schema completo. 17 tabelle, solo `CREATE TABLE IF NOT EXISTS`.
**Eseguito da:** `server/sv_database.lua` → `Database.Install()`, **primo** dei tre passi

## Proprietà

- **Idempotente**: può essere rieseguito su un database esistente senza danni. Non contiene
  `ALTER`, `DROP` né `INSERT`.
- Tutte le tabelle `InnoDB`, `utf8mb4_unicode_ci`.
- La chiave di riferimento è **`identifier`** (stabile), con `ssn` come colonna indicizzata
  di comodo per le ricerche: è la correzione del bug L5, che usava l'SSN come chiave.
- **Non aggiunge colonne alle tabelle preesistenti**: quello è compito di
  `sv_migrations.lua`, che gira dopo.

## Le tabelle

| Tabella | Chiave | Note |
|---|---|---|
| `kf_police_schema_version` | `version` | versioni di migrazione applicate |
| `kf_police_profiles` | `identifier` | `mugshot`, `is_wanted` + campi di segnalazione; indici su `ssn` e `is_wanted` |
| `kf_police_penalcode_categories` | `id` AI | `label`, `icon`, `sort_order` |
| `kf_police_penalcode` | `id` AI | **`code` UNIQUE**, `category_id`, `fine`, `jail_months`, `is_felony` |
| `kf_police_charges` | `id` AI | un reato = una riga; `voided_at`/`voided_by`/`void_reason`; indici su `identifier`, `report_id`, `created_at` |
| `kf_police_notes` | `id` AI | id da AUTO_INCREMENT (bug L6) |
| `kf_police_reports` | `id` AI | `status` ENUM, `is_confidential`; indici su `officer_id`, `status`, `created_at` |
| `kf_police_report_involved` | `(report_id, identifier, role)` | `role` ENUM suspect/victim/witness |
| `kf_police_report_vehicles` | `(report_id, plate)` | |
| `kf_police_tags` | `id` AI | `icon` FontAwesome, `color` esadecimale |
| `kf_police_report_tags` | `(report_id, tag_id)` | |
| `kf_police_vehicle_flags` | `plate` | flag persistenti (bug L3); indici su `is_stolen`, `is_impounded` |
| `kf_police_jail` | `identifier` | `seconds_remaining` persistente; indice su `released_at` |
| `kf_police_armory_stock` | `item` | nomi **minuscoli** |
| `kf_police_duty_log` | `id` AI | `action` ENUM in/out; indici su `identifier`, `at` |
| `kf_police_audit` | `id` AI | `payload` LONGTEXT JSON; indici su actor, action, at |
| `kf_police_orphan_records` | `id` AI | righe legacy il cui SSN non esiste più |

## Note e trappole

- **Nessuna `FOREIGN KEY`.** Voluto: le tabelle esterne (`users`, `owned_vehicles`) sono di
  altre risorse e la loro esistenza non è garantita. Conseguenza: nessuna cancellazione a
  cascata, i riferimenti orfani si gestiscono a mano (es. `penalcode:delete` mette a `NULL`
  i `penalcode_id` dei reati).
- La chiave primaria composita di `kf_police_report_involved` include il **ruolo**: la stessa
  persona può essere sospettato e testimone nello stesso rapporto.
- `kf_police_penalcode.code` è `UNIQUE`: un `INSERT` con codice duplicato fallisce. Vedi la
  nota in [server/sv_penalcode.md](../server/sv_penalcode.md).
- `plate` è `VARCHAR(12)` qui e `Config.Limits.plate = 12` in configurazione: **tenerli
  allineati**.
- `kf_police_jail` ha una riga per `identifier`: la storia delle detenzioni **non è
  conservata**, l'upsert riusa la stessa riga. Lo storico è solo in `kf_police_audit`.
- Le tabelle **lette ma non possedute**: `users`, `jobs`, `job_grades`, `owned_vehicles`,
  `user_licenses`, `licenses`, `coin_system_items`. Le ultime tre sono protette da
  `Database.TableExists`.
- Va dichiarato nei `files` di `fxmanifest.lua`, altrimenti `LoadResourceFile` non lo trova.

## Correlati

[server/sv_database.md](../server/sv_database.md) · [sql/seed.md](seed.md) ·
[server/sv_migrations.md](../server/sv_migrations.md) ·
[ARCHITECTURE.md](../ARCHITECTURE.md) §8

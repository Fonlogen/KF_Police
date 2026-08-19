# shared/locales/it.lua

**Ruolo:** locale italiano, quello predefinito (`Config.Locale = 'it'`).
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `sh_permissions.lua`

## Cosa fa

Popola `Locales['it']` e riassegna `Config.Locales = Locales`. Le chiavi sono lette da
`Locale(key, ...)` in `shared/sh_utils.lua`.

Circa 140 chiavi, raggruppate per area:

| Gruppo | Esempi |
|---|---|
| Accesso | `not_allowed_job`, `no_permission`, `rate_limited`, `mdt_not_ready`, `off_duty_read_only` |
| Dati | `invalid_data`, `citizen_not_found`, `vehicle_not_found`, `report_not_found`, `charge_not_found` |
| Rapporti | `report_created`, `report_updated`, `report_deleted` |
| Reati | `charge_added`, `charges_added` (`%d`), `charge_voided`, `charge_already_voided` |
| Ricercati e note | `wanted_updated`, `note_saved`, `note_deleted` |
| Veicoli | `vehicle_impounded`, `vehicle_marked_stolen`, `plate_check` (`%s`, `%s`) |
| Codice penale e tag | `article_saved`, `article_deleted`, `tag_saved` |
| Multe | `fine_issued` (`%s`), `fine_failed`, `fine_invalid_amount` |
| Radio | `radio_connected`, `radio_not_allowed`, `radio_unavailable` |
| Servizio | `duty_on`, `duty_off`, `duty_full`, `duty_required` |
| Spogliatoio | `uniform_applied`, `uniform_removed`, `uniform_missing` |
| Armeria | `armory_taken` (`%s`), `armory_out_of_stock`, `armory_no_money`, `armory_full` |
| Garage | `garage_no_space`, `garage_already_out`, `garage_not_service_vehicle` |
| Azioni di campo | `cuffed`, `too_far`, `search_need_restraint`, `lockpick_success`, `object_placed` |
| Carcere | `jail_sent` (`%s`), `jail_received` (`%s`), `jail_time_left` (`%s`), `jail_no_cell` |
| Progressi | `progress_impound`, `progress_lockpick`, `progress_search`, `progress_cuff` |

## Note e trappole

- **Nessuna lettera accentata.** Le stringhe usano `e` per `è`, `societa` per `società`.
  È voluto: evita problemi di codifica nella console del server e nei toast della NUI.
  Mantieni la convenzione.
- Le chiavi che contengono `%s` o `%d` vanno chiamate con l'argomento corrispondente:
  `Locale('jail_sent', FormatDuration(seconds))`. Senza argomento la stringa esce con il
  segnaposto grezzo (il `pcall` in `Locale` non lo intercetta, perché `string.format`
  senza argomenti su `%s` **lancia** e il `pcall` ritorna il valore non formattato).
- Le chiavi di errore sono anche i valori di `error` nelle risposte MDT: `MdtError(key)`
  mette `error = key` e `message = Locale(key)`. La UI può quindi decidere in base a
  `error` e mostrare `message`.
- **Deve restare allineato a `en.lua`**: stesse chiavi, stesso numero di segnaposto.
  Una chiave presente solo qui funziona in italiano e mostra il nome della chiave in
  inglese.

## Correlati

[shared/locales-en.md](locales-en.md) · [shared/sh_utils.md](sh_utils.md) ·
[server/sv_main.md](../server/sv_main.md)

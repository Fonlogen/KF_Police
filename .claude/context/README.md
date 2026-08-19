# Contesto KF_Police — indice

Un file `.md` per ogni file sorgente della risorsa. Serve a capire cosa fa ogni modulo
senza rileggere il sorgente.

**Prima di tutto leggi [ARCHITECTURE.md](ARCHITECTURE.md):** contiene i flussi che
attraversano più file (contratto NUI, permessi, avvio del database, invalidazioni) e
senza di quello i singoli documenti si capiscono a metà.

La regola di manutenzione di questi file è in [`../../CLAUDE.md`](../../CLAUDE.md) §2:
**chi modifica un sorgente aggiorna il suo `.md` nello stesso turno di lavoro.**

---

## Mappa in una schermata

```
Gioco (client Lua)                Server Lua                   Database
------------------                ----------                   --------
cl_nui.lua ── RegisterNUICallback('mdt')
     │
     └── lib.callback ─────────►  sv_main.lua
                                  KF_Police:mdt (unico ingresso)
                                       │ RequirePermission
                                       ▼
                                  sv_citizens / sv_charges / sv_reports / ...
                                       │                      ▼
                                       │              kf_police_* (17 tabelle)
                                       │
                                  Invalidate(scope) ─► client ─► NUI ricarica una vista

NUI (web/)
---------
main.tsx ─► MdtProvider ─► App.tsx ─► DeviceFrame / StatusBar / Sidebar / TabStrip
                                          └── pagina attiva ─► callMdt(endpoint)
```

---

## Trasversali

| Documento | Contenuto |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Contratto NUI, tabella completa degli endpoint, permessi, avvio DB, invalidazioni, eventi |
| [fxmanifest.md](fxmanifest.md) | Ordine di caricamento dei file e perché non usa glob |

## `config/` — configurazione

| Documento | File sorgente |
|---|---|
| [config/config.md](config/config.md) | `config/config.lua` — base, bridge, apertura MDT, scala UI, anti-abuso |
| [config/cfg_stations.md](config/cfg_stations.md) | `config/cfg_stations.lua` — stazioni, zone, blip |
| [config/cfg_duty.md](config/cfg_duty.md) | `config/cfg_duty.lua` — servizio e divise per grado |
| [config/cfg_armory.md](config/cfg_armory.md) | `config/cfg_armory.lua` — armi per grado, stock |
| [config/cfg_vehicles.md](config/cfg_vehicles.md) | `config/cfg_vehicles.lua` — veicoli di servizio |
| [config/cfg_actions.md](config/cfg_actions.md) | `config/cfg_actions.lua` — azioni di campo, oggetti piazzabili |
| [config/cfg_radio.md](config/cfg_radio.md) | `config/cfg_radio.lua` — canali pma-voice |
| [config/cfg_jail.md](config/cfg_jail.md) | `config/cfg_jail.lua` — carcere, celle, conversione pena |
| [config/cfg_banking.md](config/cfg_banking.md) | `config/cfg_banking.lua` — 9 adapter di fatturazione |

## `shared/` — condivisi client e server

| Documento | File sorgente |
|---|---|
| [shared/sh_utils.md](shared/sh_utils.md) | `shared/sh_utils.lua` — utilità, sanificazione, `StripEmoji` |
| [shared/sh_permissions.md](shared/sh_permissions.md) | `shared/sh_permissions.lua` — permessi per grado, ereditarietà `@N` |
| [shared/locales-it.md](shared/locales-it.md) | `shared/locales/it.lua` — locale italiano (predefinito) |
| [shared/locales-en.md](shared/locales-en.md) | `shared/locales/en.lua` — locale inglese (ripiego) |

## `modules/` — bridge verso le altre risorse

| Documento | File sorgente |
|---|---|
| [modules/framework-sh_bridge.md](modules/framework-sh_bridge.md) | `modules/framework/sh_bridge.lua` — contratto del bridge framework |
| [modules/framework-cl_esx.md](modules/framework-cl_esx.md) | `modules/framework/cl_esx.lua` — ESX lato client |
| [modules/framework-sv_esx.md](modules/framework-sv_esx.md) | `modules/framework/sv_esx.lua` — ESX lato server, conti società |
| [modules/target-cl_ox.md](modules/target-cl_ox.md) | `modules/target/cl_ox.lua` — zone ox_target |
| [modules/target-cl_marker.md](modules/target-cl_marker.md) | `modules/target/cl_marker.lua` — ripiego a marker classici |
| [modules/inventory-sv_ox.md](modules/inventory-sv_ox.md) | `modules/inventory/sv_ox.lua` — ox_inventory |
| [modules/inventory-sv_esx.md](modules/inventory-sv_esx.md) | `modules/inventory/sv_esx.lua` — inventario ESX classico |
| [modules/clothing-cl_appearance.md](modules/clothing-cl_appearance.md) | `modules/clothing/cl_appearance.lua` — fivem-appearance |
| [modules/clothing-cl_skinchanger.md](modules/clothing-cl_skinchanger.md) | `modules/clothing/cl_skinchanger.lua` — skinchanger / esx_skin |
| [modules/voice-cl_pma.md](modules/voice-cl_pma.md) | `modules/voice/cl_pma.lua` — pma-voice, **correzione bug L1** |
| [modules/notify-cl_notify.md](modules/notify-cl_notify.md) | `modules/notify/cl_notify.lua` — notifiche dentro o fuori dal tablet |

## `server/` — logica autorevole

| Documento | File sorgente |
|---|---|
| [server/sv_logger.md](server/sv_logger.md) | `server/sv_logger.lua` — audit a lotti, pulizia |
| [server/sv_permissions.md](server/sv_permissions.md) | `server/sv_permissions.lua` — `RequirePermission`, rate limit |
| [server/sv_migrations.md](server/sv_migrations.md) | `server/sv_migrations.lua` — migrazione dallo schema monolitico |
| [server/sv_database.md](server/sv_database.md) | `server/sv_database.lua` — wrapper SQL, esecuzione file, sequenza di avvio |
| [server/sv_main.md](server/sv_main.md) | `server/sv_main.lua` — dispatcher endpoint, invalidazioni, bootstrap |
| [server/sv_citizens.md](server/sv_citizens.md) | `server/sv_citizens.lua` — ricerca e dossier cittadini |
| [server/sv_charges.md](server/sv_charges.md) | `server/sv_charges.lua` — reati, aggiunta multipla, annullamento |
| [server/sv_notes.md](server/sv_notes.md) | `server/sv_notes.lua` — note di servizio |
| [server/sv_wanted.md](server/sv_wanted.md) | `server/sv_wanted.lua` — ricercati |
| [server/sv_reports.md](server/sv_reports.md) | `server/sv_reports.lua` — rapporti, giunzioni, tag |
| [server/sv_vehicles.md](server/sv_vehicles.md) | `server/sv_vehicles.lua` — veicoli e flag persistenti |
| [server/sv_penalcode.md](server/sv_penalcode.md) | `server/sv_penalcode.lua` — codice penale e categorie |
| [server/sv_duty.md](server/sv_duty.md) | `server/sv_duty.lua` — servizio, roster, monte ore |
| [server/sv_jail.md](server/sv_jail.md) | `server/sv_jail.lua` — carcere, timer persistente |
| [server/sv_fines.md](server/sv_fines.md) | `server/sv_fines.lua` — sanzioni e adapter banking |
| [server/sv_armory.md](server/sv_armory.md) | `server/sv_armory.lua` — armeria, stock atomico |
| [server/sv_garage.md](server/sv_garage.md) | `server/sv_garage.lua` — veicoli di servizio |
| [server/sv_actions.md](server/sv_actions.md) | `server/sv_actions.lua` — azioni di campo, `ValidateTarget` |

## `client/` — presentazione e input

| Documento | File sorgente |
|---|---|
| [client/cl_main.md](client/cl_main.md) | `client/cl_main.lua` — utilità condivise, blip stazioni |
| [client/cl_nui.md](client/cl_nui.md) | `client/cl_nui.lua` — geometria tablet, ponte NUI, apertura |
| [client/cl_duty.md](client/cl_duty.md) | `client/cl_duty.lua` — entrata/uscita servizio |
| [client/cl_cloakroom.md](client/cl_cloakroom.md) | `client/cl_cloakroom.lua` — spogliatoio, divise |
| [client/cl_armory.md](client/cl_armory.md) | `client/cl_armory.lua` — menu armeria |
| [client/cl_garage.md](client/cl_garage.md) | `client/cl_garage.lua` — prelievo e riconsegna veicoli |
| [client/cl_boss.md](client/cl_boss.md) | `client/cl_boss.lua` — menu società |
| [client/cl_cuffs.md](client/cl_cuffs.md) | `client/cl_cuffs.lua` — manette, controlli disabilitati |
| [client/cl_drag.md](client/cl_drag.md) | `client/cl_drag.lua` — scorta del cittadino |
| [client/cl_jail.md](client/cl_jail.md) | `client/cl_jail.lua` — timer e confinamento |
| [client/cl_impound.md](client/cl_impound.md) | `client/cl_impound.lua` — sequestro e deposito |
| [client/cl_objects.md](client/cl_objects.md) | `client/cl_objects.lua` — oggetti piazzabili |
| [client/cl_actions_citizen.md](client/cl_actions_citizen.md) | `client/cl_actions_citizen.lua` — menu azioni su cittadino |
| [client/cl_actions_vehicle.md](client/cl_actions_vehicle.md) | `client/cl_actions_vehicle.lua` — menu azioni su veicolo |
| [client/cl_radio.md](client/cl_radio.md) | `client/cl_radio.lua` — radio, endpoint locali `radio:*` |
| [client/cl_blips.md](client/cl_blips.md) | `client/cl_blips.lua` — blip colleghi e allerte |

## `sql/`

| Documento | File sorgente |
|---|---|
| [sql/install.md](sql/install.md) | `sql/install.sql` — 17 tabelle, schema completo |
| [sql/seed.md](sql/seed.md) | `sql/seed.sql` — categorie, tag, 59 articoli |
| [sql/migrations-001_normalize.md](sql/migrations-001_normalize.md) | `sql/migrations/001_normalize.sql` — versione manuale della migrazione |
| [sql/backup.md](sql/backup.md) | `sql/backup/` — dump gitignorati |

## `web/` — NUI

### Fondazioni

| Documento | File sorgente |
|---|---|
| [web/main.md](web/main.md) | `web/src/main.tsx` — punto d'ingresso |
| [web/index-css.md](web/index-css.md) | `web/src/index.css` — reset, base, animazioni |
| [web/styles/tokens.md](web/styles/tokens.md) | `web/src/styles/tokens.css` — **fonte unica** di colori e misure |
| [web/styles/fonts.md](web/styles/fonts.md) | `web/src/styles/fonts.css` — Inter e JetBrains Mono locali |
| [web/toolchain.md](web/toolchain.md) | `package.json`, `vite.config.ts`, `tailwind.config.js`, `tsconfig*.json`, `postcss.config.js`, `.eslintrc.cjs`, `index.html`, `vite-env.d.ts` |

### `lib/`, `hooks/`, `state/`

| Documento | File sorgente |
|---|---|
| [web/lib/types.md](web/lib/types.md) | `web/src/lib/types.ts` — tipi condivisi con il server |
| [web/lib/nui.md](web/lib/nui.md) | `web/src/lib/nui.ts` — `callMdt`, `closeMdt` |
| [web/lib/format.md](web/lib/format.md) | `web/src/lib/format.ts` — formattazione it-IT |
| [web/lib/mock.md](web/lib/mock.md) | `web/src/lib/mock.ts` — dati finti per `npm run dev` |
| [web/hooks/useNuiEvent.md](web/hooks/useNuiEvent.md) | `web/src/hooks/useNuiEvent.ts` |
| [web/hooks/useTabletScale.md](web/hooks/useTabletScale.md) | `web/src/hooks/useTabletScale.ts` |
| [web/hooks/usePagedQuery.md](web/hooks/usePagedQuery.md) | `web/src/hooks/usePagedQuery.ts` |
| [web/hooks/useRevisionEffect.md](web/hooks/useRevisionEffect.md) | `web/src/hooks/useRevisionEffect.ts` |
| [web/state/MdtProvider.md](web/state/MdtProvider.md) | `web/src/state/MdtProvider.tsx` — stato globale, linguette |

### `components/` — design system

| Documento | File sorgente |
|---|---|
| [web/components/Icon.md](web/components/Icon.md) | registro `ICONS`, zero emoji |
| [web/components/Button.md](web/components/Button.md) | `Button`, `IconButton` |
| [web/components/Field.md](web/components/Field.md) | Text/Number/TextArea/Select/Checkbox |
| [web/components/DataTable.md](web/components/DataTable.md) | tabella, virtualizzazione, `OpenCell` |
| [web/components/Sheet.md](web/components/Sheet.md) | `Sheet`, `SheetHeader`, `SheetBody`, `Panel`, `DataRow` |
| [web/components/Sidebar.md](web/components/Sidebar.md) | navigazione 13 rem |
| [web/components/StatusBar.md](web/components/StatusBar.md) | barra di stato |
| [web/components/TabStrip.md](web/components/TabStrip.md) | linguette |
| [web/components/RadioDock.md](web/components/RadioDock.md) | dock radio nel telaio |
| [web/components/DeviceFrame.md](web/components/DeviceFrame.md) | telaio del tablet |
| [web/components/Modal.md](web/components/Modal.md) | `Modal`, `ConfirmDialog` |
| [web/components/Toast.md](web/components/Toast.md) | notifiche interne |
| [web/components/Chip.md](web/components/Chip.md) | chip, colori dal database |
| [web/components/Stamp.md](web/components/Stamp.md) | timbri del fascicolo |
| [web/components/Avatar.md](web/components/Avatar.md) | foto segnaletica, ripiego locale |
| [web/components/SegmentedControl.md](web/components/SegmentedControl.md) | filtri dell'intestazione |
| [web/components/Pagination.md](web/components/Pagination.md) | paginazione |
| [web/components/EmptyState.md](web/components/EmptyState.md) | stato vuoto |
| [web/components/Skeleton.md](web/components/Skeleton.md) | scheletro di caricamento |

### `pages/` — schermate

| Documento | File sorgente | Stato |
|---|---|---|
| [web/pages/App.md](web/pages/App.md) | `web/src/pages/App.tsx` | Scritto, **non compila**: importa 6 pagine mancanti |
| [web/pages/registry.md](web/pages/registry.md) | `web/src/pages/registry.ts` | Completo |
| [web/pages/CitizensPage.md](web/pages/CitizensPage.md) | `web/src/pages/CitizensPage.tsx` | Scritto |
| [web/pages/CitizenSheet.md](web/pages/CitizenSheet.md) | `web/src/pages/CitizenSheet.tsx` | Scritto |
| [web/pages/VehiclesPage.md](web/pages/VehiclesPage.md) | `web/src/pages/VehiclesPage.tsx` | Scritto |
| [web/pages/VehicleSheet.md](web/pages/VehicleSheet.md) | `web/src/pages/VehicleSheet.tsx` | Scritto |
| [web/pages/ReportsPage.md](web/pages/ReportsPage.md) | `web/src/pages/ReportsPage.tsx` | Scritto |
| [web/pages/MANCANTI.md](web/pages/MANCANTI.md) | — | Le 6 pagine da scrivere, con endpoint e requisiti |

### Legacy da eliminare

| Documento | File coperti |
|---|---|
| [web/legacy-ui.md](web/legacy-ui.md) | `pages/App.css`, `pages/components/*` (12), `pages/sections/*` (10), `providers/VisibilityProvider.tsx`, `utils/*` (6) — **30 file, tutti da cancellare in F2c** |

---

## Nota sulle due deroghe a "un `.md` per file"

Per non sporcare il contesto sono raggruppati:

1. **`web/toolchain.md`** — otto file di configurazione della build da 6-40 righe
   (`postcss.config.js`, `tsconfig.json`, ...). Un documento a testa sarebbe rumore.
2. **`web/legacy-ui.md`** — i 30 file della vecchia UI, che si cancellano tutti insieme
   e non compilano più. Ognuno ha la sua sezione dentro il documento.

Se una di queste categorie diventa di nuovo terreno di lavoro attivo, va splittata in
documenti per file.

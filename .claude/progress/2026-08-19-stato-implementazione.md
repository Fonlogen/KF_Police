# Stato dell'implementazione — 2026-08-19

> Companion di `.claude/handoff.md`. Qui c'è l'inventario file per file, le decisioni prese oltre a
> quanto scritto nel piano e le scoperte fatte sull'ambiente reale.
> Il piano di riferimento è `.claude/plans/2026-08-19-kf-police-mdt-rework.md`.

---

## 1. Inventario: cosa esiste adesso

### 1.1 Configurazione — `config/` (nuova, sostituisce `config.lua` in radice)

| File | Contenuto |
|---|---|
| `config.lua` | Base, bridge selezionati, lavori, apertura MDT (**tasto F5**), `Config.UI` per la scala, pagine, `Config.RateLimit`, `Config.Limits`, `Config.Audit` |
| `cfg_stations.lua` | Stazione LSPD: blip, spogliatoi, armerie, garage (auto + elicottero), punti di riconsegna, boss, deposito sequestri. Config marker e blip colleghi |
| `cfg_duty.lua` | Servizio interno, spogliatoio, divise per grado e sesso (migrate da `Config.Uniforms` di esx_policejob) + `bulletproof` e `gilet` |
| `cfg_armory.lua` | Armi autorizzate per grado, oggetti, stock iniziale, `BuyFrom` |
| `cfg_vehicles.lua` | Veicoli di servizio per categoria e grado, prefisso targa `LSPD` |
| `cfg_actions.lua` | Distanze massime, item manette/lockpick, voci del menu cittadino e veicolo con il permesso richiesto, oggetti piazzabili, sequestro |
| `cfg_radio.lua` | Canali pma-voice con `short` per i pulsanti del RadioDock |
| `cfg_jail.lua` | Secondi per mese, tetto massimo, celle, area di confinamento, punto di rilascio |
| `cfg_banking.lua` | 9 adapter di fatturazione descritti per nome di argomento |

### 1.2 Bridge — `modules/`

| File | Note |
|---|---|
| `framework/sh_bridge.lua` | Contratto documentato + `ResolveGradeName`, `IsAllowedJob`, `IsPoliceJob` |
| `framework/cl_esx.lua` · `sv_esx.lua` | Implementazione ESX. Il server espone anche i conti societa' via `esx_addonaccount` |
| `target/cl_ox.lua` · `cl_marker.lua` | Stesso contratto `Target.AddZone/RemoveZone`. Il marker mostra un suggerimento e reagisce a E |
| `inventory/sv_ox.lua` · `sv_esx.lua` | `Count/AddItem/RemoveItem/AddWeapon/RemoveWeapon/CanCarry/GetInventory/StripWeapons` |
| `clothing/cl_appearance.lua` · `cl_skinchanger.lua` | Le divise usano le chiavi skinchanger; `cl_appearance` le traduce negli indici nativi GTA. L'abito civile è salvato su KVP, quindi sopravvive a un rientro in divisa |
| `voice/cl_pma.lua` | **Correzione L1.** Espone anche presenti sul canale e chi parla, agganciandosi agli eventi `pma-voice:syncRadioData` / `addPlayerToRadio` / `removePlayerFromRadio` / `setTalkingOnRadio` |
| `notify/cl_notify.lua` | Se il tablet è aperto la notifica va dentro il tablet (`mdt:notify`), altrimenti esce con `lib.notify` |

### 1.3 Condivisi — `shared/`

- `sh_utils.lua`: `Locale` con `string.format` e ripiego su `en`, `Trim`, `SanitizeText`, `ClampInt`,
  `ToBool`, `NormalizePlate`, `FormatDuration`, `SqlNow`, **`StripEmoji`**.
- `sh_permissions.lua`: `Config.Permissions` (police 0–4, ambulance 0–4), `Config.WritePermissions`,
  `ResolvePermissions` con cache, `HasPermission`, `PermissionList`.
- `locales/it.lua` e `locales/en.lua`: ~140 chiavi ciascuno, allineate.

### 1.4 Server — `server/`

| File | Ruolo |
|---|---|
| `sv_logger.lua` | `kf_police_audit` a lotti ogni 2 s, pulizia oltre `KeepDays`, `Logger.List` |
| `sv_permissions.lua` | `GetOfficer`, `RequirePermission`, `RequirePermissionNotify`, `OfficerInfo`, rate limit per source |
| `sv_migrations.lua` | Allineamento colonne, pulizia emoji dai tag, backup, profili, esplosione reati e note, orfani, giunzioni dei rapporti, stock iniziale, verifica dei conteggi |
| `sv_database.lua` | Wrapper con errori **visibili** (L9), introspezione, `RunSqlFile` con splitter che rispetta stringhe e commenti, sequenza install → migrate → seed |
| `sv_main.lua` | `RegisterMdtEndpoint`, dispatcher `KF_Police:mdt`, `Invalidate`/`PushCounters`/`GetMdtCounters`, `bootstrap`, item usabili, registrazione telefono e società, evento di allerta |
| `sv_citizens.lua` | Cache etichette lavoro, `citizens:search` (ordinamento su lista bianca), `citizens:get` (dossier completo), `citizens:setMugshot`, `GetCitizenCharges`, `GetCitizenNotes`, `EnsureProfile` |
| `sv_charges.lua` | `charges:add` **multiplo e transazionale** (L2), `charges:void` tracciato, `charges:markPaid` |
| `sv_notes.lua` | `notes:add/update/delete`, id da AUTO_INCREMENT (L6) |
| `sv_wanted.lua` | `wanted:list` con id stabili (L7), `wanted:set` |
| `sv_reports.lua` | `reports:list/get/save/delete` con giunzioni in transazione, riservatezza; `tags:list/save/delete` con `StripEmoji` |
| `sv_vehicles.lua` | `vehicles:search/get/setFlag/impounded`, `GetVehicleRecord`, `SetVehicleFlags` persistente (L3) |
| `sv_penalcode.lua` | `penalcode:list` per categoria, `save`, `delete` (i reati già contestati conservano il testo), `saveCategory` |
| `sv_duty.lua` | `SetDuty`, `duty:toggle/state/roster` con monte ore da `kf_police_duty_log`, `KF_Police:duty:colleagues` |
| `sv_jail.lua` | `JailPlayer`, `ReleasePlayer`, `GetJailStatus`, `jail:list/send/release`, timer persistente, ripristino all'avvio, rilascio automatico |
| `sv_fines.lua` | Adapter di fatturazione (self esplicito), `IssueFine`, `fines:issue/list` |
| `sv_armory.lua` | Catalogo per grado, `take` con `UPDATE` condizionato **atomico**, `store`, `buy` |
| `sv_garage.lua` | `catalog/spawn/store` con `CreateVehicleServerSetter`, un veicolo per agente, pulizia su disconnessione e stop risorsa |
| `sv_actions.lua` | `ValidateTarget` (distanza misurata **sul server**), cuff, drag, vehicle, search, seize, identify, licenses, lockpick, impound, markStolen, plateCheck, jail, pendingSentence |

### 1.5 Client — `client/`

`cl_main.lua` (utilità + blip stazioni + stato servizio iniziale) · `cl_nui.lua`
(`ComputeTabletGeometry`, apertura/chiusura, ponte NUI, `OpenMdtOnCitizen`/`OpenMdtOnVehicle`, push
del server, rilevamento cambio risoluzione) · `cl_duty.lua` · `cl_cloakroom.lua` · `cl_armory.lua` ·
`cl_garage.lua` · `cl_boss.lua` · `cl_cuffs.lua` · `cl_drag.lua` · `cl_jail.lua` · `cl_impound.lua` ·
`cl_objects.lua` · `cl_actions_citizen.lua` (F7) · `cl_actions_vehicle.lua` (F8) · `cl_radio.lua` ·
`cl_blips.lua`.

### 1.6 SQL — `sql/`

- `install.sql` — 234 righe, solo `CREATE TABLE IF NOT EXISTS`. 17 tabelle.
- `seed.sql` — 126 righe. 4 categorie, 10 tag con icona, **59 articoli** di codice penale.
- `migrations/001_normalize.sql` — versione manuale/di riferimento della migrazione.
- `backup/kfdev_esx_20260819.sql` — dump completo (22 MB), **gitignorato**.

### 1.7 UI — `web/`

**Nuovo e funzionante (non ancora collegato):**

```
web/assets/fonts/           inter-latin.woff2, inter-latin-ext.woff2,
                            jetbrains-mono-latin.woff2, jetbrains-mono-latin-ext.woff2
web/src/styles/             fonts.css, tokens.css
web/src/lib/                types.ts, nui.ts, format.ts, mock.ts
web/src/hooks/              useNuiEvent.ts (corretto), useTabletScale.ts, usePagedQuery.ts
web/src/state/              MdtProvider.tsx
web/src/pages/registry.ts   metadati delle pagine
web/src/components/         Icon, Button (+IconButton), Field (Text/Number/TextArea/Select/Checkbox),
                            Stamp, Avatar, Chip, EmptyState, Skeleton (+SkeletonRows), Pagination,
                            SegmentedControl, Modal (+ConfirmDialog), Toast (+ToastStack),
                            DataTable (+OpenCell), StatusBar, Sidebar, TabStrip,
                            Sheet (+SheetHeader/SheetBody/Panel/DataRow), RadioDock, DeviceFrame
web/tailwind.config.js      legge i token
web/src/index.css           reset + base, importa fonts.css e tokens.css
```

**Vecchio, ancora attivo, da sostituire:** `web/src/main.tsx`, `web/src/pages/App.tsx`,
`web/src/pages/App.css`, `web/src/pages/components/*` (12 file), `web/src/pages/sections/*`
(10 file), `web/src/providers/VisibilityProvider.tsx`, `web/src/utils/*`.

### 1.8 File eliminati

`config.lua` (radice) · `kf_police.sql` · `server/sv_functions.lua` · `server/sv_banking.lua` ·
`client/cl_functions.lua` · `client/cl_events.lua`.

---

## 2. Come sono stati corretti i bug del piano

### Lato Lua

| # | Correzione | Dove |
|---|---|---|
| L1 | Export chiamato con `self` esplicito | `modules/voice/cl_pma.lua`, `server/sv_fines.lua` |
| L2 | Ogni reato è una riga, inserimenti in transazione | `server/sv_charges.lua` |
| L3 | Flag su `kf_police_vehicle_flags` | `server/sv_vehicles.lua` |
| L4 | Nessuna cache globale, query paginate, `Invalidate` mirato | `server/sv_main.lua` + tutti i moduli |
| L5 | Chiave su `identifier`, `ssn` solo indicizzato | schema + migrazione |
| L6 | Id note da AUTO_INCREMENT | `server/sv_notes.lua` |
| L7 | Ricercati identificati da `identifier` | `server/sv_wanted.lua` |
| L8 | Tasto predefinito **F5** | `config/config.lua`, `client/cl_nui.lua` |
| L9 | Errore SQL → `nil` + stampa con la query | `server/sv_database.lua` |
| L10 | `fine` e `jail_months` numerici; migrazione converte `sanction` | schema + `sv_migrations.lua` |
| L11 | `StripEmoji` + colonna `icon` | `shared/sh_utils.lua`, `seed.sql`, `sv_migrations.lua` |
| L12 | `RequirePermission` su **ogni** endpoint | `server/sv_permissions.lua` |

### Lato UI

| # | Correzione | Dove |
|---|---|---|
| U1 | Listener in `useEffect` con cleanup | `hooks/useNuiEvent.ts`, `Modal.tsx`, `Sheet.tsx` |
| U2 | `useMdt()` lancia se manca il provider, nessun ciclo di attesa | `state/MdtProvider.tsx` |
| U3 | Mappe di classi statiche | `Button.tsx`, `Chip.tsx`, `Stamp.tsx` |
| U4 | Valori dinamici via `style`, non interpolati in classi | `DeviceFrame.tsx`, `Chip.tsx`, `DataTable.tsx` |
| U5 | Nessun centraggio verticale forzato | struttura di `DeviceFrame`/`Sheet` |
| U6 | Altezza tabella non fissa: `flex-1` + `overflow-y-auto` | `DataTable.tsx` |
| U7 | `Modal` controllato dalle props, chiusura funzionante | `Modal.tsx` |
| U11 | `width` e `flex` mutuamente esclusivi | `DataTable.tsx` (`cellStyle`) |
| U13 | Tre raggi + il cerchio, colori solo da token | `tokens.css` |
| U8, U9, U10, U12 | **Aperti**: dipendono dalle pagine (§5 dell'handoff) e da F9 | — |

---

## 3. Decisioni prese oltre al piano

Nessuna contraddice il piano; sono raffinamenti resi necessari dal codice reale.

1. **Un solo endpoint di trasporto NUI.** Il piano elenca i callback uno per uno (§6.1); qui sono
   registrati singolarmente lato server con `RegisterMdtEndpoint`, ma il trasporto è unico
   (`KF_Police:mdt`). Motivo: un solo punto dove validare, tracciare e limitare.
2. **`sql/seed.sql` separato da `sql/install.sql`.** Necessario: i seed usano colonne che su un DB
   preesistente le aggiunge la migrazione. Senza la separazione si prende
   `ERROR 1054 Unknown column 'icon'`.
3. **`client/cl_boss.lua` aggiunto** (non nell'elenco §4 del piano). Il boss menu è una funzione da
   assorbire (§7) e meritava un file suo.
4. **Endpoint `radio:*` e `client:*` gestiti sul client** con `RegisterLocalMdtEndpoint`: pma-voice e
   le coordinate sono lato client, un giro sul server sarebbe stato inutile.
5. **Registro `ICONS` ampliato** oltre l'elenco §3.8: servivano le icone dei tag (`weapon`, `money`,
   `fist`, `spray`, `drink`, `drug`), quelle di ordinamento e quelle di stato.
6. **Nuovi token**: scala icone (`--ico-*`), altezze pulsante (`--h-btn-*`), altezze/larghezze di
   struttura (`--h-*`, `--w-*`). Restano tutti in `tokens.css`: nessun valore nei componenti.
7. **Codice penale unificato con le multe** (§7 del piano): le 52 `fine_types` sono state tradotte in
   italiano e riversate come articoli con id 101–152, più i 7 originali con id 1–7. Totale 59 su
   4 categorie. `fine_types` resta in database, non più letta da KF_Police.
8. **Soglia di collasso del controllo segmentato misurata sul contenitore** (54 rem
   sull'intestazione) e non sulla finestra: la sidebar espansa o compressa cambia lo spazio
   disponibile a parità di larghezza del tablet, quindi la finestra non è il riferimento giusto.
9. **Sequestro item durante la perquisizione** (`KF_Police:actions:seize`): sostituisce
   `esx_policejob:confiscatePlayerItem`, aggiungendo i controlli di distanza e permesso che
   l'originale non faceva. Serve a non perdere funzionalità in F8.

---

## 4. Schema del database creato

17 tabelle: `kf_police_schema_version`, `kf_police_profiles`, `kf_police_penalcode_categories`,
`kf_police_penalcode`, `kf_police_charges`, `kf_police_notes`, `kf_police_reports`,
`kf_police_report_involved`, `kf_police_report_vehicles`, `kf_police_tags`,
`kf_police_report_tags`, `kf_police_vehicle_flags`, `kf_police_jail`, `kf_police_armory_stock`,
`kf_police_duty_log`, `kf_police_audit`, `kf_police_orphan_records`.

`kf_police_citizens` resta in sola lettura per due release (§5.2 punto 7 del piano), più
`kf_police_citizens_backup_20260819` creata dalla migrazione.

### Verifica eseguita sul database reale

I tre file SQL sono stati eseguiti a mano, in ordine, contro `kfdev_esx`: **nessun errore**.
Risultato: 10 tag senza emoji e con `icon` valorizzato, 59 articoli su 4 categorie
(21 / 11 / 19 / 8), `schema_version = 1`, tabella di backup creata.

Poi `schema_version` è stata svuotata, il backup rimosso e sono stati inseriti i dati legacy di prova
(vedi §4 dell'handoff), così la **migrazione Lua** gira davvero al primo avvio del server e i suoi
criteri di accettazione sono verificabili.

---

## 5. Font

Scaricati da Google Fonts e messi **dentro la risorsa**, come prescrive §3.1 (la NUI non ha accesso
di rete garantito):

| File | Byte |
|---|---|
| `inter-latin.woff2` | 48 256 |
| `inter-latin-ext.woff2` | 85 068 |
| `jetbrains-mono-latin.woff2` | 31 432 |
| `jetbrains-mono-latin-ext.woff2` | 11 624 |

Sono font **variabili**: un file copre tutti i pesi. `font-display: block`, non `swap`.
Dichiarati in `web/src/styles/fonts.css` e aggiunti ai `files` di `fxmanifest.lua`.

**Verificato con `npm run build`**: Vite li copia in `web/build/assets/` con l'hash
(`inter-latin-Dx4kXJAl.woff2` e simili). È l'esito desiderato, e `web/build/assets/**/*` è già
dichiarato nel manifest. La voce `web/assets/fonts/*.woff2` resta come ripiego documentato dal piano.

---

## 6. Ordine di caricamento in `fxmanifest.lua`

Esplicito, **senza glob**, perché l'ordine conta: configurazione → utilità → permessi → locali →
contratto bridge; poi lato server logger → permessi → migrazioni → database → `sv_main` (che registra
il dispatcher) → moduli di dominio.

Un glob avrebbe reso l'ordine dipendente dal filesystem.

---

## 7. Script di controllo sintassi Lua

Non esiste un interprete Lua sulla macchina. Il controllo si fa con `luaparse` via Node:

```bash
cd "$TEMP" && mkdir -p luacheck && cd luacheck && npm install luaparse
```

`$TEMP/luacheck/check.mjs`:

```js
import luaparse from 'luaparse';
import { readFileSync, readdirSync, statSync } from 'fs';
import { join } from 'path';

const root = process.argv[2];
const files = [];
function walk(dir) {
  for (const name of readdirSync(dir)) {
    if (name === 'node_modules' || name === '.git' || name === 'web' || name === '.claude') continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p);
    else if (name.endsWith('.lua')) files.push(p);
  }
}
walk(root);

let bad = 0;
for (const f of files.sort()) {
  try {
    luaparse.parse(readFileSync(f, 'utf8'), { luaVersion: '5.3', comments: false });
  } catch (e) {
    bad++;
    console.log(`FAIL ${f.replace(root, '')}: ${e.message}`);
  }
}
console.log(`\n${files.length} file controllati, ${bad} con errori di sintassi`);
```

Uso:

```bash
node "$TEMP/luacheck/check.mjs" "D:/Server/FiveM/KFTest/resources/[kfdev]/KF_Police"
```

Ultimo esito: **59 file, 0 errori**.

---

## 8. Cosa non è ancora stato provato in gioco

Niente è stato collaudato con il server FiveM avviato. Le verifiche fatte sono: sintassi Lua,
compilazione TypeScript, esecuzione dei tre file SQL contro il database reale.

Da collaudare, nell'ordine dei criteri di accettazione del piano:

- **F1**: la migrazione gira e i 4 reati orfani finiscono in `kf_police_orphan_records`; la radio
  cambia canale davvero.
- **F5**: nessun evento accetta un bersaglio non validato; il sequestro sopravvive al restart; un
  `recruit` non può sequestrare.
- **F6**: il ciclo servizio → divisa → arma → veicolo → fine servizio funziona **senza
  `esx_policejob` avviato**.
- **F7**: un detenuto che si disconnette e rientra ha il tempo residuo corretto; il rilascio
  automatico funziona anche se l'agente che ha arrestato è offline.

# Architettura trasversale

Quello che non sta in un singolo file: come si parlano NUI, client e server, come si
validano i permessi, come si avvia il database, come si aggiornano le viste.

---

## 1. Contratto NUI: un solo canale

La UI **non chiama endpoint diversi**. Chiama sempre:

```ts
callMdt(endpoint, payload)   // web/src/lib/nui.ts
```

che posta su `RegisterNUICallback('mdt')` in `client/cl_nui.lua`. Il client:

- se l'endpoint è registrato **in locale** (`RegisterLocalMdtEndpoint`) lo esegue lì;
- altrimenti lo inoltra a `lib.callback` **`KF_Police:mdt`** in `server/sv_main.lua`.

`KF_Police:mdt` è l'**unico punto** dove passa la validazione, nell'ordine:

1. l'endpoint esiste;
2. il database è pronto (`Database.IsReady()`);
3. il giocatore esiste;
4. il lavoro è fra `Config.AllowedJobs`;
5. il grado ha il permesso richiesto;
6. il rate limit non è saturo.

Poi il handler gira dentro un `pcall`: un errore diventa `MdtError('invalid_data')` e una
riga di log, non un crash del callback.

### Registrare un endpoint nuovo

Lato server:

```lua
RegisterMdtEndpoint('citizens:search', 'mdt.citizen.view', function(officer, payload, src)
    return MdtOk({ rows = ..., total = ... })   -- oppure MdtError('chiave_locale')
end)
```

Lato client (solo per cose che vivono sul client: pma-voice, coordinate):

```lua
RegisterLocalMdtEndpoint('radio:state', function(payload)
    return { ok = true, radio = GetRadioState() }
end)
```

### Forma delle risposte

- `MdtOk(tabella)` → aggiunge `ok = true` alla tabella e la ritorna.
- `MdtError(chiave, extra)` → `{ ok = false, error = chiave, message = Locale(chiave) }`.

Le liste ritornano sempre `{ rows, total, page, pageSize }` (tipo `Paged<T>` in
`web/src/lib/types.ts`).

**Se cambi la forma di una risposta, aggiorna `web/src/lib/types.ts` nello stesso commit.**

---

## 2. Tabella completa degli endpoint

### Sul server (`RegisterMdtEndpoint`, permesso richiesto)

| Endpoint | Permesso | File |
|---|---|---|
| `bootstrap` | `mdt.view` | `server/sv_main.lua` |
| `citizens:search` | `mdt.citizen.view` | `server/sv_citizens.lua` |
| `citizens:get` | `mdt.citizen.view` | `server/sv_citizens.lua` |
| `citizens:setMugshot` | `mdt.note.create` | `server/sv_citizens.lua` |
| `charges:add` | `mdt.charge.add` | `server/sv_charges.lua` |
| `charges:void` | `mdt.charge.void` | `server/sv_charges.lua` |
| `charges:markPaid` | `mdt.fine.issue` | `server/sv_charges.lua` |
| `notes:add` | `mdt.note.create` | `server/sv_notes.lua` |
| `notes:update` | `mdt.note.create` | `server/sv_notes.lua` |
| `notes:delete` | `mdt.note.delete` | `server/sv_notes.lua` |
| `wanted:list` | `mdt.citizen.view` | `server/sv_wanted.lua` |
| `wanted:set` | `mdt.wanted.set` | `server/sv_wanted.lua` |
| `reports:list` | `mdt.view` | `server/sv_reports.lua` |
| `reports:get` | `mdt.view` | `server/sv_reports.lua` |
| `reports:save` | `mdt.report.create` | `server/sv_reports.lua` |
| `reports:delete` | `mdt.report.delete` | `server/sv_reports.lua` |
| `tags:list` | `mdt.view` | `server/sv_reports.lua` |
| `tags:save` | `mdt.tag.edit` | `server/sv_reports.lua` |
| `tags:delete` | `mdt.tag.edit` | `server/sv_reports.lua` |
| `vehicles:search` | `mdt.vehicle.view` | `server/sv_vehicles.lua` |
| `vehicles:get` | `mdt.vehicle.view` | `server/sv_vehicles.lua` |
| `vehicles:setFlag` | `mdt.vehicle.flag` | `server/sv_vehicles.lua` |
| `vehicles:impounded` | `mdt.vehicle.view` | `server/sv_vehicles.lua` |
| `penalcode:list` | `mdt.view` | `server/sv_penalcode.lua` |
| `penalcode:save` | `mdt.penalcode.edit` | `server/sv_penalcode.lua` |
| `penalcode:delete` | `mdt.penalcode.edit` | `server/sv_penalcode.lua` |
| `penalcode:saveCategory` | `mdt.penalcode.edit` | `server/sv_penalcode.lua` |
| `duty:toggle` | `duty.toggle` | `server/sv_duty.lua` |
| `duty:state` | `mdt.view` | `server/sv_duty.lua` |
| `duty:roster` | `mdt.view` | `server/sv_duty.lua` |
| `jail:list` | `mdt.jail.view` | `server/sv_jail.lua` |
| `jail:send` | `jail.send` | `server/sv_jail.lua` |
| `jail:release` | `jail.release` | `server/sv_jail.lua` |
| `fines:issue` | `mdt.fine.issue` | `server/sv_fines.lua` |
| `fines:list` | `mdt.view` | `server/sv_fines.lua` |

### Sul client (`RegisterLocalMdtEndpoint`, nessun giro sul server)

| Endpoint | File | Perché è locale |
|---|---|---|
| `client:context` | `client/cl_nui.lua` | posizione e ora sono native del client |
| `client:nearby` | `client/cl_nui.lua` | il giocatore vicino lo sa solo il client |
| `radio:state` | `client/cl_radio.lua` | pma-voice gira sul client |
| `radio:join` | `client/cl_radio.lua` | idem |
| `radio:leave` | `client/cl_radio.lua` | idem |
| `radio:volume` | `client/cl_radio.lua` | idem |

### `lib.callback` diretti (non passano dal dispatcher MDT)

Le azioni di gioco non usano il canale MDT: hanno bisogno di argomenti posizionali e di
validare la distanza. Ognuno rivalida il permesso con `RequirePermission`.

| Callback | Permesso | File |
|---|---|---|
| `KF_Police:actions:cuff` | `field.cuff` | `server/sv_actions.lua` |
| `KF_Police:actions:drag` | `field.cuff` | `server/sv_actions.lua` |
| `KF_Police:actions:vehicle` | `field.cuff` | `server/sv_actions.lua` |
| `KF_Police:actions:search` | `field.search` | `server/sv_actions.lua` |
| `KF_Police:actions:seize` | `field.search` | `server/sv_actions.lua` |
| `KF_Police:actions:identify` | `field.identify` | `server/sv_actions.lua` |
| `KF_Police:actions:licenses` | `field.license` | `server/sv_actions.lua` |
| `KF_Police:actions:revokeLicense` | `field.license` | `server/sv_actions.lua` |
| `KF_Police:actions:lockpick` | `field.lockpick` | `server/sv_actions.lua` |
| `KF_Police:actions:impound` | `field.impound` | `server/sv_actions.lua` |
| `KF_Police:actions:markStolen` | `mdt.vehicle.flag` | `server/sv_actions.lua` |
| `KF_Police:actions:plateCheck` | `mdt.vehicle.view` | `server/sv_actions.lua` |
| `KF_Police:actions:jail` | `jail.send` | `server/sv_actions.lua` |
| `KF_Police:actions:pendingSentence` | `jail.send` | `server/sv_actions.lua` |
| `KF_Police:armory:catalog` | `armory.use` | `server/sv_armory.lua` |
| `KF_Police:armory:take` | `armory.use` | `server/sv_armory.lua` |
| `KF_Police:armory:store` | `armory.use` | `server/sv_armory.lua` |
| `KF_Police:armory:buy` | `armory.buy` | `server/sv_armory.lua` |
| `KF_Police:garage:catalog` | `garage.use` | `server/sv_garage.lua` |
| `KF_Police:garage:spawn` | `garage.use` | `server/sv_garage.lua` |
| `KF_Police:garage:store` | `garage.use` | `server/sv_garage.lua` |
| `KF_Police:duty:colleagues` | `mdt.view` | `server/sv_duty.lua` |

---

## 3. Messaggi NUI: dal Lua verso la UI

`SendNUIMessage({ action, data })`, ascoltati con `useNuiEvent(action, handler)`.

| `action` | Chi lo manda | Chi lo ascolta | Contenuto |
|---|---|---|---|
| `mdt:visible` | `cl_nui.lua` | `pages/App.tsx` | `{ visible }`; se falso App non rende nulla |
| `mdt:geometry` | `cl_nui.lua` | `MdtProvider` | larghezza, altezza, `rootFontSize` |
| `mdt:bootstrap` | `cl_nui.lua` (risposta di `bootstrap`) | `MdtProvider` | agente, permessi, pagine, contatori |
| `mdt:status` | `cl_nui.lua` (ogni 5 s) | `MdtProvider` | strada, ora, in veicolo |
| `mdt:counters` | `sv_main.PushCounters` → client | `MdtProvider` | badge della sidebar |
| `mdt:invalidate` | `sv_main.Invalidate` → client | `MdtProvider` | `{ scope, id }` |
| `mdt:duty` | `cl_nui.lua` su `DutyChanged` | `MdtProvider` | `{ onDuty }` |
| `mdt:radio` | `cl_radio.PushRadioStateToNui` | `MdtProvider` | stato radio completo |
| `mdt:notify` | `cl_notify.lua` | `MdtProvider` → `ToastStack` | messaggio e tono |
| `mdt:open` | `cl_nui.OpenMdtOnCitizen/Vehicle` | `MdtProvider` | apre una linguetta su una scheda |

---

## 4. Permessi

`shared/sh_permissions.lua` è **caricato sia sul client sia sul server**:

- il **client** lo usa per non mostrare voci di menu inutili;
- il **server** lo usa per rifiutare. Il controllo autorevole è solo quello del server.

Sintassi: `'@N'` in una lista eredita tutti i permessi del grado N dello stesso lavoro.
`ResolvePermissions` ha una cache per `job:grade` e una protezione contro le
ereditarietà circolari.

### Gradi `police` (da `job_grades`)

| Grado | Nome | Permessi aggiunti a quelli del grado precedente |
|---|---|---|
| 0 | `recruit` | consultazione MDT, rapporti, note, servizio, spogliatoio, armeria, garage, radio, `field.identify`, `objects.place` |
| 1 | `officer` | `mdt.charge.add`, `mdt.vehicle.flag`, `field.cuff`, `field.search`, `field.lockpick`, `jail.send` |
| 2 | `sergeant` | `mdt.wanted.set`, `mdt.note.delete`, `field.impound`, `field.fine`, `field.license`, `mdt.fine.issue` |
| 3 | `lieutenant` | `mdt.charge.void`, `mdt.report.delete`, `jail.release`, `mdt.roster.view` |
| 4 | `boss` (Captain) | `mdt.penalcode.edit`, `mdt.tag.edit`, `mdt.audit.view`, `armory.buy`, `society.boss` |

`ambulance` 0-4 consulta il MDT ma non opera sui fascicoli.

`Config.WritePermissions` marca quali permessi sono scritture: serve al rate limiter
(`MaxWrites` separato da `MaxCalls`) e all'audit.

### Controlli di visibilità oltre al grado

Alcune regole non sono esprimibili come permesso e stanno nel modulo:

- **Rapporti riservati**: li vede solo l'autore o chi ha `mdt.report.delete`
  (`sv_reports.lua`).
- **Modifica di un rapporto di altri**: richiede `mdt.report.edit`.
- **Modifica di una nota di altri**: richiede `mdt.note.delete`.

---

## 5. Sequenza di avvio del database

`server/sv_database.lua` esegue in quest'ordine, e **l'ordine conta**:

1. **`sql/install.sql`** — solo `CREATE TABLE IF NOT EXISTS`.
2. **`Migrations.Run()`** — aggiunge le colonne mancanti alle tabelle preesistenti,
   ripulisce le emoji dai tag, esplode i blob JSON di `kf_police_citizens`, salva gli
   orfani, crea lo stock iniziale dell'armeria, segna `kf_police_schema_version`.
3. **`sql/seed.sql`** — dati iniziali.

I seed sono in un file separato **perché su un database esistente usano colonne (`icon`,
`category_id`, `jail_months`) che le aggiunge il passo 2**. Invertendo l'ordine si prende
`ERROR 1054 Unknown column 'icon'`: è già successo, è la ragione della separazione.

Dopo il passo 3 `Database.IsReady()` diventa vero e i callback MDT cominciano a
rispondere. Prima ritornano `mdt_not_ready`.

---

## 6. Invalidazioni: come si aggiornano le viste

Il vecchio codice caricava tutti gli utenti e tutti i veicoli in RAM e li ribroadcastava
a `-1` a ogni modifica (bug L4). Ora:

1. una scrittura chiama `Invalidate(scope, id)` in `server/sv_main.lua`;
2. il server manda `KF_Police:Client:Invalidate` a tutti i client;
3. `client/cl_nui.lua` inoltra `mdt:invalidate` alla NUI **solo se il tablet è aperto**;
4. `MdtProvider` incrementa `revision[scope]`;
5. ogni pagina osserva i propri scope con `useRevisionEffect` e ricarica **solo la
   propria vista**.

Scope disponibili: `citizen`, `citizens`, `reports`, `wanted`, `vehicles`, `jail`,
`penalcode`, `roster`.

Chi osserva cosa, oggi:

| Pagina | Scope osservati |
|---|---|
| `CitizensPage` | `citizen`, `wanted`, `jail` |
| `CitizenSheet` | `citizen`, `jail`, `wanted` |
| `VehiclesPage` | `vehicles` |
| `VehicleSheet` | `vehicles` |
| `ReportsPage` | `reports` |

`PushCounters()` è separato: manda solo i quattro numeri dei badge della sidebar.

---

## 7. Eventi di rete

### Server → client

| Evento | Uso |
|---|---|
| `KF_Police:Client:Notify` | notifica generica |
| `KF_Police:Client:OpenMDT` | apre il tablet (item usabile) |
| `KF_Police:Client:Invalidate` | vista da ricaricare |
| `KF_Police:Client:Counters` | badge sidebar |
| `KF_Police:Client:DutyChanged` | stato servizio cambiato |
| `KF_Police:Client:LeaveRadio` | uscita forzata dal canale |
| `KF_Police:Client:DespawnServiceVehicle` | rimozione veicolo di servizio |
| `KF_Police:Client:SetRestrained` | manette applicate o rimosse |
| `KF_Police:Client:SetDragged` | scorta iniziata o finita |
| `KF_Police:Client:PutInVehicle` / `OutOfVehicle` | carico/scarico dal veicolo |
| `KF_Police:Client:Jailed` / `JailTick` / `Released` | carcere |
| `KF_Police:Client:Alert` | allerta con blip temporaneo |

### Client → server

| Evento | Uso |
|---|---|
| `KF_Police:Server:CuffExpired` | scadenza automatica delle manette |
| `KF_Police:Server:DespawnServiceVehicle` | il client conferma la rimozione |

### Ascoltati da altre risorse

| Evento | Uso |
|---|---|
| `KF_Police:Server:Alert` | allerta polizia da telefono, negozi, rapine |
| `esx_phone:registerNumber` | registra il contatto `police` (emesso all'avvio) |
| `esx_society:registerSociety` | registra la società LSPD (emesso all'avvio) |

Questi ultimi due vanno **mantenuti anche dopo la dismissione di `esx_policejob`**,
altrimenti il telefono perde il contatto di allerta e la società perde il conto.

---

## 8. Schema del database

17 tabelle, tutte con prefisso `kf_police_`. Chiave di riferimento: **`identifier`**
(stabile), con `ssn` come colonna indicizzata di comodo (correzione bug L5).

| Tabella | Contenuto |
|---|---|
| `kf_police_schema_version` | versioni di migrazione applicate |
| `kf_police_profiles` | foto segnaletica e stato ricercato, chiave `identifier` |
| `kf_police_penalcode_categories` | 4 categorie del codice penale |
| `kf_police_penalcode` | 59 articoli con `fine` e `jail_months` numerici |
| `kf_police_charges` | un reato = una riga, con annullamento tracciato |
| `kf_police_notes` | note di servizio, id da AUTO_INCREMENT |
| `kf_police_reports` | testata dei rapporti |
| `kf_police_report_involved` | giunzione rapporto ↔ cittadino con ruolo |
| `kf_police_report_vehicles` | giunzione rapporto ↔ targa |
| `kf_police_tags` | tag con `icon` FontAwesome e `color` |
| `kf_police_report_tags` | giunzione rapporto ↔ tag |
| `kf_police_vehicle_flags` | rubato / sequestrato / BOLO, persistenti |
| `kf_police_jail` | tempo residuo in secondi, persistente |
| `kf_police_armory_stock` | scorte armeria |
| `kf_police_duty_log` | entrate e uscite dal servizio, per il monte ore |
| `kf_police_audit` | tracciabilità delle scritture |
| `kf_police_orphan_records` | righe legacy il cui SSN non esiste più |

Tabelle **lette ma non possedute** da questa risorsa: `users`, `jobs`, `job_grades`,
`owned_vehicles`, `user_licenses`, `licenses`, `coin_system_items` (proprietà).

`kf_police_citizens` (vecchio schema monolitico) resta in sola lettura per due release,
più `kf_police_citizens_backup_20260819` creata dalla migrazione.

---

## 9. Scala dinamica del tablet

Il tablet non ha dimensione assoluta in pixel, e da F2b ha una **cornice fisica**
(`web/assets/tablet.png`) intorno alla schermata:

1. `client/cl_nui.lua` → `ComputeTabletGeometry()` calcola due rettangoli concentrici come
   frazione della risoluzione reale: la **cornice** (`frameWidth`/`frameHeight`, l'ingombro
   che deve entrare nello schermo, `Config.UI.heightRatio`) e la **schermata**
   (`width`/`height`, la finestra utile, che mantiene il rapporto di progetto 1280 × 910).
   Da quest'ultima ricava `rootFontSize`;
2. la geometria arriva alla NUI come `mdt:geometry`, con `frameInset` = posizione della
   finestra trasparente in frazioni della cornice;
3. `DeviceFrame` dimensiona in pixel **solo il riquadro esterno**, unico posto del
   progetto dove si scrive un pixel, e posiziona la schermata con le percentuali di
   `frameInset`. L'immagine è stirata sul riquadro esterno, quindi il ritaglio combacia
   con la schermata per costruzione;
4. `useTabletScale` scrive `rootFontSize` sul `font-size` della radice;
5. **tutti** i componenti misurano in `rem`, quindi scalano da soli.

Conseguenza operativa: in un componente **non si scrive mai un pixel**. A 1080p, 1440p e
4K il testo ha la stessa dimensione apparente.

Due conseguenze meno ovvie:

- `heightRatio` misura la **cornice**, non la schermata. La scocca è alta 1.208 volte il
  ritaglio, quindi la schermata utile è sempre più piccola della frazione dichiarata: per
  questo `heightRatio` è passato da 0.86 a 0.96 quando è stata introdotta la cornice.
- Il rapporto del ritaglio (1.441) non è quello di progetto (1.407): la cornice prende un
  2.4% di stiramento verticale. Si deforma la scocca, non la UI.

Con `Config.UI.frame.enabled = false` i due rettangoli coincidono e il comportamento è
quello di prima della cornice.

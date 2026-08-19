# HANDOFF — Rework MDT KF_Police

> **Documento di ripresa lavoro.** Scritto per essere letto da zero, senza il contesto della
> conversazione in cui il lavoro è stato svolto.
> **Data**: 2026-08-19 · **Branch**: `feature/mdt-rework` · **Piano di riferimento**:
> `.claude/plans/2026-08-19-kf-police-mdt-rework.md`

---

## 1. Cosa leggere, in quest'ordine

1. **Questo file** (§2 → §9): stato, prima azione, cosa resta.
2. `.claude/progress/2026-08-19-stato-implementazione.md`: inventario file per file, decisioni prese
   oltre al piano, scoperte sull'ambiente reale.
3. `.claude/plans/2026-08-19-kf-police-mdt-rework.md`: il piano approvato. **Le §1 e §3 sono chiuse:
   non rimetterle in discussione.**
4. `.claude/plans/assets/mockup-casefile-v4.html`: aprire nel browser. È la specifica visiva
   vincolante a 1280 × 910 con base 16 px.

---

## 2. Prima azione da compiere

**Il lavoro non è committato.** Tutto vive come modifiche non committate sul branch
`feature/mdt-rework`. Il piano prescrive «una fase = un commit funzionante» (§8), quindi la prima cosa
da fare è consolidare quanto esiste in due commit:

```bash
cd "D:/Server/FiveM/KFTest/resources/[kfdev]/KF_Police"
git branch --show-current      # deve rispondere feature/mdt-rework

# Commit F0 + F1 (backend Lua completo, migrazione, permessi)
git add .gitignore fxmanifest.lua config/ modules/ shared/ server/ client/ sql/
git add -u   # raccoglie le cancellazioni di config.lua, kf_police.sql, sv_functions.lua, ...
git commit   # messaggio suggerito in §8 di questo documento

# Commit F2 parziale (fondazioni design system)
git add web/
git commit
```

Verificare prima che i due controlli automatici passino (§7).

---

## 3. Stato in una riga

| Fase | Titolo | Stato |
|---|---|---|
| F0 | Preparazione | **Completata** |
| F1 | Fondazioni Lua | **Completata** (da collaudare in gioco) |
| F2 | Design system UI | **~60%** — token, primitive e telaio fatti; **pagine e App.tsx no** |
| F3 | MDT dati reali | **Backend completo**, frontend da fare (dipende da F2) |
| F4 | Radio nel tablet | **Backend + RadioDock fatti**, pagina Radio da fare |
| F5 | Azioni di campo | **Completata lato Lua** (da collaudare in gioco) |
| F6 | Strutture stazione | **Completata lato Lua** (da collaudare in gioco) |
| F7 | Carcere | **Completata lato Lua** (da collaudare in gioco) |
| F8 | Dismissione esx_policejob | **Non iniziata** |
| F9 | Hardening e collaudo | **Parziale** (rate limit e validazioni già scritti) |

> **Attenzione, punto più importante di tutto il documento:** la UI **attualmente in build è ancora
> quella vecchia**. `web/src/main.tsx` punta a `web/src/pages/App.tsx`, che è il file originale con
> tutti i bug U1–U13. I nuovi componenti esistono ma **non sono ancora collegati a nulla**.
> Il primo lavoro utile su F2 è riscrivere `App.tsx` + `main.tsx` (§5.1).

---

## 4. Ambiente: quello che il piano dice e quello che è vero

Il piano è stato scritto qualche tempo prima; il database è cambiato. Fatti **verificati** oggi:

| Voce | Valore reale |
|---|---|
| Database | **`kfdev_esx`** (il piano cita `kftest_esx` in §0 e `testserver` in §8: entrambi errati) |
| Connessione | `mysql://root:NegroPene123@localhost/kfdev_esx` da `KFTest/server.cfg` |
| Client MySQL | **Nessun binario locale.** MariaDB gira in Docker, container di nome `MariaDB` |
| Query | `docker exec MariaDB mariadb -uroot -pNegroPene123 kfdev_esx -e "..."` |
| Import file | `docker exec -i MariaDB mariadb -uroot -pNegroPene123 kfdev_esx < file.sql` |
| `web/node_modules` | **NON era installato** nonostante il piano lo dia per fatto. Ora sì (401 pacchetti) |
| Interprete Lua | **Assente.** Per il controllo sintassi si usa `luaparse` via Node (§7) |
| Utenti in DB | 3 (non 5): `char1/2/3:624634ad...`, job `banker` e `unemployed` |
| `owned_vehicles` | 16 righe (il piano diceva 0) |
| `fine_types` | 52 righe, in inglese → tradotte e riversate nel codice penale come articoli |
| Record orfano `677-15-0384` | **Non esisteva più**: `kf_police_citizens` era vuota |
| Gradi `police` | `recruit`(0) `officer`(1) `sergeant`(2) `lieutenant`(3) `boss`(4) = *Captain* — confermato |
| `users` | ha `ssn`, `nationality` (default `Los Santos`), `phone_number`, `dateofbirth`, `sex`, `height` |

### Dato di prova inserito a mano

Poiché i 4 reati orfani citati nel criterio di accettazione F1 non esistevano più, **sono stati
ricreati sinteticamente** in `kf_police_citizens` per poter collaudare la migrazione:

- `515-87-4812` → SSN reale di un utente, 2 reati + 1 nota + stato ricercato → deve finire in
  `kf_police_profiles` / `kf_police_charges` / `kf_police_notes`;
- `677-15-0384` → SSN inesistente, **4 reati** → deve finire in `kf_police_orphan_records`.

`kf_police_schema_version` è stata svuotata e la tabella di backup rimossa, così la migrazione Lua
gira davvero al primo avvio del server. **Non svuotare quelle tabelle prima del collaudo F1.**

---

## 5. Cosa resta da fare, in ordine di esecuzione

### 5.1 F2 — completare il design system (priorità massima)

Restano i punti 6–8 dell'ordine consigliato in §F2 del piano.

**a) Nuovo punto d'ingresso** — sostituisce la UI vecchia:

- riscrivere `web/src/main.tsx`: monta `MdtProvider` + `App`, elimina `VisibilityProvider`;
- riscrivere `web/src/pages/App.tsx`: `DeviceFrame` → `StatusBar` → `main` (`Sidebar` + colonna
  `TabStrip` / `Sheet` / `RadioDock`), e smista la linguetta attiva sul componente di pagina;
- la mappa `pageKey → componente` va in `App.tsx`, **non** in `pages/registry.ts` (quel file resta di
  soli metadati per non creare cicli di import con `MdtProvider`);
- gestire la visibilità: `useNuiEvent('mdt:visible')` → se `visible === false` non rendere nulla;
  ESC deve chiamare `closeMdt()`.

**b) Pagine da scrivere** in `web/src/pages/` (nessuna esiste ancora nella forma nuova):

| File | Endpoint usati | Note |
|---|---|---|
| `CitizensPage.tsx` | `citizens:search` | È **la schermata del mockup**: replicarla esattamente. Filtro Tutti/Ricercati/Detenuti, colonne avatar `2.75rem` fisso · nome `1.15` · cognome `1.4` · cittadinanza `1` · impiego `1.3` · azioni `3.5rem` fisso |
| `CitizenSheet.tsx` | `citizens:get`, `charges:add`, `charges:void`, `notes:*`, `wanted:set`, `fines:issue`, `jail:send` | Aggiunta reati **multipla** in una sola chiamata (`penalcodeIds[]`) |
| `VehiclesPage.tsx` | `vehicles:search` | Filtri: tutti / rubati / sequestrati / BOLO |
| `VehicleSheet.tsx` | `vehicles:get`, `vehicles:setFlag` | |
| `ReportsPage.tsx` | `reports:list` | Filtro per `status` |
| `ReportSheet.tsx` | `reports:get`, `reports:save`, `reports:delete`, `tags:list` | Coinvolti con ruolo (`suspect`/`victim`/`witness`), veicoli, tag |
| `PenalCodePage.tsx` | `penalcode:list`, `penalcode:save`, `penalcode:delete` | Raggruppata per categoria |
| `WantedPage.tsx` | `wanted:list`, `wanted:set` | |
| `JailPage.tsx` | `jail:list`, `jail:release` | |
| `RadioPage.tsx` | `radio:state`, `radio:join`, `radio:leave`, `radio:volume` | Completa F4 |
| `DutyPage.tsx` | `duty:roster`, `duty:toggle` | **È la `AgentManagement` del bug U9**: roster, gradi, stato servizio, monte ore |

Gli attrezzi ci sono già tutti: `usePagedQuery`, `DataTable` + `OpenCell`, `Sheet` + `SheetHeader` +
`SheetBody` + `Panel` + `DataRow`, `Modal`, `ConfirmDialog`, `Button`, `IconButton`, i campi di
`Field.tsx`, `Chip`, `Stamp`, `Avatar`, `EmptyState`, `SkeletonRows`, `Pagination`,
`SegmentedControl`, `Icon`.

**c) Cancellazioni** — solo dopo che le pagine nuove funzionano:

```
web/src/pages/App.css                (bug U5, U6 — sostituito dai token)
web/src/pages/components/*           (tutti: Background e Badge sono i bug U3/U4, Dialog è U7)
web/src/pages/sections/*             (tutti)
web/src/providers/VisibilityProvider.tsx
web/src/utils/debugData.ts, debugDataList.ts, fetchNui.ts, utils.ts, translator.ts, FiveM.js
```

`web/src/utils/misc.ts` va controllato: se resta usato solo da file cancellati, va via anche lui.

**d) Ricollegare le invalidazioni**: ogni pagina deve rileggere `revision[scope]` dal contesto e
ricaricare **solo** la propria vista quando cambia (sostituisce il broadcast totale, bug L4).

### 5.2 F3 — completare lato UI

Il backend è già pronto. Resta da esercitare dalla UI: reati multipli, annullamento tracciato,
`DutyPage`, e la foto segnaletica con ripiego locale (`Avatar` lo fa già: `web/assets/guest.png`,
mai `via.placeholder.com`).

### 5.3 F8 — dismissione `esx_policejob`

1. Creare l'item `police_mdt` in `ox_inventory`
   (`[ox]/ox_inventory/data/items.lua`). Oggi esistono `tablet` e `police_cad`, quest'ultimo puntato
   a `origen_police`. `Config.OpenItemAliases` accetta già `mdt` e `tablet` come ripiego.
2. Grep su **tutte** le risorse per `esx_policejob:` prima di spegnerlo, e registrare alias di
   compatibilità dove serve.
3. Spostare `[esx_addons]/esx_policejob` in `[disabled]` e togliere `ensure` da `server.cfg`.
4. Scrivere il `README.md` della risorsa (installazione, config, permessi, migrazione).

### 5.4 F9 — collaudo

- Avviare il server e verificare i criteri di accettazione di ogni fase (§8 del piano).
- Leggibilità a 1920×1080, 2560×1440, 3840×2160: dimensione apparente identica.
- I due grep di controllo di §7 devono restare vuoti.

---

## 6. Come è fatto quello che c'è già

### Contratto NUI: un solo canale

La UI non chiama endpoint diversi: chiama sempre `callMdt(endpoint, payload)` (in
`web/src/lib/nui.ts`), che posta su `RegisterNUICallback('mdt')` in `client/cl_nui.lua`. Il client
inoltra a `lib.callback` `KF_Police:mdt` in `server/sv_main.lua`, **unico punto** dove passa la
validazione: giocatore esiste → lavoro autorizzato → grado ha il permesso → rate limit non saturo
(`server/sv_permissions.lua`).

Registrare un endpoint nuovo lato server:

```lua
RegisterMdtEndpoint('citizens:search', 'mdt.citizen.view', function(officer, payload, src)
    return MdtOk({ rows = ..., total = ... })   -- oppure MdtError('chiave_locale')
end)
```

Gli endpoint `radio:*` e `client:*` sono gestiti **in locale sul client**
(`RegisterLocalMdtEndpoint`), perché pma-voice e le coordinate vivono lì: non fanno un giro sul
server.

### Sequenza di avvio del database

`server/sv_database.lua` esegue in quest'ordine, e **l'ordine conta**:

1. `sql/install.sql` — solo `CREATE TABLE IF NOT EXISTS`;
2. `Migrations.Run()` — aggiunge le colonne mancanti alle tabelle preesistenti, ripulisce le emoji
   dai tag, esplode i blob JSON, salva gli orfani, segna `kf_police_schema_version`;
3. `sql/seed.sql` — dati iniziali.

I seed sono in un file separato **perché su un database esistente usano colonne (`icon`,
`category_id`, `jail_months`) che le aggiunge il passo 2**. Invertendo l'ordine si prende
`ERROR 1054 Unknown column 'icon'`: è già successo, è la ragione della separazione.

### Permessi

`shared/sh_permissions.lua` è caricato sia client sia server. Il client lo usa per non mostrare voci
inutili, il server per rifiutare. `'@N'` eredita dal grado N. `ResolvePermissions` ha una cache e una
protezione contro le ereditarietà circolari.

---

## 7. Verifiche da rieseguire dopo ogni modifica

```bash
# 1. TypeScript: deve dire 0 errori
cd "D:/Server/FiveM/KFTest/resources/[kfdev]/KF_Police/web" && npx tsc --noEmit

# 2. Build della UI
npm run build

# 3. Sintassi Lua (nessun interprete installato: si usa luaparse via Node)
cd "$TEMP" && mkdir -p luacheck && cd luacheck && npm install luaparse
# poi lo script check.mjs descritto in .claude/progress/2026-08-19-stato-implementazione.md §7

# 4. Nessun valore hardcoded nei componenti (checklist §3.9 del piano)
cd "D:/Server/FiveM/KFTest/resources/[kfdev]/KF_Police"
grep -rE "text-\[|w-\[|h-\[|#[0-9a-fA-F]{6}" web/src/components web/src/pages
# Nota: oggi questo grep NON è vuoto, perché web/src/pages contiene ancora i file
# vecchi. Deve diventare vuoto quando le pagine nuove li sostituiscono (§5.1c).
# I pochi valori arbitrari nei componenti nuovi sono misure prese dal mockup
# (0.45rem, 1.75rem, 0.18rem...) e sono in rem, non in px: sono ammessi.

# 5. Nessuna emoji
grep -rP "[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]" web/src shared sql

# 6. Nessun font serif o di sistema
grep -rn "Georgia\|serif\|system-ui" web/src --include="*.css" --include="*.tsx"
```

Stato attuale di queste verifiche:

- **1 → 0 errori.**
- **2 → build riuscita in 5.8 s.** I quattro `.woff2` finiscono in `web/build/assets/` con l'hash,
  come atteso. Avviso di chunk oltre 500 kB: il bundle pesa 1 047 kB perché contiene ancora
  `@uiw/react-md-editor`, usato solo dalle sezioni vecchie. Quando quelle spariscono, la dipendenza
  va rimossa da `package.json` e il bundle cala di circa 700 kB.
- **3 → 59 file, 0 errori.**
- **4 → attesa non vuota** (vedi nota sopra).
- **5 → vuoto.**

---

## 8. Messaggi di commit suggeriti

**Commit F0+F1:**

```
F1: fondazioni Lua, schema normalizzato e permessi per grado

Config splittata in config/, bridge in modules/ (framework, target, inventory,
clothing, voice, notify), schema in sql/install.sql + migrazione idempotente,
permessi per grado applicati da ogni callback.

Corregge L1 (radio: export chiamato col self esplicito), L2 (reati come righe,
non blob JSON riscritto), L3 (flag veicolo persistenti), L4 (query paginate al
posto del broadcast dell'intero database), L5 (chiave su identifier),
L6 (id note da AUTO_INCREMENT), L7 (id ricercati stabili), L8 (tasto su F5),
L9 (errori SQL non piu' inghiottiti), L10 (multa dai campi numerici),
L11 (emoji fuori dai seed), L12 (permessi per grado).
```

**Commit F2 parziale:**

```
F2: token, primitive e telaio del design system Case File v4

Font Inter e JetBrains Mono self-hosted, tokens.css come fonte unica,
tailwind.config.js che legge i token, scala dinamica in rem, componenti di
telaio e di contenuto.

Le pagine e il nuovo App.tsx restano da scrivere: la UI in build e' ancora
quella vecchia.
```

---

## 9. Trappole da non ripetere

1. **Export FiveM**: `exports[res][name](arg)` mangia il primo argomento come `self`. Va sempre
   `exports[res]:name(arg)` oppure `handle[name](handle, arg)`. È il bug L1 e ricompare facilmente.
2. **Tailwind**: `"bg-" + colore` e `` `w-[${x}px]` `` non generano nessuna classe (bug U3/U4). Mappe
   statiche complete, oppure `style={{ }}` per i valori davvero dinamici (es. il colore di un tag,
   che arriva dal database).
3. **`width` + `flex` sulla stessa cella** si contraddicono (bug U11). In `DataTable` sono mutuamente
   esclusivi per costruzione: usare `width` **oppure** `flex`, mai entrambi.
4. **Listener nel corpo del render** = memory leak (bug U1). Sempre in `useEffect` con cleanup.
5. **Hook condizionali**: mai `while (!context) { context = useContext(...) }` (bug U2). `useMdt()`
   lancia se il provider manca.
6. **Zero emoji** in qualunque file, seed SQL compresi. Solo chiavi del registro `ICONS`.
7. **Solo `rem`**, mai `px`, nei componenti. La radice la imposta `useTabletScale`.
8. **Ordine install → migrate → seed** (§6).
9. **Non fidarsi mai del payload NUI**: ogni endpoint rivalida. Le azioni di campo verificano la
   distanza dal bersaglio con `GetEntityCoords` **sul server**, non con quello che dice il client.

---

## 10. Dubbi aperti da chiarire col committente

1. **Item del tablet**: creare `police_mdt` nuovo o riusare `police_cad` (oggi puntato a
   `origen_police`)? Serve per F8.
2. **Coordinate del carcere**: `config/cfg_jail.lua` usa le celle di Bolingbroke standard. Da
   confermare che corrispondano alla mappa in uso.
3. **Nazionalità**: si usa `users.nationality` come da Appendice A del piano. `Config.DefaultTown` è
   stato rimosso.
4. **Criterio di accettazione F1**: «i 4 reati orfani sono in `kf_police_orphan_records`» si collauda
   sul dato sintetico ricreato (§4), non sul dato originale, che non esiste più nel database.

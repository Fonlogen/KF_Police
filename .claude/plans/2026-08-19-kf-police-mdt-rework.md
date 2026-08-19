# KF_Police — Piano di completamento MDT + assorbimento esx_policejob

> **Stato**: piano approvato per l'esecuzione · **Data**: 2026-08-19 · **Branch di lavoro**: `feature/mdt-rework`
> **Obiettivo finale**: KF_Police diventa la risorsa polizia **unica e standalone** del server, con MDT completo
> e funzionante al 100% e senza dipendere da `esx_policejob`.

---

## 0. Per chi riprende il lavoro da zero

Questo documento è **autosufficiente**: contiene tutto il necessario per eseguire il lavoro senza avere il
contesto della conversazione in cui è stato scritto.

**Ordine di lettura**: §0 → §1 (decisioni già approvate, non rimetterle in discussione) → §2 (cosa è rotto
oggi) → §3 (specifica grafica vincolante) → §4-7 (architettura) → §8 (piano operativo per fasi).

**Prima azione da compiere**: aprire nel browser `.claude/plans/assets/mockup-casefile-v4.html`. È il design
approvato dal committente, a dimensione reale. Tutta la §3 descrive quel file.

### Ambiente (verificato)

| Voce | Valore |
|---|---|
| Percorso risorsa | `C:\Users\Administrator\Desktop\Server\resources\[kfdev]\KF_Police` |
| Risorsa da assorbire | `C:\Users\Administrator\Desktop\Server\resources\[esx_addons]\esx_policejob` |
| Framework | ESX **1.14.0** (`[core]/es_extended`) |
| Database | MySQL `testserver` · client in `C:\xampp\mysql\bin\mysql.exe` (utente `root`, senza password) |
| Librerie disponibili | `ox_lib`, `ox_target`, `ox_inventory` 2.44.1, `oxmysql`, `pma-voice`, `esx_billing`, `esx_society`, `fivem-appearance`, `skinchanger` |
| Toolchain UI | React 18 + TypeScript + Vite 5 + Tailwind 3 in `web/` (`node_modules` già installati) |
| Build UI | `cd web && npm run build` (esegue `tsc && vite build` → `web/build/`) |
| Sviluppo UI in browser | `cd web && npm run dev` (i dati finti sono in `web/src/utils/debugDataList.ts`) |
| Lingua | Italiano: interfaccia, commenti, locali. `Config.Locale = 'it'` |

### Regole non negoziabili

1. **Zero emoji** in qualunque file: codice, locali, seed SQL, commenti. Solo icone FontAwesome (§3.8).
2. **Nessun valore hardcoded** nei componenti React: colori, raggi e dimensioni vengono dai token (§3.4).
3. **Tutto in `rem`**, mai in `px`, così la scala funziona a ogni risoluzione (§3.2).
4. **Ogni callback server rivalida** giocatore, job e permesso di grado (§4.1). Non fidarsi mai della NUI.
5. **Una fase = un commit funzionante**: il server deve restare avviabile alla fine di ogni fase (§8).
6. Il design è **approvato e chiuso**: implementare la §3, non reinterpretarla.

---

## 1. Decisioni prese

| Ambito | Decisione |
|---|---|
| Scope ESX | **Assorbimento totale** di `esx_policejob`; a lavoro finito la cartella va in `[disabled]` |
| Database | **Normalizzazione con tabelle dedicate + migrazione** dei dati esistenti (nessuna perdita) |
| Interazioni in gioco | **Bridge configurabile**: `ox_target` (default) oppure marker classici, selezionabile da config |
| Carcere | **Sistema completo integrato** (celle, timer persistente, rilascio automatico, stato nel MDT) |
| Direzione estetica | **Variante 2 "Case File"** in dark totale (nessuna area chiara) |
| Icone | **Solo FontAwesome** (già in `package.json`). **Zero emoji**, anche nei seed SQL |
| Tipografia | **Una sola famiglia moderna** per tutta l'interfaccia (no serif) |
| Scala | Base **16 px su 1280×910 logici**, scalata proporzionalmente alla risoluzione |

### 1.1 Correzioni richieste sulla Variante 2

Tre feedback puntuali, recepiti come vincoli di design:

1. **Barra laterale troppo piccola** → il rail da `4.4em` icon-only diventa una **sidebar da 13 rem** con
   righe icona + etichetta, altezza minima riga **3 rem (48 px)**, icona **1.25 rem**. Resta un pulsante per
   collassarla a icone (56 px) per chi vuole più spazio al foglio, ma **il default è espansa**.
2. **Barra di ricerca troppo grossa, occupa due righe** → l'intestazione del fascicolo diventa una **riga
   singola che non va mai a capo**: `flex-nowrap` sul contenitore, `min-width:0` + `truncate` sul titolo,
   campo ricerca ridotto a `14 rem` e badge `CTRL K` spostato in tooltip (non più dentro al campo).
   Il filtro segmentato (Tutti / Ricercati / Detenuti) collassa a icone sotto i 1100 px logici.
3. **Font non graditi e disomogenei** → eliminati Georgia/serif e lo stack di sistema. **Inter Variable**
   self-hosted per tutto (400/500/600/700). Unica eccezione funzionale: **JetBrains Mono** solo per
   identificatori tabellari (SSN, targhe, orari, importi), perché le cifre a larghezza fissa evitano il
   ballerino nelle colonne. È un token singolo (`--font-numeric`): se non piace, si allinea a Inter
   cambiando una riga.

> I font vanno **inclusi nella risorsa** come `.woff2` sotto `web/assets/fonts/` e dichiarati in
> `fxmanifest.lua`: la NUI non ha accesso garantito alla rete, quindi Google Fonts via CDN non è affidabile.

---

## 2. Audit dello stato attuale

Tutto verificato leggendo il codice e interrogando il database `testserver`. Le voci marcate **[BUG]** sono
difetti reali confermati, non ipotesi.

### 2.1 Lato Lua / server

| # | File:riga | Problema | Gravità |
|---|---|---|---|
| L1 | `client/cl_radio.lua:17` | **[BUG] La radio non cambia canale.** `exports[res][name](...)` senza chiamata con `:` — il metatable di CFX (`scheduler.lua:718`) espone `function(self, ...)`, quindi **il primo argomento viene mangiato come `self`** e `setRadioChannel` riceve `nil`. In `sv_banking.lua:83` lo stesso problema era già stato notato e risolto correttamente | Alta |
| L2 | `server/sv_functions.lua:153` | **[BUG] Sovrascrittura concorrente.** `persistCitizen` riscrive l'intero blob JSON `criminalRecords`: due agenti che aggiungono un reato nello stesso momento si annullano a vicenda | Alta |
| L3 | `server/sv_functions.lua:345` | **[BUG] I flag veicolo non vengono mai salvati.** `SetVehicleFlag` muta solo `vehicles[plate]` in RAM: rubato/sequestrato si perdono al restart | Alta |
| L4 | `server/sv_main.lua:288` + `sv_functions.lua:1` | **[BUG] L'intero database viene inviato a ogni client.** `ServerDataInit` carica *tutti* gli utenti e *tutti* i veicoli, e `UpdateMDTData()` fa `TriggerClientEvent(..., -1)` → ogni agente riscarica l'intero payload **a ogni singolo reato, nota o report**. Con 5 utenti non si nota, a 3000 è insostenibile ed è anche una fuga di dati | Alta |
| L5 | `server/sv_main.lua:49` | Chiave dati su **SSN** invece che su `identifier`. In DB c'è già un record orfano (`kf_police_citizens.citizenid = 677-15-0384` con 4 reati) che non corrisponde a nessun utente → i precedenti si perdono ricreando il personaggio | Alta |
| L6 | `server/sv_functions.lua:331` | **[BUG] ID note duplicati.** `id = #citizen.notes + 1`: dopo una cancellazione due note condividono lo stesso id | Media |
| L7 | `server/sv_main.lua:249` | **[BUG] ID ricercati instabili.** `RefreshWantedList` rigenera gli id per indice di iterazione: l'id di una voce cambia tra due refresh | Media |
| L8 | `config.lua:9` | **[BUG] Conflitto tasto.** `Config.OpenKey = "F6"` collide con `police:quickactions` di `esx_policejob` (`client/main.lua:1452`), anch'esso su F6 | Media |
| L9 | `server/sv_main.lua:86` | `safeQuery` inghiotte gli errori e ritorna `{}`: un errore SQL diventa silenziosamente "nessun dato" | Media |
| L10 | `server/sv_functions.lua:110` | La sanzione viene **riestratta con regex** da una stringa già formattata (`sanction:match('%$(%d+)')`) invece di usare i campi `fine`/`jailTime` | Bassa |
| L11 | `kf_police.sql:52` | **Emoji nei seed** di `kf_police_tags` (⚠️ 🔫 💰 …), in contrasto diretto con la regola "solo icone FontAwesome" | Bassa |
| L12 | — | Nessun controllo di **permesso per grado**: qualunque agente `police` può marcare ricercati, cancellare report, sequestrare | Alta |

### 2.2 Lato UI / React

| # | File:riga | Problema | Gravità |
|---|---|---|---|
| U1 | `App.tsx:117`, `DebugMenu.tsx:16` | **[BUG] Memory leak.** `window.addEventListener('keydown', …)` chiamato **nel corpo del render**: un listener nuovo a ogni render, mai rimosso. F11 finisce per commutare più volte per pressione | Alta |
| U2 | `PagesContainer.tsx:78`, `CitizenSearch.tsx:29`, `VehicleSearch.tsx:15`, `CreateReport.tsx:25` | **[BUG] Violazione delle regole degli hook**: `while (!context) { context = useContext(...); return ... }` — hook chiamato condizionalmente e `return` dentro un `while` | Alta |
| U3 | `Badge.tsx:47` | **[BUG] Badge senza stile.** Classi Tailwind costruite per concatenazione (`"bg-" + colore + "-700"`): il JIT non le vede mai, quindi non vengono generate | Media |
| U4 | `Background.tsx:11` | **[BUG]** Stessa causa di U3 con valori arbitrari interpolati (`w-[${...}px]`) | Media |
| U5 | `App.css:32` | `.main-part` ha `align-items:center; justify-content:center` → il contenuto è centrato verticalmente e combatte con le tabelle | Media |
| U6 | `App.css:128` | `.flex-table { height:200px }` **fisso per tutte le tabelle**, con `.flex-table-body` che ne forza altre 200px | Media |
| U7 | `Dialog.tsx:29` | `useState(props.show)` mai risincronizzato con la prop; la X di chiusura non ha handler. Di fatto il componente è inutilizzabile ed è **commentato** in `App.tsx:200` | Media |
| U8 | `CreateReport.tsx:302`, `:380` | I pulsanti "Cerca" non hanno `onClick`: non fanno nulla | Bassa |
| U9 | `AgentManagement.tsx` | Stub: ritorna `<div>AgentManagement</div>` | Bassa |
| U10 | `App.tsx:63` | Tema iniziale hardcoded a `cib` mentre i job configurati sono `police`/`ambulance` | Bassa |
| U11 | `DataTable.tsx:27` | `size` applica `width` a celle che hanno anche `flex:1` → regole in conflitto | Bassa |
| U12 | `web/build/` | Bundle **stale committati** in git; nessuno script di build in CI | Bassa |
| U13 | — | Incoerenza raggi: nello stesso schermo convivono squadrato, `rounded-lg`, `rounded-xl`, `rounded-2xl`, `rounded-[50%]` e 14 grigi hardcoded da `#0a0a0a` a `#3a3a3a` | Media |

### 2.3 Funzioni presenti in UI ma non collegate al gioco

`AgentManagement` (vuoto) · gestione tag da UI · modifica/eliminazione singolo reato · pagamento multa ·
stato detenzione · dispatch/chiamate · pannello radio integrato · gestione licenze · foto segnaletica reale
(oggi `Config.DefaultImage` punta a `via.placeholder.com`, host esterno non raggiungibile dalla NUI).

---

## 3. Design system — specifica implementativa

> **Direzione approvata dal committente: "Case File v4", dark totale.** Questa sezione è vincolante e
> autosufficiente: contiene tutti i valori necessari a ricostruire l'interfaccia senza altre informazioni.

### 3.0 Riferimento visivo

Il mockup approvato, a dimensione reale e pixel-accurato, è salvato nel repository:

```
.claude/plans/assets/mockup-casefile-v4.html
```

**Aprirlo nel browser prima di scrivere qualunque componente.** È un file HTML statico autosufficiente
(CSS inline, icone SVG inline, nessuna dipendenza): rappresenta la schermata *Anagrafica cittadini* a
1280 × 910 con base 16 px. Tutti i valori in `rem` di questa sezione sono presi da lì e vanno rispettati.

Non è un riferimento indicativo ma **la specifica**: in caso di dubbio su una spaziatura, un colore o una
dimensione, si misura sul mockup.

### 3.1 Tipografia

Una sola famiglia per l'intera interfaccia. Georgia, i serif e lo stack di sistema attuale
(`index.css:9-12`) vengono **rimossi**.

| Ruolo | Famiglia | Uso |
|---|---|---|
| Interfaccia | **Inter** (400/500/600/700) | Tutto: titoli, etichette, corpo, pulsanti, tabelle |
| Numerico | **JetBrains Mono** (500/600) | Solo SSN, targhe, orari, importi, ID pratica |

L'eccezione monospace è **funzionale**, non estetica: le cifre a larghezza fissa impediscono alle colonne
di spostarsi quando i dati cambiano. È isolata nel token `--font-numeric`: per allinearla a Inter basta
cambiare quella riga.

**Installazione obbligatoriamente locale.** La NUI non ha accesso di rete garantito, quindi Google Fonts
via CDN non è affidabile: i font vanno inclusi nella risorsa.

1. Scaricare i `.woff2`:
   - `Inter` variable (o statici 400/500/600/700) → `web/assets/fonts/inter-*.woff2`
   - `JetBrains Mono` 500/600 → `web/assets/fonts/jetbrains-mono-*.woff2`
2. Dichiararli in `web/src/styles/fonts.css` con `@font-face` e `font-display: block`
   (non `swap`: nella NUI un ricalcolo di layout a metà apertura è visibile).
3. Aggiungerli ai `files` di `fxmanifest.lua`:

```lua
files {
    'web/build/index.html',
    'web/build/assets/**/*',
    'web/assets/fonts/*.woff2',
}
```

4. Verifica: avviare con la rete del client bloccata e controllare che il testo non ricada su Arial.

### 3.2 Scala: perché il tablet oggi è illeggibile e come si risolve

Due cause distinte, che vanno risolte insieme:

1. **Valori in pixel sparsi nel codice.** `w-[350px]`, `h-[100px]`, `text-[10px]`, `height:200px`: non
   scalano con nulla.
2. **Finestra a dimensione fissa.** `Config.window = {1080, 768}` è assoluto. Su 1080p occupa il 56% della
   larghezza; su 1440p e 4K la finestra CEF è più grande, quindi la stessa scatola da 1080 px diventa
   **proporzionalmente più piccola** e il testo diventa illeggibile.

**Soluzione: una sola unità.** Tutte le misure dei componenti in `rem`; la radice viene calcolata a runtime
in funzione della larghezza reale del tablet.

```lua
-- config/config.lua
Config.UI = {
    baseWidth   = 1280,   -- larghezza logica di progetto (il mockup)
    baseHeight  = 910,    -- rapporto 1.4066
    heightRatio = 0.86,   -- frazione dell'altezza schermo occupata dal tablet
    minWidth    = 1080,   -- non scende sotto
    maxWidth    = 1920,   -- non sale sopra
    scale       = 1.0,    -- zoom utente: 0.9 | 1.0 | 1.1
}
```

```lua
-- client/cl_nui.lua
function ComputeTabletGeometry()
    local sw, sh = GetActiveScreenResolution()
    local height = math.floor(sh * Config.UI.heightRatio)
    local width  = math.floor(height * (Config.UI.baseWidth / Config.UI.baseHeight))

    if width < Config.UI.minWidth then
        width  = Config.UI.minWidth
        height = math.floor(width * (Config.UI.baseHeight / Config.UI.baseWidth))
    elseif width > Config.UI.maxWidth then
        width  = Config.UI.maxWidth
        height = math.floor(width * (Config.UI.baseHeight / Config.UI.baseWidth))
    end

    return {
        width  = width,
        height = height,
        -- la NUI usa questo valore come font-size della radice
        rootFontSize = 16.0 * (width / Config.UI.baseWidth) * (Config.UI.scale or 1.0),
    }
end
```

```ts
// web/src/hooks/useTabletScale.ts
useEffect(() => {
  if (!geometry?.rootFontSize) return;
  document.documentElement.style.fontSize = `${geometry.rootFontSize}px`;
}, [geometry?.rootFontSize]);
```

Risultato: a 1920×1080, 2560×1440 e 3840×2160 il tablet occupa la stessa porzione di schermo e **la
dimensione apparente del testo è identica**. Va verificato su tutte tre le risoluzioni.

### 3.3 Minimi invalicabili

Regole del design system, non suggerimenti. Sono la risposta diretta al feedback "è tutto troppo piccolo":
valgono per **ogni componente nuovo**, così il problema non si ripresenta.

| Regola | Valore minimo | Note |
|---|---|---|
| Testo più piccolo in assoluto | `0.75rem` (12 px) | Solo intestazioni di colonna e etichette di gruppo |
| Testo dei dati in tabella | `0.95rem` (≈15 px) | Nomi, valori, contenuti |
| Testo di navigazione | `0.92rem` | Voci di sidebar |
| Titolo di sezione | `1.15rem` | Intestazione del foglio |
| Bersaglio cliccabile | `2.25rem` (36 px) | Pulsanti icona, chip cliccabili |
| Riga di tabella | `3.4rem` (≈54 px) | Include l'avatar da `2.25rem` |
| Voce di sidebar | `3rem` (48 px) | **Requisito esplicito del committente** |
| Icona di navigazione | `1.25rem` | Nella sidebar |
| Linguetta (tab) | `2.4rem` / `2.6rem` se attiva | |
| Campo di input | `2.3rem` | Ricerca, select, testo |

Sono vietati: `text-[10px]`, `text-[12px]`, `text-xs` su dati, e qualunque bersaglio cliccabile sotto
`2.25rem`. In fase F9 un grep in CI verifica l'assenza di valori arbitrari in pixel.

### 3.4 Token (`web/src/styles/tokens.css`)

Fonte unica di verità. **Nessun colore, raggio o dimensione hardcoded nei componenti.**

```css
:root {
  /* ---------- Tipografia ---------- */
  --font-ui:      'Inter', system-ui, -apple-system, sans-serif;
  --font-numeric: 'JetBrains Mono', ui-monospace, monospace;

  /* ---------- Superfici: nero-bruno caldo, non grigio-blu ---------- */
  --bg-shell:    #100E0B;   /* telaio del dispositivo          */
  --bg-chrome:   #0A0908;   /* status bar, sidebar, dock radio  */
  --bg-sheet:    #1A1611;   /* il "foglio" del fascicolo        */
  --bg-raised:   #221C15;   /* intestazioni di tabella, pannelli */
  --bg-inset:    #120F0C;   /* campi di input                   */
  --bg-tab:      #191510;   /* linguetta inattiva               */
  --bg-control:  #262019;   /* pulsanti icona, chip             */
  --bg-hover:    #1F1A14;
  --bg-active:   #1D1913;   /* voce di navigazione attiva       */

  /* ---------- Bordi ---------- */
  --line:        #302719;   /* bordo del foglio                 */
  --line-soft:   #241E17;   /* separatore di riga               */
  --line-perf:   #3A3025;   /* tratteggio "perforazione"        */
  --line-ctrl:   #3D3327;   /* bordo dei controlli              */
  --line-inset:  #33291F;   /* bordo dei campi                  */

  /* ---------- Testo ---------- */
  --fg:          #E8E1D4;
  --fg-strong:   #F0E9DC;
  --fg-muted:    #8A8175;
  --fg-dim:      #6B6459;   /* etichette di gruppo              */
  --fg-nav:      #9A9084;   /* voce di navigazione inattiva     */
  --fg-chrome:   #C9C0B0;   /* testo della status bar           */

  /* ---------- Accenti: semantici, non decorativi ---------- */
  --accent:      #A8322A;   /* identità LSPD, tab attiva, badge */
  --critical:    #E8695C;   /* ricercato, timbri, distruttivo   */
  --warning:     #C9A227;   /* radio, batteria, avvisi          */
  --success:     #7BB661;   /* in servizio, confermato          */
  --info:        #D98C6A;   /* azioni neutre, chevron           */

  /* ---------- Raggi: solo tre valori, più il cerchio ---------- */
  --r-sm:  0.25rem;   /* timbri, chip, campi, pulsanti icona   */
  --r-md:  0.5rem;    /* voci sidebar, linguette, crest, foglio */
  --r-lg:  0.75rem;   /* telaio del dispositivo, modali        */
  --r-dot: 9999px;    /* solo pallini di stato e badge numerici */
}
```

**Temi per dipartimento.** `police` / `sheriff` / `cib` / `ambulance` ridefiniscono **solo** `--accent` e
il crest; le superfici restano identiche. Il meccanismo attuale (`App.css:61-71`, che cambia solo `color`)
va rimosso.

```css
[data-dept='police']   { --accent: #A8322A; }
[data-dept='sheriff']  { --accent: #A67C00; }
[data-dept='cib']      { --accent: #6B7F1F; }
[data-dept='ambulance']{ --accent: #B03A32; }
```

### 3.5 Tailwind

`tailwind.config.js` **legge** i token, non li duplica: un valore cambia in un posto solo.

```js
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: { ui: 'var(--font-ui)', num: 'var(--font-numeric)' },
      colors: {
        shell: 'var(--bg-shell)',     chrome: 'var(--bg-chrome)',
        sheet: 'var(--bg-sheet)',     raised: 'var(--bg-raised)',
        inset: 'var(--bg-inset)',     tab: 'var(--bg-tab)',
        control: 'var(--bg-control)',
        fg: { DEFAULT: 'var(--fg)', strong: 'var(--fg-strong)',
              muted: 'var(--fg-muted)', dim: 'var(--fg-dim)', nav: 'var(--fg-nav)' },
        accent: 'var(--accent)',      critical: 'var(--critical)',
        warning: 'var(--warning)',    success: 'var(--success)', info: 'var(--info)',
        line: { DEFAULT: 'var(--line)', soft: 'var(--line-soft)',
                perf: 'var(--line-perf)', ctrl: 'var(--line-ctrl)' },
      },
      borderRadius: { sm: 'var(--r-sm)', md: 'var(--r-md)', lg: 'var(--r-lg)' },
    },
  },
}
```

> **Attenzione — causa dei bug U3/U4.** Tailwind genera solo le classi che vede come stringhe letterali.
> `"bg-" + colore + "-700"` (`Badge.tsx:47`) e `` `w-[${x}px]` `` (`Background.tsx:11`) **non vengono mai
> generate**: i badge attuali sono senza stile. Regola: mappe di classi complete e statiche, oppure
> `style={{ }}` per valori davvero dinamici.

```ts
// Corretto
const TONE = {
  critical: 'bg-critical/10 text-critical border-critical',
  warning:  'bg-warning/10  text-warning  border-warning',
} as const;
```

### 3.6 Struttura del layout

Albero dei componenti, con le misure fisse prese dal mockup:

```
DeviceFrame                    r-lg · bg-shell · overflow-hidden
├── StatusBar                  h 2.25rem · bg-chrome · border-b line-soft
│   ├── unità · posizione · SSN (font-numeric)
│   └── stato servizio · segnale · ora · batteria
└── main                       flex · min-h-0
    ├── Sidebar                w 13rem · bg-chrome · border-r line-soft
    │   ├── Brand              crest 2.5rem + città/dipartimento
    │   ├── gruppo "Archivio"  Anagrafica · Veicoli · Rapporti · Codice Penale
    │   ├── gruppo "Operativo" Ricercati · Detenuti · Radio · Servizio
    │   ├── CollapseToggle     h 2.25rem
    │   └── AgentCard          border-t line-soft
    └── stack                  flex-col · min-h-0
        ├── TabStrip           linguette 2.4rem (2.6rem se attiva)
        ├── Sheet              bg-sheet · border line · r 0 md md md
        │   ├── SheetHeader    h 3.5rem · flex-nowrap · border-b dashed line-perf
        │   ├── TableHead      h 2.5rem · bg-raised
        │   └── TableBody      righe 3.4rem
        └── RadioDock          h 3rem · bg-chrome
```

### 3.7 Specifica dei componenti

Misure esatte, tutte verificabili sul mockup. Padding orizzontale standard del contenuto: `1rem`.

#### StatusBar
`h 2.25rem` · `bg-chrome` · `border-b line-soft` · testo `0.8rem` colore `fg-muted` · gap tra gruppi
`1.15rem` · icone `0.95rem` · valori in grassetto colore `fg-chrome` peso 600.
Contenuto: distintivo unità (`1-ADAM-12`) · posizione corrente · SSN in `font-numeric` · **a destra**:
stato servizio (pallino `0.45rem` + testo `0.78rem` colore `success`), segnale, ora in `font-numeric`,
batteria (`1.75rem × 0.85rem`, bordo `#5C5449`, riempimento `warning`).

#### Sidebar — **larghezza 13rem** (correzione richiesta n. 1)
`bg-chrome` · `border-r line-soft` · padding `0.75rem 0.5rem` · gap `0.2rem`.

| Elemento | Specifica |
|---|---|
| Brand | crest `2.5rem` quadrato, `r-md`, fondo `accent`, icona `1.3rem` bianca; a fianco città `0.95rem/700` e dipartimento `0.7rem` maiuscoletto `fg-muted` con `letter-spacing .08em` |
| Etichetta di gruppo | `0.7rem/700`, maiuscolo, `letter-spacing .14em`, colore `fg-dim`, padding `0.7rem 0.6rem 0.35rem` |
| Voce (`SidebarItem`) | **`h 3rem`** · `r-md` · padding `0 0.7rem` · gap `0.7rem` · icona **`1.25rem`** · testo `0.92rem/500` colore `fg-nav` |
| Voce · hover | fondo `#171310`, testo `#D6CFC2` |
| Voce · attiva | fondo `bg-active`, testo `fg-strong` peso 600, `box-shadow: inset 0.2rem 0 0 var(--accent)` |
| Badge | `r-dot`, min `1.3rem × 1.3rem`, testo `0.7rem/700`; fondo `accent` bianco, oppure `warning` su `bg-shell` per i detenuti |
| CollapseToggle | `h 2.25rem` · `r-md` · fondo `#141110` · testo `0.75rem/600` colore `#7D7568` |
| AgentCard | `border-t line-soft` · avatar `2.1rem` `r-md` · nome `0.85rem/600` · grado `0.72rem` `fg-muted` |

Modalità compressa (facoltativa, attivata dal pulsante): `3.5rem`, solo icone centrate, etichette in
tooltip. **Il default è espansa.**

#### TabStrip
Padding `0.6rem 1rem 0` · gap `0.2rem`. Linguetta: `h 2.4rem`, `r-md r-md 0 0`, fondo `bg-tab`,
bordo `line`, **senza bordo inferiore**, testo `0.86rem/500` `fg-muted`, icona `0.95rem`, `white-space: nowrap`.
Attiva: `h 2.6rem`, fondo `bg-sheet` (si fonde col foglio), bordo `line-perf`, testo `fg-strong` peso 600,
`box-shadow: inset 0 0.18rem 0 var(--accent)`. Chiusura: `0.7rem` colore `fg-dim`.
A destra, separato da `flex:1`, il pulsante "nuova scheda" colore `warning`.

#### Sheet
`bg-sheet` · `border line` · `border-radius: 0 var(--r-md) var(--r-md) var(--r-md)` (l'angolo in alto a
sinistra è quadrato perché lì si innesta la linguetta) · margine orizzontale `1rem` · `overflow: hidden`.

#### SheetHeader — **riga singola** (correzione richiesta n. 2)
`h 3.5rem` (fissa) · padding `0 1rem` · `flex-nowrap` · gap `0.8rem` ·
`border-bottom: 1px dashed var(--line-perf)`.

| Elemento | Specifica |
|---|---|
| Titolo | contenitore `min-width: 0` + `overflow: hidden`; `h3` `1.15rem/700`, `letter-spacing -.01em`, `white-space: nowrap`, `text-overflow: ellipsis` |
| Contatore | `0.8rem/500` `fg-muted`, `font-numeric`, `nowrap` (es. `8 · 1 ricercato`) |
| SegmentedControl | `h 2.3rem` · `r-sm` · bordo `line-perf` · voce padding `0 0.8rem` testo `0.8rem/500`; attiva fondo `accent` testo bianco 600 |
| SearchField | **`w 14rem`** · `h 2.3rem` · `r-sm` · fondo `bg-inset` · bordo `line-inset` · testo `0.85rem` · icona `0.95rem` |
| Pulsante icona | `2.3rem` quadrato · `r-sm` · fondo `bg-control` · bordo `line-ctrl` · icona `0.95rem` colore `warning` |

**Vincoli obbligatori**: mai `flex-wrap`; il titolo è l'unico elemento che si comprime (`min-width: 0`);
il badge `CTRL K` **non va dentro il campo** (va in tooltip); sotto 1100 px logici il SegmentedControl
collassa a sole icone. Questo elimina l'andare a capo su due righe.

#### DataTable
Riscrittura completa di `web/src/pages/components/DataTable.tsx`. L'altezza **non** è più fissa
(elimina `App.css:128`, `height:200px`): il corpo occupa lo spazio residuo con `flex:1` + `overflow-y:auto`.

| Elemento | Specifica |
|---|---|
| Intestazione | `h 2.5rem` · `bg-raised` · `border-b line-perf` · testo `0.75rem/700` maiuscolo `letter-spacing .1em` colore `#948A7C` |
| Riga | **`h 3.4rem`** · `border-b line-soft` · testo `0.95rem` · hover `bg-hover` |
| Padding cella | `0 1rem` sulla riga, gap `0.75rem` tra colonne |
| Avatar | `2.25rem` quadrato · `r-sm` · fondo `#3D342A` |
| Nome | peso 600 |
| Pulsante apri | `2.25rem` quadrato · `r-sm` · fondo `bg-control` · bordo `line-ctrl` · chevron `0.85rem` colore `info` |
| Colonne | flex proporzionali: avatar `2.75rem` fisso, nome `1.15`, cognome `1.4`, cittadinanza `1`, impiego `1.3`, azioni `3.5rem` fisso |

Requisiti funzionali: ordinamento per colonna, paginazione (`Pagination`), `EmptyState` quando non ci sono
risultati, `Skeleton` durante il caricamento, virtualizzazione oltre 100 righe. Non si applica mai `width`
a celle che hanno anche `flex` (bug U11).

#### Stamp (timbro)
`display: inline-flex` · gap `0.3rem` · testo `0.72rem/700` `letter-spacing .09em` · padding `0.18rem 0.42rem` ·
colore e bordo `critical` (`1.5px`) · `r-sm` · fondo `rgba(232,105,92,.09)` ·
**`transform: rotate(-2.5deg)`** · margine sinistro `0.45rem` · icona `0.8rem`.
La leggera rotazione è ciò che dà il carattere "fascicolo": va mantenuta.

#### RadioDock
`h 3rem` · `bg-chrome` · bordo `#262019` · `r-md` · padding `0 0.9rem` · gap `0.75rem` · margine
`0.65rem 1rem 0.8rem`.
Contenuto: icona radio `1.3rem` colore `warning` · nome canale `0.9rem/600` · sottotitolo `0.75rem` colore
`warning` (`CH 1 · 4 agenti in ascolto`) · istogramma di 5 barre (`w 0.2rem`, altezza `1.15rem` massima,
colore `warning`, animato solo quando qualcuno parla) · a destra i pulsanti canale (`h 2rem`,
padding `0 0.7rem`, `r-sm`, testo `0.8rem/600`; attivo: fondo `#2A2118`, bordo `warning`, testo `#E8DFC9`).

#### Altri componenti da costruire
`Button` (primary `accent` / ghost / danger `critical`; taglie `2.25` / `2.5` / `2.75rem`) ·
`Field` (input, select, textarea uniformi: `h 2.3rem`, `bg-inset`, bordo `line-inset`, `r-sm`) ·
`Modal` che **sostituisce** `Dialog.tsx` (stato controllato dalle props, non copiato in `useState`, e
pulsante di chiusura funzionante — bug U7) · `ConfirmDialog` per le azioni distruttive · `Chip` ·
`Avatar` · `Toast` (notifiche **dentro** il tablet) · `EmptyState` · `Skeleton` · `Pagination` ·
`SegmentedControl` · `Icon`.

### 3.8 Icone — solo FontAwesome, mai emoji

`@fortawesome/free-solid-svg-icons` è già in `package.json`. **Zero emoji in tutto il progetto**, incluse
`shared/locales/*.lua` e i seed SQL (oggi `kf_police.sql:52` inserisce ⚠️ 🔫 💰 nei tag: vanno sostituite
con la colonna `icon`).

Registro centralizzato in `web/src/components/Icon.tsx`, così le icone non vengono importate a caso nei
componenti:

```ts
export const ICONS = {
  citizens: faUsers,        vehicles: faCar,          reports: faFileLines,
  penalcode: faScaleBalanced, wanted: faSkullCrossbones, jail: faHandcuffs,
  radio: faWalkieTalkie,    duty: faUserShield,       search: faMagnifyingGlass,
  close: faXmark,           add: faPlus,              open: faChevronRight,
  collapse: faChevronLeft,  identity: faIdCard,       location: faLocationDot,
  signal: faSignal,         clock: faClock,           warning: faTriangleExclamation,
  evidence: faFingerprint,  charge: faGavel,
} as const;
```

I tag del database usano la **chiave** di questo registro nella colonna `icon`, non un carattere Unicode.

### 3.9 Verifica della parte grafica

- [ ] Il mockup `.claude/plans/assets/mockup-casefile-v4.html` e l'interfaccia reale sono sovrapponibili a 1280×910
- [ ] `grep -rE "text-\[|w-\[|h-\[|#[0-9a-fA-F]{6}" web/src/components web/src/pages` → nessun risultato
- [ ] Nessuna emoji in `web/src`, `shared/locales`, `sql/`
- [ ] Nessun font serif o di sistema: solo Inter e JetBrains Mono, caricati localmente
- [ ] Sidebar `13rem` con righe `3rem`; intestazione del foglio su **una riga sola** a ogni larghezza
- [ ] Leggibilità verificata a 1920×1080, 2560×1440, 3840×2160 con dimensione apparente identica
- [ ] `npm run build` senza errori TypeScript









---

## 4. Architettura target

Struttura a moduli, sullo stesso schema di `KF_AmbulanceJob` (che già usa `modules/framework`,
`modules/target`, `modules/inventory`): coerenza interna ai tuoi script e sostituibilità del framework.

```
KF_Police/
├── fxmanifest.lua
├── config/
│   ├── config.lua           # generale, UI/scala, pagine, permessi per grado
│   ├── cfg_stations.lua     # stazioni, zone, spogliatoi, armerie, garage, celle
│   ├── cfg_duty.lua         # servizio, divise per grado/sesso
│   ├── cfg_armory.lua       # armi, accessori, prezzi, stock
│   ├── cfg_vehicles.lua     # veicoli di servizio per grado
│   ├── cfg_actions.lua      # azioni cittadino/veicolo, oggetti piazzabili
│   ├── cfg_radio.lua        # canali (migrato dall'attuale Config.Radio)
│   ├── cfg_jail.lua         # celle, tempi, conversione mesi→secondi
│   └── cfg_banking.lua      # adapter fatturazione (migrato da Config.Banking)
├── modules/
│   ├── framework/  sh_bridge.lua · cl_esx.lua · sv_esx.lua
│   ├── target/     cl_ox.lua · cl_marker.lua        # bridge configurabile
│   ├── inventory/  sv_ox.lua · sv_esx.lua
│   ├── clothing/   cl_appearance.lua · cl_skinchanger.lua
│   ├── voice/      cl_pma.lua                       # con la chiamata export corretta
│   └── notify/     cl_notify.lua
├── shared/         sh_utils.lua · sh_permissions.lua · locales/{it,en}.lua
├── client/         cl_main · cl_nui · cl_duty · cl_cloakroom · cl_armory · cl_garage
│                   cl_actions_citizen · cl_actions_vehicle · cl_cuffs · cl_drag
│                   cl_impound · cl_objects · cl_jail · cl_radio · cl_blips
├── server/         sv_main · sv_database · sv_migrations · sv_citizens · sv_charges
│                   sv_reports · sv_wanted · sv_notes · sv_vehicles · sv_penalcode
│                   sv_duty · sv_armory · sv_garage · sv_jail · sv_fines
│                   sv_actions · sv_permissions · sv_logger
├── sql/            install.sql · migrations/001_normalize.sql
└── web/            (React, invariato come toolchain)
```

### 4.1 Principio di sicurezza

Ogni callback server **rivalida sempre**: giocatore esiste → job autorizzato → grado ha il permesso →
input sanificato. Non ci si fida mai del payload NUI. `shared/sh_permissions.lua` definisce:

```lua
Config.Permissions = {
    police = {
        [0] = { 'mdt.view', 'mdt.report.create', 'mdt.note.create' },              -- recruit
        [1] = { '@0', 'mdt.charge.add', 'mdt.vehicle.flag', 'field.cuff' },        -- officer
        [2] = { '@1', 'mdt.wanted.set', 'field.impound', 'field.fine' },           -- sergeant
        [3] = { '@2', 'mdt.charge.void', 'mdt.report.delete', 'jail.release' },     -- lieutenant
        [4] = { '@3', 'mdt.penalcode.edit', 'mdt.tag.edit', 'society.boss' },       -- boss
    },
}
```

`'@N'` eredita dal grado N. I gradi corrispondono a quelli reali in `job_grades`
(recruit/officer/sergeant/lieutenant/boss), verificati in DB.

---

## 5. Database

### 5.1 Nuovo schema

Chiave primaria di riferimento: **`identifier`** (stabile), con `ssn` come colonna indicizzata di comodo.

| Tabella | Contenuto |
|---|---|
| `kf_police_profiles` | `identifier` PK, `ssn`, `mugshot`, `is_wanted`, `wanted_reason`, `wanted_by_id`, `wanted_by_name`, `wanted_at`, `updated_at` |
| `kf_police_charges` | `id` PK, `identifier` IDX, `penalcode_id`, `crime`, `fine`, `jail_months`, `is_paid`, `officer_id`, `officer_name`, `location`, `victim_identifier`, `report_id`, `created_at`, `voided_at`, `voided_by` |
| `kf_police_notes` | `id` PK, `identifier` IDX, `note`, `officer_id`, `officer_name`, `created_at`, `updated_at` |
| `kf_police_reports` | esistente + `status` (`draft`/`open`/`closed`), `is_confidential`, `updated_at` |
| `kf_police_report_involved` | `report_id` + `identifier` + `role` (`suspect`/`victim`/`witness`) — PK composita |
| `kf_police_report_vehicles` | `report_id` + `plate` |
| `kf_police_report_tags` | `report_id` + `tag_id` |
| `kf_police_tags` | `id`, `label`, **`icon`** (nome FontAwesome), `color` — **emoji rimosse** |
| `kf_police_penalcode` | `id`, `code` (es. `PC-187`), `category_id`, `title`, `description`, `fine`, `jail_months`, `is_felony` |
| `kf_police_penalcode_categories` | `id`, `label`, `icon`, `sort_order` |
| `kf_police_vehicle_flags` | `plate` PK, `is_stolen`, `is_impounded`, `impound_reason`, `impound_by`, `impound_at`, `has_bolo`, `bolo_reason`, `notes` |
| `kf_police_jail` | `identifier` PK, `seconds_remaining`, `total_seconds`, `reason`, `officer_id`, `officer_name`, `cell`, `jailed_at`, `released_at` |
| `kf_police_armory_stock` | `item` PK, `count` |
| `kf_police_duty_log` | `id`, `identifier`, `action` (`in`/`out`), `at` |
| `kf_police_audit` | `id`, `actor_identifier`, `action`, `target`, `payload` JSON, `at` — tracciabilità anti-exploit |

### 5.2 Migrazione (`sql/migrations/001_normalize.sql` + `server/sv_migrations.lua`)

1. Backup automatico: `kf_police_citizens` → `kf_police_citizens_backup_20260819` (`CREATE TABLE … SELECT *`).
2. Per ogni riga: risoluzione `citizenid` → `users.identifier` tramite `users.ssn`.
3. `criminalRecords` decodificato e **esploso in righe** di `kf_police_charges`, preservando
   `date`/`officer`/`crime`/`fine`/`jailTime`/`location`.
4. `notes` esplose in `kf_police_notes`; `wanted*` in `kf_police_profiles`.
5. **Orfani preservati**, non cancellati: i record il cui SSN non esiste più in `users` (nel tuo DB c'è
   `677-15-0384` con 4 reati) finiscono in `kf_police_orphan_records` con il JSON originale, per revisione
   manuale invece di sparire silenziosamente.
6. Migrazione **idempotente**: tabella `kf_police_schema_version`, la migrazione gira una sola volta.
7. `kf_police_citizens` resta in sola lettura per due release, poi si elimina.

Nota: `Config.AutoDatabaseCreation` con i `CREATE TABLE` inline in `sv_functions.lua:9-107` viene
sostituito dal caricamento di `sql/install.sql`, così schema e codice non divergono più.

---

## 6. Contratto NUI

Si abbandona il modello "invia tutto il DB e filtra in React" (causa di L4) per **query su richiesta con
paginazione**. Tutto passa da `lib.callback` con risposta tipizzata.

### 6.1 Callback (NUI → client → server)

| Callback | Payload | Risposta |
|---|---|---|
| `mdt:bootstrap` | — | profilo agente, permessi risolti, pagine abilitate, contatori (ricercati/detenuti/report aperti), config UI |
| `mdt:citizens:search` | `{ query, filter, page, pageSize }` | `{ rows, total, page }` — ricerca **SQL** su nome/cognome/SSN/telefono |
| `mdt:citizens:get` | `{ identifier }` | dossier completo: profilo, reati, note, veicoli, licenze, proprietà, report collegati, stato detenzione |
| `mdt:vehicles:search` | `{ query, filter, page }` | `{ rows, total }` — targa/modello/proprietario |
| `mdt:vehicles:get` | `{ plate }` | veicolo + flag + proprietario + storico |
| `mdt:vehicles:setFlag` | `{ plate, stolen?, impounded?, bolo?, reason }` | ok — **con persistenza** (risolve L3) |
| `mdt:reports:list` | `{ query, status, page }` | `{ rows, total }` |
| `mdt:reports:get` / `:save` / `:delete` | `{ id }` / `{ … }` | dettaglio con coinvolti e tag dalle tabelle di giunzione |
| `mdt:charges:add` | `{ identifier, penalcodeIds[], location, victim, reportId? }` | **INSERT atomici** multipli (risolve L2) |
| `mdt:charges:void` | `{ chargeId, reason }` | annullamento tracciato, non cancellazione |
| `mdt:wanted:set` / `:list` | `{ identifier, wanted, reason }` | ok / elenco con id stabili (risolve L7) |
| `mdt:notes:add` / `:delete` | `{ identifier, note }` / `{ id }` | id da AUTO_INCREMENT (risolve L6) |
| `mdt:penalcode:list` / `:save` / `:delete` | — / articolo | elenco per categoria; scrittura solo con `mdt.penalcode.edit` |
| `mdt:tags:list` / `:save` | — | tag con **icona FontAwesome**, non emoji |
| `mdt:fines:issue` / `:list` | `{ identifier, amount, label }` | emissione via adapter di `cfg_banking.lua` |
| `mdt:jail:list` / `:release` | — / `{ identifier }` | detenuti con tempo residuo |
| `mdt:duty:toggle` / `:roster` | — | stato servizio, agenti online per grado |
| `mdt:radio:state` / `:join` / `:leave` / `:volume` | `{ channelId }` | stato canali autorizzati per grado |

### 6.2 Push (server → client → NUI)

Sostituisce il broadcast totale con **invalidazione mirata**:

| Evento | Uso |
|---|---|
| `mdt:invalidate` | `{ scope: 'citizen'\|'reports'\|'wanted'\|'vehicles'\|'jail', id? }` — la UI ricarica **solo** la vista interessata, e solo se ha il MDT aperto su quella vista |
| `mdt:counters` | aggiorna solo i badge di navigazione |
| `mdt:notify` | notifica in-app (toast dentro il tablet, non `esx:showNotification`) |
| `mdt:radio:state` | cambio canale, agenti in ascolto, chi sta parlando |
| `mdt:dispatch` | nuova chiamata/panico |

---

## 7. Assorbimento di esx_policejob

Mappa completa di ciò che viene reimplementato. Tutto passa dal bridge `modules/target` (ox_target o
marker) e dai menu `ox_lib` (`lib.registerContext` / `lib.showContext`, già disponibili in
`[ox]/ox_lib/resource/interface/client/context.lua`), sostituendo `ESX.OpenContext`.

| Funzione esx_policejob | Origine | Destinazione KF_Police |
|---|---|---|
| Spogliatoio / divise per grado | `client/main.lua:34` + `Config.Uniforms` | `cl_cloakroom.lua` + `cfg_duty.lua`, via bridge `modules/clothing` (`fivem-appearance` o `skinchanger`, entrambi presenti) |
| Armeria: prendi/deposita/compra armi | `client/main.lua:195,692,718,746,833` | `cl_armory.lua` + `sv_armory.lua`, stock su `kf_police_armory_stock` invece di `esx_datastore` |
| Stock oggetti società | `server/main.lua:117,142` | `sv_armory.lua` via `modules/inventory` (ox_inventory) |
| Garage veicoli di servizio | `client/vehicle.lua` | `cl_garage.lua` + `sv_garage.lua`. **Rimuove la dipendenza da `esx_vehicleshop`**, che sul tuo server è in `[disabled]` — quindi oggi il garage è già rotto |
| Boss menu | `client/main.lua:1436` | `society.boss` + `esx_society` (attivo) o menu interno |
| Manette / slega / timer | `client/main.lua:1028-1089` | `cl_cuffs.lua` + `sv_actions.lua`, con item `handcuffs` già in ox_inventory |
| Scorta (drag) | `client/main.lua:1090` | `cl_drag.lua` |
| Metti/togli dal veicolo | `client/main.lua:1128,1152` | `cl_actions_citizen.lua` |
| Carta d'identità | `client/main.lua:403` | `cl_actions_citizen.lua` → apre la **scheda MDT** invece di un menu di testo |
| Perquisizione corpo | `client/main.lua:434` | `cl_actions_citizen.lua` + `sv_actions.lua` |
| Multe (52 righe in `fine_types`) | `client/main.lua:495-588` | `sv_fines.lua`, **unificato al codice penale**: le multe diventano articoli con categoria, non una tabella separata |
| Multe non pagate | `client/main.lua:654` | pannello MDT via `esx_billing` (`BillPlayerByIdentifier`, export verificato) |
| Licenze: verifica/revoca | `client/main.lua:622` | `sv_actions.lua` su `user_licenses` (11 righe presenti) |
| Info veicolo / targa | `client/main.lua:589,674` | `cl_actions_vehicle.lua` → apre la scheda veicolo nel MDT |
| Lockpick veicolo | `client/main.lua:329` | `cl_actions_vehicle.lua` con `lib.progressBar` |
| Sequestro veicolo | `client/main.lua:1543` | `cl_impound.lua` + `sv_vehicles.lua`, **con persistenza** su `kf_police_vehicle_flags` |
| Oggetti piazzabili (coni, barriere, chiodi) | `client/main.lua:370` | `cl_objects.lua` + `cfg_actions.lua`, con rimozione e pulizia allo stop risorsa |
| Blip colleghi | `client/main.lua:1479` | `cl_blips.lua`, con opzione "solo in servizio" |
| Servizio (in/out) | `Config.EnableESXService` | `cl_duty.lua` + `sv_duty.lua` interno, log su `kf_police_duty_log`. Rimuove la dipendenza da `esx_service` |
| Allerta polizia telefono | `server/main.lua:7` | `sv_main.lua`, registrazione contatto mantenuta per `lb-phone` |

**Non assorbito** (resta esterno, per scelta): gestione società/conti → `esx_society` + `esx_addonaccount`;
fatturazione → `esx_billing`; vestiario → `fivem-appearance`/`skinchanger`. Sono servizi condivisi con
altri job, duplicarli farebbe danno.

---

## 8. Fasi di lavoro

Ogni fase è **autoconclusiva e testabile**: a fine fase il server parte e il gioco funziona. Niente
"grande esplosione" a metà lavoro.

### F0 · Preparazione
- Branch `feature/mdt-rework`; `.superpowers/` già aggiunto a `.gitignore`.
- Dump del DB (`mysqldump testserver` → `sql/backup/`).
- Rimozione dei bundle stale da `web/build/` dal tracking git (`.gitignore` + `git rm --cached`).
- **Accettazione**: il repo è pulito, il backup esiste e si ripristina.

### F1 · Fondazioni Lua
- `config/` splittato; `modules/framework`, `modules/target`, `modules/inventory`, `modules/voice`.
- `sql/install.sql` + `sv_migrations.lua` con versionamento e migrazione dati.
- `sh_permissions.lua` e wrapper `RequirePermission(src, 'chiave')` usato da **tutti** i callback.
- `sv_logger.lua` → `kf_police_audit`.
- **Correzione L1**: chiamata export corretta (`exports[res]:name(...)`) in `modules/voice/cl_pma.lua`.
- **Correzione L8**: tasto MDT spostato su `F5` (con `Config.OpenKey` configurabile) per non collidere.
- **Accettazione**: migrazione eseguita, i 4 reati orfani sono in `kf_police_orphan_records`, la radio
  cambia canale davvero (verificabile con `/setradio` di pma-voice e log).

### F2 · Design system UI

**Riferimento vincolante: §3 nella sua interezza.** Aprire prima
`.claude/plans/assets/mockup-casefile-v4.html` e tenerlo a fianco durante il lavoro.

Ordine di esecuzione consigliato:

1. `web/src/styles/fonts.css` + i `.woff2` in `web/assets/fonts/` + voce in `fxmanifest.lua` (§3.1).
2. `web/src/styles/tokens.css` con i token integrali (§3.4) e i temi per dipartimento.
3. `tailwind.config.js` che legge i token (§3.5). Da qui in poi **nessun valore hardcoded**.
4. Scala dinamica: `ComputeTabletGeometry()` lato client e `useTabletScale()` lato NUI (§3.2).
5. Componenti di telaio: `DeviceFrame`, `StatusBar`, `Sidebar` (13 rem, righe 3 rem), `TabStrip`,
   `Sheet` con `SheetHeader` a riga singola, `RadioDock` (§3.6, §3.7).
6. Componenti di contenuto: `DataTable` riscritta, `Stamp`, `Button`, `Field`, `Modal`, `Chip`, `Avatar`,
   `Toast`, `EmptyState`, `Skeleton`, `Pagination`, `SegmentedControl`, `Icon` (§3.7, §3.8).
7. Correzione dei bug UI in elenco: U1 (listener in `useEffect` con cleanup), U2 (hook in cima, early
   return **dopo**), U3/U4 (mappe di classi statiche), U5, U6, U7, U10, U11, U13.
8. Rimozione di `App.css` a favore dei token; eliminazione di `Background.tsx` e `Badge.tsx` nella forma
   attuale.

**Accettazione**: la checklist §3.9 è tutta spuntata; `npm run build` passa senza errori TypeScript;
l'interfaccia è sovrapponibile al mockup.


### F3 · MDT: dati reali e funzioni core
- Riscrittura dello strato dati: da `setData` monolitico a callback paginati (§6).
- Anagrafica, scheda cittadino, veicoli, scheda veicolo, report (creazione/modifica/eliminazione con
  coinvolti e tag), codice penale con categorie, ricercati, note, reati.
- Reati: aggiunta **multipla** in una transazione, annullamento tracciato, calcolo automatico di multa e
  mesi totali. **Risolve il "salvataggio dei reati che non funziona bene"** (L2).
- `AgentManagement` implementata: roster, gradi, stato servizio, log ore (**U9**).
- Foto segnaletica: URL configurabile con fallback **locale** (`web/assets/guest.png`, già presente),
  eliminando `via.placeholder.com`.
- **Accettazione**: due agenti aggiungono reati contemporaneamente allo stesso cittadino e **entrambi**
  restano salvati; ogni scrittura compare in `kf_police_audit`; un agente `recruit` non riesce a marcare
  un ricercato.

### F4 · Radio integrata nel tablet
- `RadioDock` fisso nel telaio (footer del fascicolo) + pagina Radio completa: elenco canali autorizzati
  per grado, volume, agenti in ascolto, indicatore di chi parla.
- Rimozione dell'overlay separato (`BottomButtons.tsx:33`).
- Uscita automatica dal canale allo smontaggio job/risorsa.
- **Accettazione**: connessione, cambio canale e voce funzionano con `pma-voice`; il pannello non è più
  una schermata a parte.

### F5 · Azioni di campo
- Manette (+ timer, animazioni, item `handcuffs`), scorta, metti/togli dal veicolo, perquisizione,
  carta d'identità → apre la scheda MDT, multe, licenze, lockpick, sequestro con persistenza, oggetti
  piazzabili.
- Menu radiale/contestuale `ox_lib` con permessi per grado.
- **Accettazione**: nessun evento client→server accetta un target non validato; sequestro sopravvive al
  restart; un `recruit` non può sequestrare.

### F6 · Strutture (stazione)
- Spogliatoio, armeria con stock, garage di servizio, boss menu, servizio in/out.
- Zone da `cfg_stations.lua` tramite bridge target; marker come fallback.
- **Accettazione**: l'intero ciclo (entra in servizio → divisa → arma → veicolo → fine servizio) funziona
  **senza `esx_policejob` avviato**.

### F7 · Carcere
- Celle configurabili, invio in cella con motivo e reati collegati, **timer persistente** (sopravvive a
  disconnessione e restart, si scala solo online o anche offline secondo config), rilascio automatico,
  rilascio manuale con permesso `jail.release`, stato visibile nel MDT e nella scheda cittadino.
- Conversione `jail_months` → secondi da `cfg_jail.lua`.
- **Accettazione**: detenuto che si disconnette e rientra ha il tempo residuo corretto; il rilascio
  automatico funziona anche se l'agente che ha arrestato è offline.

### F8 · Dismissione esx_policejob
- Item `mdt` in `ox_inventory` (oggi esistono `tablet` e `police_cad`, quest'ultimo puntato a
  `origen_police`: va sostituito o creato `police_mdt` dedicato).
- `esx_policejob` spostato in `[disabled]`; verifica che nessun'altra risorsa ne triggeri gli eventi.
- README con installazione, config, permessi, migrazione.
- **Accettazione**: `esx_policejob` disattivato e **nessuna funzionalità persa**; nessun errore in console.

### F9 · Hardening e collaudo
- Rate limiting sui callback, validazione lunghezze/tipi, protezione contro payload NUI malevoli.
- Test di carico: elenco cittadini con 3000 record paginato (oggi caricherebbe tutto in RAM e in NUI).
- Passata finale su leggibilità a 1080p / 1440p / 4K.
- **Accettazione**: nessun warning in console client e server; tempi di risposta MDT < 150 ms sulle liste.

---

## 9. Rischi e mitigazioni

| Rischio | Mitigazione |
|---|---|
| La migrazione dati corrompe i precedenti penali | Backup automatico + tabella orfani + migrazione idempotente + verifica conteggi prima/dopo |
| Altre risorse dipendono da eventi `esx_policejob:*` | Grep su tutte le risorse prima di F8; se necessario si registrano alias di compatibilità |
| `esx_vehicleshop` disabilitato rompe i veicoli di servizio | Il garage viene reimplementato in F6 senza quella dipendenza |
| Conflitto tasto F6 con altri script | `Config.OpenKey` configurabile; default spostato su F5 e verificato contro gli altri `RegisterKeyMapping` del server |
| Il rework UI rallenta la NUI | Componenti memoizzati, liste virtualizzate oltre 100 righe, payload paginati |
| Perdita di lavoro in caso di rollback | Una fase = un commit atomico; il server resta avviabile a ogni fase |

## 10. Verifica finale (checklist)

- [ ] Nessuna emoji in `web/src`, `shared/locales`, `sql/`
- [ ] Nessun colore/raggio/dimensione hardcoded nei componenti React
- [ ] Testo minimo 12 px effettivi a 1080p; bersagli ≥ 36 px
- [ ] Tutti i callback server validano job **e** permesso di grado
- [ ] Ogni scrittura sensibile è in `kf_police_audit`
- [ ] `esx_policejob` in `[disabled]` senza regressioni
- [ ] Migrazione riproducibile su DB pulito e su DB esistente
- [ ] `npm run build` senza errori; bundle non tracciati in git
- [ ] Leggibilità verificata a 1920×1080, 2560×1440, 3840×2160

---

## Appendice A · Riferimenti verificati nell'ambiente

- ESX **1.14.0**, `xPlayer.getSSN()` disponibile (`es_extended/server/classes/player.lua:271`)
- `ESX.RegisterInput` esiste ma è in `client/compat.lua:60` (API di compatibilità) → si preferisce
  `RegisterKeyMapping` nativo o `lib.addKeybind`
- `ox_lib` con `context`, `menu`, `radial`, `input`, `progress`, `notify`, `callback`
- `ox_target` e `ox_inventory` **2.44.1** presenti e avviati
- `pma-voice`: export `setRadioChannel`, `removePlayerFromRadio`, `setRadioVolume`, `setVoiceProperty`
- `esx_billing`: export `BillPlayerByIdentifier` confermato (`server/main.lua:65`)
- `esx_society`: export `registerSociety` + evento `esx_society:openBossMenu`
- DB `testserver`: 5 utenti, **0 veicoli posseduti**, 7 articoli codice penale, 52 righe `fine_types`,
  11 licenze utente, 1 profilo in `kf_police_citizens` (orfano), 0 report
- Gradi `police`: `recruit`(0) `officer`(1) `sergeant`(2) `lieutenant`(3) `boss`(4) = *Captain*
- `users.nationality` esiste (default `Los Santos`) → usare quella al posto di `Config.DefaultTown`
- Vestiario disponibile: `fivem-appearance` **e** `skinchanger`/`esx_skin` → bridge configurabile






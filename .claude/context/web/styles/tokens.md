# web/src/styles/tokens.css

**Ruolo:** **fonte unica di verità** di colori, raggi, altezze e scala delle icone.
**Contesto:** UI
**Caricato da:** `web/src/index.css`

## La regola

Nessun colore, raggio o dimensione va scritto a mano dentro un componente.
**`tailwind.config.js` LEGGE questi token, non li duplica**, quindi un valore cambia in un
posto solo.

Direzione approvata: **"Case File v4"**, dark totale. Le superfici sono un nero-bruno caldo,
non un grigio-blu.

## I gruppi

### Tipografia

`--font-ui` (Inter + ripieghi di sistema), `--font-numeric` (JetBrains Mono).

### Superfici (11)

Dal più scuro al più chiaro: `--bg-chrome` `#0a0908` (status bar, sidebar, dock) →
`--bg-shell` `#100e0b` (telaio) → `--bg-inset` `#120f0c` (campi) → `--bg-tab` `#191510`
(linguetta inattiva) → `--bg-sheet` `#1a1611` (**il foglio del fascicolo**) →
`--bg-active` / `--bg-hover` / `--bg-nav-hover` / `--bg-collapse` →
`--bg-raised` `#221c15` (intestazioni tabella, pannelli) → `--bg-control` `#262019`
(pulsanti icona, chip) → `--bg-avatar` `#3d342a`.

### Bordi (5)

`--line` (foglio), `--line-soft` (riga), **`--line-perf`** (tratteggio "perforazione", il
dettaglio che dà il carattere fascicolo), `--line-ctrl` (controlli), `--line-inset` (campi).

### Testo (9)

`--fg` `#e8e1d4` base, `--fg-strong` per i dati importanti, `--fg-muted` secondario,
`--fg-dim` etichette di gruppo, `--fg-nav` / `--fg-nav-hover` navigazione, `--fg-chrome`
status bar, `--fg-head` intestazioni di colonna, `--fg-collapse`.

### Accenti: semantici, non decorativi

| Token | Valore | Significato |
|---|---|---|
| `--accent` | `#a8322a` | identità LSPD, tab attiva, badge |
| `--critical` | `#e8695c` | ricercato, timbri, distruttivo |
| `--warning` | `#c9a227` | radio, batteria, avvisi, detenuto |
| `--success` | `#7bb661` | in servizio, confermato |
| `--info` | `#d98c6a` | azioni neutre, chevron |

Un colore ha **un** significato: non usare `--warning` per decorare.

### Raggi: solo tre valori, più il cerchio

`--r-sm` 0.25 rem (timbri, chip, campi, pulsanti icona) · `--r-md` 0.5 rem (sidebar,
linguette, crest, foglio) · `--r-lg` 0.75 rem (telaio, modali) · `--r-dot` (solo pallini di
stato e badge numerici).

È la correzione del bug U13.

### Altezze invalicabili

`--h-statusbar` 2.25 · **`--h-nav` 3 rem (48 px, requisito esplicito del committente)** ·
`--h-tab` 2.4 / `--h-tab-active` 2.6 · `--h-sheet-header` 3.5 · `--h-thead` 2.5 ·
`--h-row` 3.4 · `--h-field` 2.3 · `--h-radiodock` 3 · **`--h-target` 2.25 rem (bersaglio
cliccabile minimo)** · `--h-btn-sm/md/lg` 2.25/2.5/2.75.

`--w-sidebar` 13 rem (correzione richiesta n. 1) · `--w-sidebar-collapsed` 3.5 rem ·
`--w-search` 14 rem (correzione richiesta n. 2).

### Scala icone

`--ico-xs` 0.7 → `--ico-2xl` 1.3 rem. Sei gradini, consumati da `Icon.tsx` tramite
`SIZE_VAR`.

## Temi per dipartimento

`[data-dept='police'|'sheriff'|'cib'|'ambulance']` ridefiniscono **solo `--accent`**. Le
superfici restano identiche, così un cambio di reparto non diventa un tema diverso.

`DeviceFrame` scrive `data-dept={officer?.job}` sul contenitore del tablet.

## Note e trappole

- **Aggiungere un token richiede due modifiche**: qui e in `tailwind.config.js` (se serve
  come classe Tailwind). Solo qui se lo si usa via `var(--...)` in uno `style`.
- **Un nome non può stare sia in `colors` sia in `fontSize`.** È la trappola più cattiva di
  questa configurazione, ed è già costata un bug. `tab` e `chrome` erano in entrambe le
  scale: Tailwind genera `text-*` sia da `fontSize` sia da `textColor` (che per difetto
  ricava da tutto `colors`), quindi `text-tab` produceva **due** regole omonime, una di
  `font-size` e una di `color`. Vinceva quella che compare più tardi nel foglio, cioè il
  colore — e non solo sovrascriveva il colore dichiarato accanto, lo faceva con
  `var(--bg-tab)`:

  > la linguetta attiva scriveva il proprio titolo in `#191510`, cioè esattamente il colore
  > del suo fondo. Testo perfettamente invisibile, DOM corretto, nessun errore in console.

  La status bar perdeva invece la dimensione `0.78rem` del mockup, per la stessa ragione su
  `text-chrome`.

  La cura è in `tailwind.config.js`: **`textColor` è dichiarato per esteso, fuori da
  `extend`**, e contiene solo i nomi che sono davvero colori di testo (`fg` e varianti,
  `accent`, `critical`, `warning`, `success`, `info`, `shell`, `white`, `transparent`). Le
  superfici restano disponibili come `bg-*`, che non collide con niente.

  **Quando aggiungi un token:** se il nome esiste anche in `fontSize`, non metterlo in
  `textColor`. Se aggiungi un `fontSize` con il nome di una superficie, togli quella
  superficie da `textColor`.
- Tutte le altezze sono in `rem`: dipendono dal `font-size` della radice che imposta
  `useTabletScale`. **Non convertirle in px.**
- `--h-target` 2.25 rem è il minimo per ogni bersaglio **cliccabile**: pulsanti, celle
  "apri", chip su cui si clicca. Un chip statico non è un bersaglio e non deve usarla:
  imporgliela gonfiava le righe di tabella e i pannelli, quindi `Chip` la applica solo
  quando riceve `onClick`.
- I pochi valori arbitrari che restano nei componenti (`0.45rem`, `1.75rem`, `0.18rem`) sono
  misure prese direttamente dal mockup e sono **in rem**: sono ammessi. I px non lo sono.

## Correlati

[web/toolchain.md](../toolchain.md) · [web/index-css.md](../index-css.md) ·
[web/components/Icon.md](../components/Icon.md) ·
`.claude/plans/assets/mockup-casefile-v4.html`

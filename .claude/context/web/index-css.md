# web/src/index.css

**Ruolo:** reset, stili di base, animazioni. Importa font e token.
**Contesto:** UI
**Caricato da:** `web/src/main.tsx`

## Cosa fa

```css
@import './styles/fonts.css';
@import './styles/tokens.css';
@tailwind base;
@tailwind components;
@tailwind utilities;
```

L'ordine conta: i token devono esistere prima che Tailwind generi le utility che li leggono.

## Base

| Selettore | Scelte notevoli |
|---|---|
| `*` | `box-sizing: border-box`, **`outline: none !important`** |
| `html` | `font-size: 16px` come **valore di partenza**, sovrascritto a runtime da `useTabletScale`; `background: transparent` |
| `body` | `height: 100vh`, `overflow: hidden`, **fondo trasparente**, `font-family: var(--font-ui)`, `user-select: none`, antialiasing |
| `#root` | `height: 100%` |
| `input`, `textarea` | `user-select: text` — riabilita la selezione solo dove serve |
| `input[type='range']` | traccia e pollice tematizzati, vedi sotto |

`background: transparent` su `html` e `body` è **obbligatorio**: la NUI è un overlay sul
gioco, un fondo opaco coprirebbe tutto lo schermo invece del solo tablet.

`font-feature-settings: 'cv11', 'ss01'` e `font-variation-settings: 'opsz' 22` sono le
varianti di Inter scelte per il progetto.

## `.num`

```css
.num { font-family: var(--font-numeric); font-variant-numeric: tabular-nums; }
```

È l'**unica eccezione monospace**, e ha una ragione funzionale: le cifre tabellari non
ballano quando i dati cambiano. Si applica a SSN, targhe, importi, date, durate, id.

## Barre di scorrimento

`::-webkit-scrollbar` 0.5 rem, traccia `--bg-inset`, pollice `--line-ctrl` che schiarisce a
`--fg-dim` in hover. Coerenti col telaio invece delle barre di sistema.

## Animazioni

| Classe | Uso |
|---|---|
| `.kf-wave-bar` | istogramma del `RadioDock`, **attiva solo quando qualcuno parla** |
| `.kf-skeleton` | pulsazione dello scheletro di caricamento |
| `.kf-toast` | entrata dei toast |

Sono le uniche tre animazioni del progetto. `kf-wave` usa `transform-origin: bottom` così le
barre crescono dal basso.

## Cursore di scorrimento

`input[type='range']` è l'unico controllo nativo che il progetto ridisegna: `appearance:
none`, traccia 0.4 rem su `--bg-inset` con bordo `--line-inset`, pollice 1 rem su
`--accent`, `opacity: 0.4` quando disabilitato.

Senza questo la parte non riempita della traccia resta **bianca**, il default del browser: in
un tema tutto scuro diventa l'elemento più luminoso della pagina. Lo usa solo il volume in
`RadioPage`.

Sta qui e non nella pagina perché è uno stile di base di un elemento HTML, non un componente.
Attenzione alla specificità: `input[type='range']` (0,1,1) batte una utility Tailwind come
`.h-field` (0,1,0), quindi la geometria la decide questo file — la pagina non deve provare a
imporla con una classe.

## Note e trappole

- `outline: none !important` **rimuove il focus visibile**: è una scelta di aspetto che
  costa accessibilità da tastiera. In una NUI di gioco è accettabile, ma va saputo.
- `font-size: 16px` su `html` è solo il valore iniziale: **tutte** le misure dei componenti
  sono in `rem` e dipendono da quello che `useTabletScale` scrive a runtime. Non scrivere px
  nei componenti.
- `user-select: none` sul body impedisce di copiare testo dal tablet (SSN, targhe). Se serve,
  va aggiunta un'eccezione mirata come quella di `input`.
- Nessun `@font-face` qui: sta in `styles/fonts.css`.

## Correlati

[web/styles/tokens.md](styles/tokens.md) · [web/styles/fonts.md](styles/fonts.md) ·
[web/hooks/useTabletScale.md](hooks/useTabletScale.md) ·
[web/components/RadioDock.md](components/RadioDock.md)

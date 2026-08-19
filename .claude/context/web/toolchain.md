# web — toolchain e configurazione della build

**Deroga documentata a "un `.md` per file":** questo documento copre otto file di
configurazione da 6-100 righe. Un documento a testa sarebbe rumore. Se uno di questi
diventa terreno di lavoro attivo, va splittato.

File coperti: `web/package.json`, `web/vite.config.ts`, `web/tailwind.config.js`,
`web/tsconfig.json`, `web/tsconfig.node.json`, `web/postcss.config.js`,
`web/.eslintrc.cjs`, `web/index.html`, `web/src/vite-env.d.ts`.

---

## `package.json`

React 18 + TypeScript 5 + Vite 5 + Tailwind 3.

| Script | Comando |
|---|---|
| `npm run dev` / `start` | `vite` — sviluppo in browser, con i dati di `lib/mock.ts` |
| `npm run build` | `tsc && vite build` — **il type-check blocca la build** |
| `npm run start:game` | `vite build --watch` |

Dipendenze di runtime: `@fortawesome/*` (icone), `react`, `react-dom`. **Nient'altro.**

I tre residui della vecchia UI sono stati rimossi alla fine di F2, insieme ai file che li
usavano:

- `@uiw/react-md-editor` — pesava circa 700 kB. Serviva a `pages/sections/CreateReport.tsx`
  e `ViewReport.tsx` per un campo di testo: `ReportSheet` usa una `textarea`, perché il
  markdown non veniva comunque reso da nessuno in rilettura.
- `react-spinners` — solo `PuffLoader` nei file legacy. Sostituito da `Skeleton`.
- `react-tooltip` — solo nei file legacy. Sostituito dall'attributo `title`.

Effetto sul bundle: **da 1 047 kB a 327 kB** (gzip 102 kB), e l'avviso di Vite sui chunk
oltre 500 kB non compare più. `lib/mock.ts` resta un chunk separato di 12 kB perché
`callMdt` lo carica con un import dinamico: **non entra nel bundle di produzione**.

> `package-lock.json` è gitignorato (`web/.gitignore`): dopo aver toccato `package.json` va
> rieseguito `npm install` in locale.

## `vite.config.ts`

```ts
plugins: [react(), tailwindcss()]
base: './'            // percorsi relativi: obbligatorio per la NUI
build: { outDir: 'build' }
```

`base: './'` è essenziale: la NUI carica `web/build/index.html` da un percorso di risorsa,
non da una radice web.

`outDir: 'build'` corrisponde a `ui_page 'web/build/index.html'` in `fxmanifest.lua`.

> Nota: `tailwindcss()` come plugin Vite **e** `postcss.config.js` con
> `tailwindcss: {}` sono due modi di attivare Tailwind. Funziona, ma è ridondante.

## `tailwind.config.js`

**Non duplica i valori: legge i token CSS** di `src/styles/tokens.css`. Cambiare un colore
o un raggio si fa in un posto solo.

Estende: `fontFamily` (`ui`, `num`), `colors` (superfici, `fg.*`, accenti, `line.*`),
`borderRadius` (`sm`/`md`/`lg`/`dot`), `spacing` (tutte le altezze e larghezze di struttura
come classi: `h-nav`, `h-row`, `w-sidebar`, `h-target`, ...), `fontSize` (nove gradini da
`micro` 0.7 rem a `section` 1.15 rem).

**Il minimo assoluto è `label` 0.75 rem (12 px)** e vale solo per intestazioni di colonna ed
etichette di gruppo: mai per i dati.

### `textColor` è dichiarato per esteso, e non per gusto

Fuori da `extend`, quindi **sostituisce** il valore che Tailwind ricaverebbe da `colors`.
Contiene solo i nomi che sono davvero colori di testo: `fg.*`, `accent`, `critical`,
`warning`, `success`, `info`, `shell`, `white`, `transparent`, `current`, `inherit`.

Motivo: `tab` e `chrome` esistevano sia in `colors` sia in `fontSize`, e il prefisso `text-`
appartiene a entrambe le scale. `text-tab` generava due regole omonime — un `font-size` e un
`color` — e vinceva il colore, dipingendo il testo con il colore del proprio fondo. Il
racconto completo è in [web/styles/tokens.md](styles/tokens.md).

**Regola:** un nome non può stare in `colors` (usato via `text-`) e in `fontSize` insieme.

Il commento in testa al file ripete la trappola U3/U4: **Tailwind genera solo le classi che
vede come stringhe letterali**. `"bg-" + colore` e `` `w-[${x}px]` `` non producono nulla.

`content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}']`.

## `tsconfig.json`

`target ESNext`, `jsx: react-jsx`, `noEmit: true`, `isolatedModules: true`,
`moduleResolution: Node`.

**`strict: false`** — il progetto non è in strict mode. I file nuovi sono comunque scritti con
tipi espliciti, e non c'è più codice che dipenda da questa indulgenza: i file legacy che ne
avevano bisogno sono stati cancellati in F2. Alzare lo strict mode è ora un cambiamento
possibile, non più bloccato dal legacy.

`noUnusedLocals` e `noUnusedParameters` **non** sono attivi. Vale la pena eseguirli a mano di
tanto in tanto, perché un import morto passa il type-check normale:

```bash
npx tsc --noEmit --noUnusedLocals --noUnusedParameters
```

`include: ["src"]`, riferimento a `tsconfig.node.json` (che copre `vite.config.ts`).

## `postcss.config.js`

`tailwindcss` + `autoprefixer`. Sei righe.

## `.eslintrc.cjs`

`eslint:recommended` + `@typescript-eslint/recommended` + `react-hooks/recommended`, più
`react-refresh/only-export-components` come warning.

`react-hooks/recommended` è la regola che avrebbe segnalato i bug U1 e U2 (listener nel
render, hook condizionali). **Non c'è uno script `lint` in `package.json`**: la
configurazione esiste ma nessuno la esegue in automatico. Si lancia con `npx eslint src`.

## `index.html`

Tredici righe. `<div id="root">` + `<script type="module" src="/src/main.tsx">`.

Due residui del boilerplate: `<title>NUI React Boilerplate</title>` e
`<link rel="icon" href="/src/favicon.svg">`, **file che non esiste** (404 innocuo, la NUI non
mostra favicon).

## `src/vite-env.d.ts`

Una riga: `/// <reference types="vite/client" />`. Serve per i tipi di
`import.meta.env`.

---

## Verifiche

```bash
cd web
npx tsc --noEmit     # 0 errori da F2
npm run build        # ~2 s, bundle 327 kB
npx eslint src       # non c'e' uno script, va lanciato a mano
```

## Correlati

[web/styles/tokens.md](styles/tokens.md) · [fxmanifest.md](../fxmanifest.md) ·
[web/pages/App.md](pages/App.md)

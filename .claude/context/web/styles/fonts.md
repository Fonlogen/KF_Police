# web/src/styles/fonts.css

**Ruolo:** dichiarazione dei font locali. Inter e JetBrains Mono, dentro la risorsa.
**Contesto:** UI
**Caricato da:** `web/src/index.css`

## Perché locali e non da CDN

**La NUI non ha accesso di rete garantito.** Google Fonts non è affidabile e il testo
ricadrebbe su Arial, che rompe tutte le misure del design system.

I quattro `.woff2` stanno in `web/assets/fonts/` e sono dichiarati nei `files` di
`fxmanifest.lua`. Vite li copia anche in `web/build/assets/` con l'hash
(`inter-latin-Dx4kXJAl.woff2`): è l'esito desiderato, e `web/build/assets/**/*` è già nel
manifest.

## I quattro file

| File | Byte | Copertura |
|---|---|---|
| `inter-latin.woff2` | 48 256 | latino base |
| `inter-latin-ext.woff2` | 85 068 | latino esteso |
| `jetbrains-mono-latin.woff2` | 31 432 | latino base |
| `jetbrains-mono-latin-ext.woff2` | 11 624 | latino esteso |

Sono font **variabili**: un solo file copre tutti i pesi
(`font-weight: 100 900` per Inter, `100 800` per JetBrains Mono).

Gli `unicode-range` fanno scaricare `-ext` solo se serve.

## `font-display: block`, non `swap`

Deliberato: nella NUI un ricalcolo di layout a metà apertura del tablet è visibile e
sgradevole. `block` accetta un istante di testo invisibile in cambio di nessun salto.

## Note e trappole

- I percorsi sono `url('../../assets/fonts/inter-latin.woff2')`, relativi a
  `web/src/styles/`. Spostare questo file rompe i percorsi.
- I nomi delle famiglie (`'Inter'`, `'JetBrains Mono'`) devono corrispondere a
  `--font-ui` e `--font-numeric` in `tokens.css`.
- **Nessun font serif e nessuno stack di sistema** nel progetto: il grep di verifica
  `grep -rn "Georgia\|serif\|system-ui"` deve restare essenzialmente vuoto (i ripieghi
  `system-ui, -apple-system, sans-serif` in `--font-ui` sono l'unica occorrenza ammessa, e
  servono solo se il `.woff2` non carica).
- Se aggiungi un font, aggiungilo anche ai `files` di `fxmanifest.lua`.

## Correlati

[web/styles/tokens.md](tokens.md) · [fxmanifest.md](../../fxmanifest.md) ·
[web/index-css.md](../index-css.md)

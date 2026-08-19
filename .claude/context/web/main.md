# web/src/main.tsx

**Ruolo:** punto d'ingresso della NUI.
**Contesto:** UI
**Caricato da:** `web/index.html` (`<script type="module" src="/src/main.tsx">`)

## Cosa fa

Tredici righe:

```tsx
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MdtProvider>
      <App />
    </MdtProvider>
  </React.StrictMode>,
);
```

Più `import './index.css'`, che tira dentro `styles/fonts.css`, `styles/tokens.css` e
Tailwind.

## Perché non c'è più VisibilityProvider

Il vecchio `VisibilityProvider` nascondeva la UI con `visibility: hidden`: **tutti i
componenti restavano montati e in ascolto anche a tablet chiuso**, con i listener attivi e i
timer che girano.

Ora:

- la visibilità la gestisce **`App`**, che non rende nulla quando il tablet è chiuso
  (`if (!visible) return null`);
- **`MdtProvider` resta montato** perché deve continuare a ricevere `mdt:bootstrap`,
  `mdt:counters` e `mdt:invalidate` anche a tablet chiuso.

La divisione è deliberata: il provider ascolta sempre, l'albero visivo esiste solo quando
serve.

## Note e trappole

- `React.StrictMode` in sviluppo monta i componenti **due volte**: gli `useEffect` con
  cleanup corretto lo tollerano, quelli scritti male si vedono subito. È un test gratuito
  contro il bug U1.
- `document.getElementById('root')!` — il `!` assume che l'elemento esista. È in
  `index.html`, quindi è vero.

## Correlati

[web/pages/App.md](pages/App.md) · [web/state/MdtProvider.md](state/MdtProvider.md) ·
[web/index-css.md](index-css.md)

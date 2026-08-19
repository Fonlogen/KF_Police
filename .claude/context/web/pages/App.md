# web/src/pages/App.tsx

**Ruolo:** telaio dell'applicazione: visibilità del tablet, struttura fissa, smistamento
della linguetta attiva sul componente che la disegna.
**Contesto:** UI
**Caricato da:** `web/src/main.tsx`, dentro `MdtProvider`

## Cosa fa

Tre cose, in quest'ordine.

**1. Decide se esistere.** `useNuiEvent('mdt:visible')` accende e spegne uno stato locale; se
il tablet è chiuso il componente ritorna `null` e l'intero albero visivo viene smontato. Non è
`visibility: hidden`: i listener e i timer delle pagine spariscono davvero. Il valore
iniziale è `isBrowser`, così in `npm run dev` il tablet è sempre aperto (il gioco non manda
mai `mdt:visible` a un browser).

**2. Disegna la struttura.** Sempre la stessa, mai condizionale:

```
DeviceFrame
  StatusBar
  div (flex, min-h-0)
    Sidebar
    div (colonna)
      TabStrip
      <vista attiva>   oppure EmptyState se non ci sono linguette
      RadioDock
```

**3. Smista.** `ActiveView` guarda `tab.kind`:

| `tab.kind` | Componente | Chiave passata |
|---|---|---|
| `citizen` | `CitizenSheet` | `identifier = tab.refId` |
| `vehicle` | `VehicleSheet` | `plate = tab.refId` |
| `report` | `ReportSheet` | `reportId = tab.refId` (`'new'` oppure numero), `tabId` |
| `page` | `PAGE_COMPONENTS[tab.pageKey]` | nessuna |

## La mappa `pageKey -> componente` sta qui, non in `registry.ts`

È una scelta deliberata contro un ciclo di import:

```
pagina -> useMdt -> MdtProvider -> registry.ts -> pagina
```

`MdtProvider` importa `registry.ts` per le etichette e le icone delle linguette. Se
`registry.ts` importasse anche i componenti di pagina, e ogni pagina importa `useMdt`, il
ciclo si chiuderebbe. Quindi `registry.ts` resta di **soli metadati** e i componenti si
associano qui, che è una foglia dell'albero degli import.

## API pubblica

`export function App(): JSX.Element | null` e `export default App`. Nessuna prop.

## Dipendenze

`useMdt` (per `ready`, `tabs`, `activeTabId`), `useNuiEvent`, `closeMdt`/`isBrowser` da
`lib/nui`, i cinque componenti di telaio e le undici pagine.

## Note e trappole

- **Solo la linguetta attiva è montata.** Cambiare scheda e tornare indietro rimonta la
  pagina: scorrimento, pagina della tabella e testo cercato ripartono da zero. È il
  compromesso scelto per non tenere in vita undici alberi; se un giorno serve conservare lo
  stato, la strada è tenerlo nel provider, non montare tutte le pagine.
- **ESC.** Il listener è in `useEffect` con cleanup (bug U1) e prima di chiudere controlla
  `document.querySelector('[data-modal="open"]')`: con una modale aperta ESC chiude la modale,
  non il tablet. L'attributo lo mette `Modal`. Non si può risolvere con l'ordine dei listener,
  perché App registra il suo al montaggio e la modale il suo molto dopo: sarebbe App a
  intercettare per prima.
- In browser `closeMdt()` non ha nessuno che risponda, quindi App spegne anche il proprio
  stato a mano. In gioco non lo fa: aspetta il `mdt:visible` del client, che è la fonte di
  verità.
- Gli hook sono **tutti** chiamati prima del `return null`. Spostare l'uscita anticipata più
  in alto romperebbe la regola degli hook.
- `ready` non blocca la struttura: sidebar e barra di stato compaiono subito e si popolano
  quando arriva `mdt:bootstrap`. Solo l'area centrale mostra "Connessione al terminale".

## Correlati

[web/main.md](../main.md) · [web/state/MdtProvider.md](../state/MdtProvider.md) ·
[web/pages/registry.md](registry.md) · [web/components/Modal.md](../components/Modal.md) ·
[web/components/DeviceFrame.md](../components/DeviceFrame.md)

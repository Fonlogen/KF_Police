# web/src/lib/nui.ts

**Ruolo:** il ponte con il client Lua. **Unico canale** verso il gioco.
**Contesto:** UI

## API pubblica

| Funzione | Comportamento |
|---|---|
| `isBrowser()` | `!(window as any).invokeNative` — vero in `npm run dev` |
| `postNui<T>(name, data)` | POST grezzo su `https://<resource>/<name>`; `null` in browser o su errore |
| `callMdt<T>(endpoint, payload)` | **la funzione che usa tutta la UI** |
| `closeMdt()` | `postNui('mdt:close')` |

## `callMdt`

```ts
await callMdt('citizens:search', { query, filter, page, pageSize })
```

- **In browser**: importa dinamicamente `./mock` e risponde con i dati finti. Così
  l'interfaccia si sviluppa e si misura contro il mockup **senza avviare il gioco**.
  L'import è dinamico proprio per non far entrare il mock nel bundle di produzione.
- **In gioco**: `postNui('mdt', { endpoint, payload })` →
  `RegisterNUICallback('mdt')` in `client/cl_nui.lua`.

Se la NUI non risponde ritorna `{ ok: false, error: 'nui_unreachable' }`: **mai
`undefined`**. Chi chiama può sempre testare `response.ok`.

`resourceName()` usa `GetParentResourceName()` con ripiego `'KF_Police'`.

## Perché un solo canale

La UI non chiama endpoint diversi: dichiara l'endpoint come **dato**. Il vantaggio è che
esiste un solo punto dove il server valida giocatore, lavoro, permesso di grado e rate
limit. Vedi [ARCHITECTURE.md](../../ARCHITECTURE.md) §1.

## Note e trappole

- **`callMdt` non lancia mai.** Il `try/catch` in `postNui` inghiotte gli errori di rete. Un
  endpoint che va in errore lato server risponde `{ ok: false, error: 'invalid_data' }`, che è
  indistinguibile da un payload malformato. Il dettaglio è nella console del server.
- Il tipo generico `T extends MdtResponse` è **una promessa, non una verifica**: nessuno
  valida la forma della risposta a runtime. `callMdt<CitizenDossier>(...)` con un server che
  ritorna altro dà `undefined` sui campi, silenziosamente.
- `postNui` è esportata ma usata solo da `callMdt` e `closeMdt`: non serve chiamarla
  direttamente.
- I callback NUI registrati dal client sono **due**: `mdt` e `mdt:close`. Non ce ne sono
  altri.
- `isBrowser()` è la stessa logica di `utils/misc.ts` (`isEnvBrowser`), che è legacy: usare
  questa.

## Correlati

[client/cl_nui.md](../../client/cl_nui.md) · [web/lib/mock.md](mock.md) ·
[web/lib/types.md](types.md) · [ARCHITECTURE.md](../../ARCHITECTURE.md)

# web/src/lib/types.ts

**Ruolo:** tipi TypeScript condivisi con il server. Rispecchiano le risposte degli endpoint.
**Contesto:** UI

## La regola

**Questi tipi sono un contratto scritto a mano.** Se un campo cambia in
`server/sv_*.lua`, va cambiato qui nello stesso commit. Non c'è generazione automatica e
non c'è validazione a runtime: una divergenza si manifesta come `undefined` in interfaccia,
non come errore di compilazione.

## I tipi

### Trasporto

```ts
MdtResponse    { ok, error?, message? }
Paged<T>       extends MdtResponse { rows: T[], total, page, pageSize }
```

Ogni risposta del server è almeno `MdtResponse`. Le liste sono `Paged<T>`.

### Bootstrap

`PageKey` — union delle otto pagine (`citizens` | `vehicles` | `reports` | `penalcode` |
`wanted` | `jail` | `radio` | `duty`). **Deve corrispondere a `Config.EnabledPages` e alle
chiavi di `PAGES` in `registry.ts`.**

`Officer`, `Counters`, `Bootstrap`.

### Dominio

| Tipo | Endpoint di origine |
|---|---|
| `CitizenRow` | `citizens:search` |
| `CitizenDossier` | `citizens:get` |
| `Charge`, `ChargeTotals` | `GetCitizenCharges` |
| `Note` | `GetCitizenNotes` |
| `JailStatus` | `GetJailStatus` |
| `VehicleRow` | `vehicles:search` |
| `VehicleRecord` | `vehicles:get` (con `flags` annidati) |
| `Tag` | `tags:list` |
| `ReportRow`, `ReportDetail`, `ReportInvolved` | `reports:list` / `reports:get` |
| `PenalArticle`, `PenalCategory` | `penalcode:list` |
| `WantedRow` | `wanted:list` |
| `JailRow` | `jail:list` |
| `RosterRow` | `duty:roster` |
| `RadioChannel`, `RadioState` | `radio:state` |

`ReportStatus` = `'draft' | 'open' | 'closed'`, `InvolvedRole` =
`'suspect' | 'victim' | 'witness'`: **stesse liste bianche** di `sv_reports.lua`.

### Messaggi NUI

`Geometry` (schermata `width`/`height`, cornice `frameWidth`/`frameHeight`, `frameInset`
opzionale, risoluzione schermo, `rootFontSize`), `FrameInset` (finestra trasparente della
cornice in frazioni dell'immagine), `GameStatus` (strada, ora, in veicolo),
`InvalidateScope` (otto scope), `InvalidatePayload`.

`frameInset` è **opzionale** perché `client/cl_nui.lua` non lo manda quando
`Config.UI.frame.enabled` è falso: `DeviceFrame` lo usa come discriminante fra "cornice
PNG" e "telaio solo CSS".

`InvalidateScope` deve corrispondere agli scope che `Invalidate()` emette in
`server/sv_main.lua`, e alle chiavi di `EMPTY_REVISION` in `MdtProvider`.

## Note e trappole

- **Il naming è camelCase**, il database è snake_case: la conversione la fa il Lua, non il
  TypeScript. `firstname` in SQL diventa `firstName` qui.
- I campi opzionali (`?`) riflettono i `NULL` del database. Il codice UI usa `?? '-'`
  praticamente ovunque.
- `Paged<T>` non copre i campi extra: `citizens:search` ritorna anche `wantedCount`, che
  `usePagedQuery` raccoglie in `extra: Record<string, unknown>` e la pagina legge con
  `Number(query.extra.wantedCount ?? 0)`. Nessun tipo lo protegge.
- `CitizenDossier.citizen` è `CitizenRow & { height?, jobName?, jobGrade?, wantedBy?,
  wantedAt? }`: l'intersezione riflette che `citizens:get` ritorna più campi di
  `citizens:search`.
- Non c'è un tipo per le risposte dei **callback diretti** (`KF_Police:actions:*`): quelli
  non passano dalla NUI.

## Correlati

[ARCHITECTURE.md](../../ARCHITECTURE.md) §1-§2 · [web/lib/nui.md](nui.md) ·
[web/hooks/usePagedQuery.md](../hooks/usePagedQuery.md)

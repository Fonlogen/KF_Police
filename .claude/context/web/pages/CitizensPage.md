# web/src/pages/CitizensPage.tsx

**Ruolo:** anagrafica cittadini. È **la schermata riprodotta nel mockup approvato**.
**Contesto:** UI
**Caricato da:** `web/src/pages/App.tsx` (`PAGE_COMPONENTS.citizens`)

## Cosa fa

`SheetHeader` con titolo, contatore, filtro segmentato, ricerca e ricarica; poi una
`DataTable` paginata. La ricerca è SQL lato server con debounce di 220 ms: qui non arriva mai
l'elenco completo dei cittadini (bug L4).

## Le proporzioni delle colonne sono vincolanti

Prese da `.claude/plans/assets/mockup-casefile-v4.html`. **Non cambiarle senza aggiornare il
mockup**, che è la specifica visiva approvata.

| Colonna | Chiave | Larghezza | Ordinabile |
|---|---|---|---|
| avatar | `avatar` | `2.75rem` fissa | no |
| Nome | `firstname` | `flex 1.15` | sì |
| Cognome | `lastname` | `flex 1.4` | sì |
| Cittadinanza | `nationality` | `flex 1` | sì |
| Impiego | `job` | `flex 1.3` | sì |
| Apri | `open` | `3.5rem` fissa | no |

Le chiavi ordinabili **sono i nomi della lista bianca di `server/sv_citizens.lua`**
(`firstname`, `lastname`, `nationality`, `job`, `ssn`). Non sono nomi liberi: il server
rifiuta tutto il resto, ed è così che la NUI non può iniettare un `ORDER BY` arbitrario.

Nella colonna Cognome compaiono i timbri `RICERCATO` (critical) e `DETENUTO` (warning), come
nel mockup.

## Endpoint

`citizens:search` con `{ query, filter, sortBy, sortDir, page, pageSize }`.

Filtri: `all` (nessun filtro), `wanted`, `jailed`. Il server ignora `all`, che non è nella sua
lista.

Risposta: `rows`, `total`, `page`, `pageSize` e l'extra **`wantedCount`**, usato per il
contatore "8 - 1 ricercato" dell'intestazione.

## Invalidazioni

`useRevisionEffect([revision.citizen, revision.wanted, revision.jail], query.reload)`.

Osserva `citizen` al **singolare**: è quello che il server emette. `revision.citizens` esiste
nei tipi ma nessuno lo incrementa.

## Note e trappole

- Il pulsante icona dell'intestazione è **ricarica**, non "aggiungi". Nel mockup c'è un `+`,
  ma un cittadino non si crea dal MDT: nasce dal framework. Stessa geometria (2.3 rem), azione
  che esiste davvero. Il `+` per il nuovo rapporto sta nella `TabStrip`.
- Cliccare la riga o la cella "apri" fa la stessa cosa. `OpenCell` fa `stopPropagation`, così
  il click non conta due volte.
- `pageSize` arriva dal provider (`Config.PageSize` del server), non è scritto qui.

## Correlati

[web/pages/CitizenSheet.md](CitizenSheet.md) ·
[web/components/DataTable.md](../components/DataTable.md) ·
[web/hooks/usePagedQuery.md](../hooks/usePagedQuery.md) ·
[server/sv_citizens.md](../../server/sv_citizens.md)

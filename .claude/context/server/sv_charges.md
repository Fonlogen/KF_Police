# server/sv_charges.lua

**Ruolo:** reati. Aggiunta **multipla e transazionale**, annullamento tracciato, pagamento.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_citizens.lua`

## I bug corretti qui

### L2 — il blob riscritto

Prima ogni reato veniva aggiunto **riscrivendo l'intero blob JSON `criminalRecords`** del
cittadino: due agenti che lavoravano sullo stesso fascicolo nello stesso momento si
annullavano a vicenda (last-write-wins). Ora ogni reato è **una riga** con id da
AUTO_INCREMENT, inserita in transazione: due aggiunte contemporanee restano entrambe.

### L10 — la multa dalla regex

La multa non viene più riestratta con una regex da una stringa formattata: si leggono i
campi numerici `fine` e `jail_months` dell'articolo.

## Endpoint

### `charges:add` — `mdt.charge.add`

Payload: `identifier`, **`penalcodeIds[]`**, `crime` (reato libero), `fine`, `jailMonths`,
`location`, `victim`, `reportId`.

Flusso:

1. il cittadino esiste in `users` → altrimenti `citizen_not_found`;
2. gli id vengono normalizzati; **le ripetizioni sono conservate** (contestare due volte
   lo stesso articolo è legittimo), ma la lettura degli articoli usa l'insieme unico;
3. `fetchArticles(ids)` legge tutti gli articoli in **una sola query** con `IN (?, ?, ...)`;
4. se il `victim` non esiste in `users` viene scartato (non fa fallire la chiamata);
5. una `INSERT` per reato viene accodata; il reato libero (senza articolo) è ammesso solo
   con testo esplicito;
6. `Database.Transaction(statements)` — o tutti o nessuno;
7. `Logger.Audit`, `Invalidate('citizen', identifier)`, `PushCounters()`.

Ritorna `added`, `charges`, `totals` e un messaggio singolare/plurale
(`charge_added` / `charges_added` con `%d`).

**Per gli articoli i valori economici vengono dall'articolo, non dal payload.** Solo il
reato libero accetta `fine` e `jailMonths` dal client, con `ClampInt` a 1 000 000 e 10 000.

### `charges:void` — `mdt.charge.void`

Non cancella: imposta `voided_at`, `voided_by`, `void_reason`. L'`UPDATE` ha
`AND voided_at IS NULL`, quindi due annullamenti contemporanei: il secondo trova 0 righe
modificate e risponde `charge_already_voided`.

Lo storico non deve cambiare: un reato annullato resta nel fascicolo, barrato, e non
conta nei totali.

### `charges:markPaid` — `mdt.fine.issue`

Imposta `is_paid = 1` su un reato non annullato.

## Note e trappole

- `fetchArticles` costruisce i placeholder dinamicamente: gli id sono già passati da
  `tonumber` e filtrati `> 0`, quindi non c'è iniezione. Il numero di id non è limitato:
  una selezione enorme produce una query enorme. `Config.RateLimit.MaxWrites` è l'unica
  protezione.
- **Un id inesistente viene silenziosamente ignorato** (`articles[id]` nil). Se tutti gli
  id sono inesistenti e non c'è reato libero, `added == 0` → `charge_add_failed`.
- `charges:markPaid` **non incassa nulla**: segna solo il flag. Il pagamento vero passa da
  `sv_fines.lua`.
- `report_id` non è validato: si può collegare un reato a un rapporto inesistente. La
  `FOREIGN KEY` non c'è.
- La risposta include già `charges` e `totals` aggiornati: la UI non deve rifare
  `citizens:get` dopo un'aggiunta.

## Correlati

[server/sv_citizens.md](sv_citizens.md) · [server/sv_penalcode.md](sv_penalcode.md) ·
[web/pages/CitizenSheet.md](../web/pages/CitizenSheet.md)

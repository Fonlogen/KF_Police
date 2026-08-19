# web/src/hooks/useRevisionEffect.ts

**Ruolo:** ricarica mirata di una singola vista quando il server invalida uno scope.
**Contesto:** UI
**Caricato da:** ogni pagina che mostra dati del server

## Cosa fa

```ts
useRevisionEffect([revision.citizen, revision.wanted], query.reload);
```

Osserva uno o più contatori di `revision` del provider ed esegue la funzione quando **uno di
essi cambia**. Il primo render è escluso di proposito.

È la metà UI della correzione del bug **L4**. Prima il server, a ogni modifica, ritrasmetteva
l'intero database a tutti i client e la UI ricostruiva tutto. Ora il server manda solo
`mdt:invalidate { scope }`, il provider incrementa `revision[scope]`, e ogni pagina decide da
sé se quel cambiamento la riguarda.

## API pubblica

`useRevisionEffect(revisions: number[], run: () => void): void`

## Come è implementato, e perché così

- `revisions.join(':')` come dipendenza dell'effetto: sono numeri, quindi la stringa unita è
  un **confronto per valore**. Passare l'array come dipendenza non funzionerebbe, perché un
  array nuovo a ogni render fa scattare l'effetto ogni volta.
- `run` passa da una `useRef` aggiornata in un effetto separato: così una funzione ricreata a
  ogni render (il caso normale) non ri-registra nulla e non serve che il chiamante la
  memoizzi.
- `mounted` (una `useRef`) salta la prima esecuzione: il caricamento iniziale lo fa già
  `usePagedQuery` o l'effetto di caricamento della scheda. Senza questa guardia ogni pagina
  chiederebbe **due volte** la stessa cosa all'apertura.

## Quali scope esistono

Solo questi, ed è il server che li emette (`Invalidate(scope, id)` in `server/sv_main.lua`):
`citizen`, `jail`, `penalcode`, `reports`, `roster`, `vehicles`, `wanted`.

`citizens` (al plurale) è dichiarato nei tipi ma **nessuno lo emette**: le modifiche a un
singolo cittadino arrivano come `citizen`. Per questo `CitizensPage` osserva
`[revision.citizen, revision.wanted, revision.jail]` e non `revision.citizens`. Chi aggiunge
una pagina lo controlli, altrimenti scrive una ricarica che non scatterà mai.

## Note e trappole

- **L'`id` dell'invalidazione non arriva qui.** `revision` è un contatore per scope, non per
  record: se cambia un cittadino qualunque, ogni scheda cittadino aperta si ricarica. È
  accettabile (una query, non un broadcast) ma va saputo.
- `ReportSheet` non ricarica alla cieca: se ci sono modifiche locali non salvate ignora
  l'invalidazione, per non sovrascrivere quello che l'agente sta scrivendo.
- Non usarlo per il caricamento iniziale: salta il primo render, quindi non farebbe nulla.

## Correlati

[web/state/MdtProvider.md](../state/MdtProvider.md) ·
[web/hooks/usePagedQuery.md](usePagedQuery.md) · [server/sv_main.md](../../server/sv_main.md) ·
[ARCHITECTURE.md](../../ARCHITECTURE.md)

# server/sv_wanted.lua

**Ruolo:** elenco e gestione dei ricercati. **Correzione del bug L7.**
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_notes.lua`

## Il bug L7

`RefreshWantedList` rigenerava gli id **per indice di iterazione**: l'id di una voce
cambiava tra due refresh e la UI apriva il fascicolo sbagliato. Qui l'elenco è una query su
`kf_police_profiles` e l'identificativo di una voce è l'**`identifier` del cittadino**, che
non cambia mai.

## Endpoint

### `wanted:list` — `mdt.citizen.view`

Paginato. `WHERE p.is_wanted = 1` con `INNER JOIN users`: un profilo ricercato il cui
utente è stato cancellato non compare.

La ricerca copre `firstname`, `lastname`, `ssn` e **`wanted_reason`**.

Ordinamento fisso: `p.wanted_at DESC, u.lastname ASC` — i più recenti in cima. Nessun
ordinamento per colonna.

Ogni riga porta anche `chargeCount`, una sottoquery che conta i reati non annullati.

### `wanted:set` — `mdt.wanted.set`

Payload: `identifier`, `wanted` (bool), `reason`.

- l'utente deve esistere in `users` → altrimenti `citizen_not_found`;
- `EnsureProfile` crea il profilo se manca;
- **attivazione**: `is_wanted = 1`, `wanted_reason` (ripiego `'Ricercato'` se vuoto),
  `wanted_by_id`, `wanted_by_name`, `wanted_at = NOW()`;
- **revoca**: azzera tutti quei campi, `wanted_at` compreso.

Poi `Invalidate('citizen', identifier)`, `Invalidate('wanted')` e `PushCounters()`: si
aggiornano il fascicolo aperto, la pagina Ricercati e il badge della sidebar.

## Note e trappole

- Il permesso `mdt.wanted.set` è di grado `sergeant`+: un `officer` che ha
  `mdt.charge.add` non può segnalare un ricercato.
- La revoca **cancella il motivo**: non resta storico dello stato di ricerca precedente in
  `kf_police_profiles`. Lo storico è solo in `kf_police_audit`
  (`wanted.set` / `wanted.clear`).
- `wanted_by_name` è il nome dell'agente al momento della segnalazione, non un riferimento:
  se l'agente cambia nome, la vecchia segnalazione mostra il nome vecchio. È voluto.
- La sottoquery `chargeCount` gira una volta per riga: su una pagina da 25 sono 25
  sottoquery. Accettabile a queste dimensioni.
- `CitizensPage` con `filter = 'wanted'` usa `citizens:search`, **non** questo endpoint:
  sono due viste diverse degli stessi dati. La pagina Ricercati dedicata (`WantedPage`)
  non è ancora scritta.

## Correlati

[server/sv_citizens.md](sv_citizens.md) · [server/sv_main.md](sv_main.md) ·
[web/pages/MANCANTI.md](../web/pages/MANCANTI.md)

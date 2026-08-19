# server/sv_fines.lua

**Ruolo:** sanzioni. Motore generico che invoca l'adapter di fatturazione disponibile.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_jail.lua`

## Cosa fa

Gli adapter sono descritti in `config/cfg_banking.lua` **per nome di argomento** e risolti
qui a runtime: aggiungere un banking nuovo non richiede codice.

### Il motore

| Funzione locale | Ruolo |
|---|---|
| `resolveArg(token, ctx)` | traduce un nome di argomento nel valore; un token non riconosciuto passa **letteralmente** |
| `buildArgs(spec, ctx)` | costruisce la lista posizionale |
| `hasRequiredArgs(spec, ctx)` | falso se un token riconosciuto risolve a `nil` → l'adapter viene **saltato** |
| `callExport(exportCfg, ctx)` | invoca l'export |
| `fireEvent(eventCfg, ctx)` | `TriggerEvent` o `TriggerClientEvent` |

`hasRequiredArgs` è ciò che rende sicuro avere nove adapter: quelli che vogliono
`targetSource` (destinatario online) vengono ignorati se il destinatario è offline, e si
passa al successivo.

### Il colon-call

Gli export sono invocati passando **`self` esplicitamente**:

```lua
handle[exportCfg.name](handle, table.unpack(args, 1, argc))
```

che equivale al colon-call richiesto da FiveM. Stessa causa del bug L1 documentato in
[voice-cl_pma](../modules/voice-cl_pma.md). Un adapter che richiede la forma senza self può
dichiarare `method = false` nella configurazione.

## API pubblica

### `IssueFine(officer, targetIdentifier, amount, label)` → boolean

`ClampInt(amount, 1, 10000000, 0)`, costruisce il contesto (con `targetSource` se il
destinatario è online), poi **itera gli adapter in ordine** e usa il primo la cui risorsa è
`started` e la cui chiamata riesce. Prima l'`export`, poi l'`event` come ripiego.

Se nessuno funziona: `Logger.Warn` e `false`.

## Endpoint

### `fines:issue` — `mdt.fine.issue`

Verifica importo e esistenza del cittadino, poi:

1. `IssueFine(...)` → se falso, `fine_failed`;
2. **solo se la fatturazione è riuscita**, inserisce una riga in `kf_police_charges` con
   `fine = amount` e `jail_months = 0`: la sanzione resta anche nel fascicolo, come reato
   pecuniario;
3. audit e `Invalidate('citizen', identifier)`.

### `fines:list` — `mdt.view`

Multe non pagate (o tutte con `onlyUnpaid = false`), filtrabili per `identifier`. Solo reati
non annullati con `fine > 0`. Limite fisso 200 righe. Ritorna anche `amount`, la somma.

Sostituisce il pannello sanzioni di `esx_policejob`.

## Note e trappole

- **Se la fatturazione fallisce, la multa non viene registrata da nessuna parte.**
  L'inserimento nel fascicolo avviene solo dopo il successo. È voluto (non si vuole un
  reato pecuniario senza fattura), ma significa che senza una risorsa di banking l'endpoint
  è inutilizzabile.
- Non c'è modo di forzare un adapter specifico: si riordina la lista in
  `cfg_banking.lua`.
- `fines:list` **non è paginato** ma ha un `LIMIT 200`: con più multe le più vecchie non
  compaiono e non c'è modo di raggiungerle.
- La riga in `kf_police_charges` creata qui ha `penalcode_id` nullo: la sanzione non è
  legata a un articolo del codice penale.
- `charges:markPaid` (in `sv_charges.lua`) segna il flag `is_paid`, ma **non incassa
  nulla**: l'incasso è responsabilità della risorsa di banking.

## Correlati

[config/cfg_banking.md](../config/cfg_banking.md) ·
[server/sv_charges.md](sv_charges.md) ·
[modules/voice-cl_pma.md](../modules/voice-cl_pma.md)

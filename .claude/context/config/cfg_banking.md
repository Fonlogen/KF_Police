# config/cfg_banking.lua

**Ruolo:** adapter di fatturazione per le sanzioni. Nove risorse di banking supportate
senza scrivere codice.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

Il primo adapter la cui risorsa risulta `started` viene usato: **l'ordine della lista è
la priorità**. Gli argomenti sono descritti **per nome** e risolti a runtime da
`server/sv_fines.lua`, così aggiungere un banking nuovo è una voce di configurazione.

### Contesto condiviso

| Chiave | Valore |
|---|---|
| `Enabled` | `true` |
| `FallbackLabel` | `'Sanzione polizia'` |
| `Society` | `'society_police'` |
| `SocietyLabel` | `'LSPD'` |
| `AccountType` | `'bank'` |
| `Reason` | `'police_fine'` |

### Token risolvibili negli `args`

`targetSource`, `targetIdentifier`, `officerSource`, `officerIdentifier`, `amount`,
`label`, `society`, `societyLabel`, `reason`, `accountType`, `withdraw`.

Un token che non è in questo elenco viene passato **letteralmente**. Se un token
riconosciuto risolve a `nil`, l'adapter viene **saltato** (`hasRequiredArgs`): per esempio
un adapter che vuole `targetSource` non viene usato se il destinatario è offline.

### Adapter, in ordine di priorità

| Nome | Meccanismo |
|---|---|
| `esx_billing` | export `BillPlayerByIdentifier` |
| `okokBilling` | export `CreateCustomInvoice` (richiede `targetSource`) |
| `okokBanking` | export `AddTransaction`, con evento di ripiego |
| `qb-banking` | export `CreateFine` (richiede `targetSource`) |
| `Renewed-Banking` | export `handleTransaction` |
| `fd_banking` | export `AddTransaction` |
| `tgg-banking` | export `AddTransaction` |
| `codem-bank` | solo evento server |
| `qs-banking` | export `AddTransaction` |

Se un adapter ha sia `export` che `event`, si prova prima l'export; l'evento è il ripiego.

### Compatibilità storica

`Config.UseBilling = true` e `Config.BillingSociety` restano per i riferimenti vecchi.

## Note e trappole

- Gli export sono invocati passando **`self` esplicitamente**
  (`handle[name](handle, ...)`), che equivale al colon-call richiesto da FiveM. È la
  stessa causa del bug L1: senza il self l'export riceve `nil` come primo argomento.
  Un adapter che richiede la forma senza self può dichiarare `method = false`.
- Se nessun adapter è disponibile, `IssueFine` ritorna `false` e l'endpoint
  `fines:issue` risponde `fine_failed`: **la multa non viene registrata nemmeno nel
  fascicolo**, perché l'inserimento in `kf_police_charges` avviene solo dopo il successo
  della fatturazione.
- Non c'è modo di forzare un adapter specifico: si riordina la lista.

## Correlati

[server/sv_fines.md](../server/sv_fines.md) ·
[modules/framework-sv_esx.md](../modules/framework-sv_esx.md)

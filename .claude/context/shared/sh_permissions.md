# shared/sh_permissions.lua

**Ruolo:** fonte unica di verità dei permessi per grado. Girato sia sul client sia sul
server.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `sh_utils.lua`

## Cosa fa

Definisce `Config.Permissions` (mappa `lavoro → grado → lista di permessi`) e le funzioni
per risolverla.

Lo **stesso file** gira su client e server:

- il **client** lo usa per non mostrare voci di menu inutili (`cl_actions_*`,
  `cl_cloakroom`, i `canInteract` delle zone target, la sidebar della NUI);
- il **server** lo usa per **rifiutare** in `RequirePermission`.

Il controllo autorevole è sempre e solo quello del server. Il client filtra per
cortesia, non per sicurezza.

## Sintassi

`'@N'` in una lista **eredita** tutti i permessi del grado N dello stesso lavoro.
Serve a non riscrivere l'elenco a ogni grado.

```lua
[2] = { '@1', 'mdt.wanted.set', ... }   -- sergeant = officer + queste
```

## API pubblica

| Funzione | Ritorna |
|---|---|
| `ResolvePermissions(jobName, grade)` | `table<string, boolean>`, con cache per `job:grade` |
| `HasPermission(jobName, grade, permission)` | boolean; **vero** se `permission` è `nil` o `''` |
| `PermissionList(jobName, grade)` | array ordinato, pronto per la NUI (`bootstrap`) |

`ResolvePermissions` ha una protezione contro le ereditarietà circolari (`visiting`): un
`@` che punta a se stesso non manda in stack overflow, semplicemente si ferma.

## Gradi

### `police` (corrispondono a `job_grades`)

| N | Nome | Aggiunge |
|---|---|---|
| 0 | `recruit` | `mdt.view`, `mdt.citizen.view`, `mdt.vehicle.view`, `mdt.report.create`, `mdt.report.edit`, `mdt.note.create`, `mdt.jail.view`, `duty.toggle`, `cloakroom.use`, `armory.use`, `garage.use`, `radio.use`, `field.identify`, `objects.place` |
| 1 | `officer` | `mdt.charge.add`, `mdt.vehicle.flag`, `field.cuff`, `field.search`, `field.lockpick`, `jail.send` |
| 2 | `sergeant` | `mdt.wanted.set`, `mdt.note.delete`, `field.impound`, `field.fine`, `field.license`, `mdt.fine.issue` |
| 3 | `lieutenant` | `mdt.charge.void`, `mdt.report.delete`, `jail.release`, `mdt.roster.view` |
| 4 | `boss` (Captain) | `mdt.penalcode.edit`, `mdt.tag.edit`, `mdt.audit.view`, `armory.buy`, `society.boss` |

### `ambulance`

Consulta il MDT ma non opera sui fascicoli: `mdt.view`, `mdt.citizen.view`,
`mdt.vehicle.view`, `mdt.note.create`, `radio.use`, `duty.toggle`. Grado 2 aggiunge
`mdt.report.create`, grado 4 `mdt.roster.view`.

## `Config.WritePermissions`

Marca i permessi che implicano scrittura. Serve a due cose in
`server/sv_permissions.lua`: contatore separato del rate limit (`MaxWrites`) e
classificazione nell'audit.

Se aggiungi un permesso di scrittura e **dimentichi di metterlo qui**, il rate limit lo
conta solo come lettura: nessun errore visibile, protezione più debole.

## Note e trappole

- `HasPermission(..., nil)` è **vero**: gli endpoint senza permesso dichiarato passano
  comunque dalla validazione di giocatore, lavoro e rate limit, ma non filtrano per grado.
- La cache non viene mai invalidata. Modificare `Config.Permissions` a runtime non ha
  effetto sui gradi già risolti: serve un restart della risorsa.
- Un lavoro **non presente** in `Config.Permissions` ottiene `{}`, cioè zero permessi,
  anche se è in `Config.AllowedJobs`. Le due liste vanno tenute allineate.
- Il permesso `mdt.audit.view` è dichiarato e assegnato al `boss`, ma **nessun endpoint lo
  usa ancora**: `Logger.List` esiste in `sv_logger.lua` senza un endpoint che la esponga.

## Correlati

[ARCHITECTURE.md](../ARCHITECTURE.md) §4 · [server/sv_permissions.md](../server/sv_permissions.md) ·
[config/config.md](../config/config.md)

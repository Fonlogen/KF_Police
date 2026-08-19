# modules/framework/sv_esx.lua

**Ruolo:** implementazione ESX del bridge framework, lato server. Include i conti società.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, **primo** dei `server_scripts` dopo oxmysql
**Attivo se:** `Config.Framework == 'esx'`

## Cosa fa

Implementa il contratto server di [sh_bridge](framework-sh_bridge.md) sopra `xPlayer` di
ESX, e aggiunge l'accesso ai conti società via `esx_addonaccount`.

## API pubblica

### Giocatori

| Funzione | Note |
|---|---|
| `GetPlayer(src)` | `ESX.GetPlayerFromId` |
| `GetPlayerFromIdentifier(id)` | usa `ESX.GetPlayerFromIdentifier` se esiste, altrimenti scorre gli online |
| `GetIdentifier(player)` | accetta anche una stringa (la ritorna) |
| `GetName(player)` | `firstName + lastName`, ripiego su `getName()`, poi `GetPlayerName(source)`, infine `'Sconosciuto'` |
| `GetJob(player)` | 4 valori; senza lavoro → `nil, 0, 'recruit', ''` |
| `GetSsn(player)` | `player.getSSN()` in `pcall`, ripiego su `identifier` |
| `GetSex(player)` | `'female'` per `f`/`F`/`female` |
| `GetOnlinePlayers()` | `ESX.GetExtendedPlayers()`, con ripiego che itera `ESX.GetPlayers()` |
| `Notify(src, msg, type)` | `TriggerClientEvent('KF_Police:Client:Notify', ...)` |
| `RegisterUsableItem(item, cb)` | in `pcall`: un item inesistente non blocca l'avvio |

### Denaro

| Funzione | Comportamento |
|---|---|
| `AddAccountMoney(player, account, amount)` | `pcall` su `addAccountMoney` |
| `RemoveAccountMoney(player, account, amount)` | **verifica il saldo prima**: ritorna `false` se insufficiente |
| `GetSocietyAccount(society)` | `nil` se `esx_addonaccount` non è `started` |
| `RemoveSocietyMoney(society, amount)` | vero solo se il denaro c'era davvero; `amount <= 0` → vero |
| `AddSocietyMoney(society, amount)` | |

`GetSocietyAccount` usa `TriggerEvent('esx_addonaccount:getSharedAccount', ...)` con una
callback sincrona: funziona perché quell'evento risponde nello stesso tick.

## Chi lo usa

- `server/sv_permissions.lua` — `GetPlayer`, `GetJob`, `GetName`, `GetSsn`
- `server/sv_armory.lua` — `RemoveSocietyMoney`, `RemoveAccountMoney`
- `server/sv_garage.lua` — `RemoveSocietyMoney`
- `server/sv_jail.lua`, `sv_actions.lua`, `sv_fines.lua` — `GetPlayerFromIdentifier`, `Notify`
- `server/sv_main.lua` — `RegisterUsableItem`, `GetOnlinePlayers`
- `server/sv_duty.lua` — `GetOnlinePlayers`, `GetPlayerFromIdentifier`

## Note e trappole

- **`RemoveSocietyMoney` ritorna `true` quando `amount <= 0`.** È voluto: un veicolo o un
  item gratuito non deve essere bloccato dall'assenza di `esx_addonaccount`. Ma significa
  che un chiamante non distingue "gratis" da "pagato".
- Se `esx_addonaccount` non è avviato, **ogni acquisto a pagamento fallisce**
  (`GetSocietyAccount` → `nil` → `false`). L'armeria risponde `armory_no_money`, che è
  fuorviante: il problema è la risorsa mancante, non il saldo.
- `GetName` non è mai `nil`: gli endpoint possono scriverlo direttamente in
  `officer_name` senza controlli.
- `GetSsn` **non** garantisce un SSN reale: il ripiego è l'`identifier`. `sv_citizens.lua`
  legge `users.ssn` direttamente dal database quando gli serve quello vero.

## Correlati

[modules/framework-sh_bridge.md](framework-sh_bridge.md) ·
[config/cfg_banking.md](../config/cfg_banking.md) ·
[server/sv_permissions.md](../server/sv_permissions.md)

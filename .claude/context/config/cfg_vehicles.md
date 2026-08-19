# config/cfg_vehicles.lua

**Ruolo:** veicoli di servizio per categoria e grado, targhe LSPD.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

**Nessuna dipendenza da `esx_vehicleshop`** (su questo server è in `[disabled]`, per cui
il garage di `esx_policejob` era di fatto rotto): i veicoli sono spawnati direttamente
dal garage con `CreateVehicleServerSetter`, targati `LSPD` + numero, e **non finiscono in
`owned_vehicles`**. Sono mezzi di reparto, non beni del personaggio.

### `Config.Garage`

| Chiave | Valore | Effetto |
|---|---|---|
| `PlatePrefix` | `'LSPD'` | targa `LSPD NNN`, contatore modulo 1000 in `sv_garage.lua` |
| `OneVehiclePerOfficer` | `true` | un solo veicolo attivo per `identifier` |
| `DespawnOnDuty` | `true` | il veicolo sparisce a fine servizio o disconnessione |
| `SpawnFullFuel` | `true` | carburante 100, motore e carrozzeria a 1000 |
| `DefaultProps` | `{ modLivery = 0 }` | livrea applicata a tutti |

### `Config.AuthorizedVehicles`

Struttura a due livelli: `categoria → nomeGrado → lista`. Ogni voce
`{ model, label, price, props? }`.

- **`car`**: `recruit` solo `police` (Cruiser); `officer` aggiunge `police3`;
  `sergeant` aggiunge `policet` e `policeb`; `lieutenant` e `boss` aggiungono `riot` e
  `fbi2`.
- **`helicopter`**: vuoto fino a `lieutenant`, che ottiene `polmav`.

`price = 0` significa gratuito (di servizio). Un prezzo `> 0` viene scalato dal conto
società tramite `Framework.RemoveSocietyMoney` in `sv_garage.lua`: se il conto non ha i
fondi lo spawn viene rifiutato.

## Note e trappole

- La categoria arriva dal **garage** (`cfg_stations.lua` → `garages[n].category`), non
  dal client: chi chiede un `polmav` dal garage auto non lo ottiene.
- `sv_garage.lua` rivalida che il modello sia fra quelli autorizzati per il grado: il
  payload del client non è attendibile.
- `props` per voce sovrascrive `DefaultProps`. Oggi solo `modLivery` viene applicata dal
  client (`cl_garage.lua`): aggiungere altri mod richiede di estendere quel `for`.
- Le chiavi di grado devono corrispondere ai `name` in `job_grades`, come in
  `cfg_duty.lua` e `cfg_armory.lua`.

## Correlati

[server/sv_garage.md](../server/sv_garage.md) ·
[client/cl_garage.md](../client/cl_garage.md) ·
[config/cfg_stations.md](cfg_stations.md)

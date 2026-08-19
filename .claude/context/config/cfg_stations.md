# config/cfg_stations.lua

**Ruolo:** stazioni, punti di interazione, blip. Ogni punto viene registrato dal bridge
`modules/target`.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `config/config.lua`

## Cosa fa

Definisce `Config.Stations`, una mappa `chiave → stazione`. Oggi ne esiste una: `LSPD`
(Mission Row).

Ogni stazione può avere:

| Campo | Tipo | Consumato da |
|---|---|---|
| `label` | string | `client/cl_main.lua` (nome del blip) |
| `blip` | `{ coords, sprite, display, scale, colour }` | `client/cl_main.lua` |
| `cloakrooms` | lista di `vector3` | `client/cl_cloakroom.lua` |
| `armories` | lista di `vector3` | `client/cl_armory.lua` |
| `garages` | lista di `{ spawner, category, spawnPoints }` | `client/cl_garage.lua` |
| `vehicleReturns` | lista di `{ coords, radius }` | `client/cl_garage.lua` |
| `bossActions` | lista di `vector3` | `client/cl_boss.lua` |
| `impound` | `{ retrieve, spawn }` | `client/cl_impound.lua` |

I garage hanno una `category` (`car`, `helicopter`) che seleziona il ramo corrispondente
di `Config.AuthorizedVehicles` in `cfg_vehicles.lua`. Gli `spawnPoints` sono provati in
ordine: il primo libero vince.

## Altre chiavi

- **`Config.Marker`** — configurazione del ripiego a marker: `drawDistance 10.0`, tipo
  per categoria (`cloakroom 20`, `armory 21`, `boss 22`, `garage 36`, `jail 21`),
  dimensione, colore rosso LSPD. Letta solo da `modules/target/cl_marker.lua`.
- **`Config.TargetRadius = 1.2`** — raggio delle sfere `ox_target`.
- **`Config.ColleagueBlips`** — blip dei colleghi: abilitati, solo in servizio, refresh
  5 s, sprite/colore/scala. Letta da `client/cl_blips.lua`.

## Note e trappole

- I file client iterano `pairs(Config.Stations)` e registrano una zona per ogni voce:
  aggiungere una stazione non richiede codice, solo la voce qui.
- Il nome della zona è costruito come `kf_police_<funzione>_<chiaveStazione>_<indice>`.
  Deve restare univoco, altrimenti `Target.AddZone` sovrascrive la precedente.
- Le coordinate del **carcere** non sono qui: stanno in `config/cfg_jail.lua`.
- Le coordinate dell'impound (`408.6, -1637.0`) sono il deposito standard di Davis, non
  la stazione: è voluto.

## Correlati

[modules/target-cl_ox.md](../modules/target-cl_ox.md) ·
[modules/target-cl_marker.md](../modules/target-cl_marker.md) ·
[config/cfg_vehicles.md](cfg_vehicles.md)

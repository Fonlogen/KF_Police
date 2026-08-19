# client/cl_garage.lua

**Ruolo:** prelievo e riconsegna dei veicoli di servizio.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_armory.lua`

## Cosa fa

Il veicolo è creato **dal server** (`CreateVehicleServerSetter`): il client scegli solo il
modello e trova un punto di spawn libero. Nessun riferimento a `esx_vehicleshop`.

Registra due tipi di zona per stazione:

- **spawner** (`garages[n].spawner`, permesso `garage.use`, richiede il servizio) — apre il
  menu dei veicoli disponibili per la categoria del garage;
- **riconsegna** (`vehicleReturns[n]`, raggio proprio) — riconsegna il veicolo su cui si è
  seduti o quello più vicino entro 5 m.

## Flusso di spawn

1. `freeSpawnPoint(garage)` — prova gli `spawnPoints` in ordine e prende il primo dove
   `lib.getClosestVehicle(point.coords, 2.5)` non trova nulla. Se nessuno è libero:
   `garage_no_space`.
2. `KF_Police:garage:spawn` con modello, categoria, coordinate e heading.
3. Attende fino a 5 s che l'entità esista **anche in locale**
   (`NetworkGetEntityFromNetworkId`).
4. Configura: targa, `SetVehicleHasBeenOwnedByPlayer`, `SetEntityAsMissionEntity`,
   carburante/salute se `SpawnFullFuel`, `SetVehicleLivery` per `modLivery`.
5. Registra `activeVehicle` locale e mette il giocatore al posto di guida.

## Riconsegna

`storeVehicle()` prende il veicolo su cui si è seduti, o `GetNearestVehicle(5.0)`, e manda
il `netId` a `KF_Police:garage:store`. Il server rifiuta se il `netId` non corrisponde a
quello prelevato da quell'agente.

`KF_Police:Client:DespawnServiceVehicle` (dal server, a fine servizio) chiama
`TriggerServerEvent('KF_Police:Server:DespawnServiceVehicle')` e azzera lo stato locale.

## Note e trappole

- **Il `for` sui `props` gestisce solo `modLivery`.** Altri mod nella configurazione
  vengono ignorati silenziosamente. Estendere quel ciclo per supportarli.
- `activeVehicle` locale può divergere da `activeVehicles` del server (es. se il veicolo
  viene distrutto): il server è la fonte di verità, il client lo usa solo per non mandare
  un despawn inutile.
- L'attesa dei 5 s è **doppia** (una lato server, una qui): entrambe necessarie, perché
  l'entità esiste sul server prima che il client la riceva via rete.
- `freeSpawnPoint` usa 2.5 m di raggio: due punti di spawn più vicini di così si
  considerano a vicenda occupati.
- Il controllo "in servizio" è nel `canInteract` della zona **e** nel server: il client
  nasconde l'opzione, il server rifiuta.

## Correlati

[server/sv_garage.md](../server/sv_garage.md) ·
[config/cfg_vehicles.md](../config/cfg_vehicles.md) ·
[config/cfg_stations.md](../config/cfg_stations.md)

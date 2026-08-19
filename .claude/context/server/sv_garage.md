# server/sv_garage.lua

**Ruolo:** veicoli di servizio: spawn lato server, targa LSPD, un veicolo per agente.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_armory.lua`

## Cosa fa

**Nessuna dipendenza da `esx_vehicleshop`** (su questo server è in `[disabled]`, per cui il
garage di `esx_policejob` era di fatto rotto). Il veicolo è creato con
`CreateVehicleServerSetter`, targato `LSPD NNN`, e **non finisce in `owned_vehicles`**: è un
mezzo di reparto, non un bene del personaggio.

Stato in memoria: `activeVehicles` indicizzata per `identifier`, con
`{ netId, entity, plate, model }`.

## Targhe

`nextPlate()` incrementa un contatore modulo 1000 e produce `LSPD NNN`. Controlla che la
targa non sia già in strada fra i veicoli attivi; in caso di collisione ricorre.

## Callback

### `KF_Police:garage:catalog` — `garage.use`

Veicoli autorizzati per grado e **categoria del garage**. Include `hasActive`.

### `KF_Police:garage:spawn` — `garage.use`

Controlli, in ordine:

1. permesso;
2. **in servizio** se `Config.Duty.Enabled` → altrimenti `duty_required`;
3. `data.model` è una stringa;
4. `OneVehiclePerOfficer` e nessun veicolo già attivo → altrimenti `garage_already_out`;
5. il modello è fra quelli **autorizzati per il grado e la categoria** → altrimenti
   `no_permission`;
6. se `price > 0`, `RemoveSocietyMoney` → altrimenti `armory_no_money`;
7. `coords` valide.

Poi `CreateVehicleServerSetter` (tipo `heli` per la categoria `helicopter`, altrimenti
`automobile`), attesa fino a 5 s che l'entità esista, `SetVehicleNumberPlateText`, e
registrazione in `activeVehicles`.

Ritorna `netId`, `plate` e `props` (quelli della voce, o `Config.Garage.DefaultProps`).

### `KF_Police:garage:store` — `garage.use`

Se il client indica un `netId` **diverso** da quello prelevato, rifiuta: non si può
riconsegnare il veicolo di un altro.

## Despawn

La funzione locale `despawn(identifier)` risolve l'entità da `entity` o, se non esiste più,
da `NetworkGetEntityFromNetworkId(netId)`, poi `DeleteEntity`.

Chiamata da:

| Trigger | Origine |
|---|---|
| `KF_Police:Server:DespawnServiceVehicle` | il client conferma dopo `DespawnOnDuty` |
| `playerDropped` | disconnessione |
| `onResourceStop` | tutti i veicoli attivi |

## Note e trappole

- **Il pagamento avviene prima dello spawn.** Se `CreateVehicleServerSetter` fallisce, il
  denaro **non viene restituito**. Con tutti i prezzi a 0 oggi è irrilevante.
- L'attesa di 5 s con `Wait(10)` blocca il callback: il client resta in attesa. È il prezzo
  di uno spawn server-side affidabile.
- `activeVehicles` è in RAM: un restart della risorsa cancella i veicoli
  (`onResourceStop` li elimina) ma se il server crasha restano in strada, orfani, senza
  che nessuno li riconosca come di servizio.
- Il contatore delle targhe **riparte da 0 a ogni restart**: dopo un riavvio si possono
  riusare targhe di veicoli orfani rimasti in strada.
- Il controllo "in servizio" c'è solo su `spawn`, non su `store`: si può riconsegnare
  anche fuori servizio. È sensato.
- La categoria arriva da `data.category` (dal client) ma il modello è validato **contro
  quella categoria**: chiedere un `polmav` dichiarando `category = 'car'` fallisce perché
  `polmav` non è in `AuthorizedVehicles.car`.

## Correlati

[config/cfg_vehicles.md](../config/cfg_vehicles.md) ·
[client/cl_garage.md](../client/cl_garage.md) · [server/sv_duty.md](sv_duty.md)

# client/cl_impound.lua

**Ruolo:** sequestro di un veicolo e deposito sequestri.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_jail.lua`

## Cosa fa

### `ImpoundVehicle(vehicle)` — funzione globale

Chiamata dal menu azioni veicolo (`cl_actions_vehicle.lua`). Sequenza:

1. targa normalizzata → altrimenti `vehicle_not_found`;
2. `lib.inputDialog` per il motivo (obbligatorio, max 200);
3. `PoliceProgress('progress_impound', Config.Impound.Duration)` con animazione
   `mini@repair / fixing_a_ped`; annullabile;
4. `KF_Police:actions:impound` → **scrive il flag `is_impounded` su database prima di
   toccare il veicolo**, così il sequestro sopravvive al restart (bug L3);
5. svuota il veicolo (`TaskLeaveVehicle` per ogni posto occupato), aspetta 1.2 s;
6. `SetEntityAsMissionEntity` + `DeleteVehicle`.

**L'ordine è deliberato:** database prima, mappa dopo. Se il passo 4 fallisce il veicolo
resta in strada, che è recuperabile; l'inverso lascerebbe un veicolo cancellato senza
registrazione.

### Deposito

Zona sull'`impound.retrieve` della stazione (permesso `field.impound`). Chiama
`vehicles:impounded` e mostra un elenco: targa, modello, proprietario, motivo.

Selezionando una voce, `lib.alertDialog` di conferma, poi
`vehicles:setFlag { impounded = false }`.

## Note e trappole

- **Il dissequestro non fa rispawnare il veicolo**, e non addebita
  `Config.Impound.Fee`: toglie solo il flag. Il proprietario non riottiene il mezzo da qui.
  È una funzionalità incompleta, non un bug da cercare.
- `Config.Impound.Fee` (500) è dichiarata in configurazione e **non usata da nessuna parte**.
- L'attesa di 1.2 s fra lo svuotamento e la cancellazione è fissa: se un ped è lento a
  scendere viene cancellato dentro il veicolo.
- `impound.spawn` in `cfg_stations.lua` è dichiarato e **non usato**: era previsto per il
  rispawn al dissequestro.
- Il progresso è annullabile: chi annulla non sequestra nulla e non scrive nulla.

## Correlati

[server/sv_vehicles.md](../server/sv_vehicles.md) ·
[client/cl_actions_vehicle.md](cl_actions_vehicle.md) ·
[config/cfg_actions.md](../config/cfg_actions.md)

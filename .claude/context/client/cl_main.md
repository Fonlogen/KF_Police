# client/cl_main.lua

**Ruolo:** nucleo client. Stato locale del servizio, utilità condivise dagli altri file
client, blip delle stazioni.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, primo del nucleo client (dopo i bridge)

## Cosa fa

Solo il minimo indispensabile. Le funzioni definite qui sono usate da quasi tutti gli altri
file client.

## API pubblica

| Funzione | Ritorna | Note |
|---|---|---|
| `IsPlayerOnDuty()` | boolean | stato locale, sincronizzato dal server |
| `GetNearestStation()` | `stazione, chiave` | entro 200 m; riferimento = `blip.coords` o il primo spogliatoio |
| `GetCurrentStreet()` | string | nome della strada, ripiego `'Los Santos'` |
| `GetNearestVehicle(maxDistance)` | `entità, distanza` | se sei **dentro** un veicolo ritorna quello con distanza 0 |
| `PoliceProgress(labelKey, duration, options)` | boolean | barra di progresso uniforme |

`PoliceProgress` incapsula `lib.progressBar` con i default del progetto: cancellabile,
non usabile da morto, movimento e veicolo disabilitati (a meno di `options.allowMove` /
`allowCar`), combattimento sempre disabilitato. L'etichetta è una **chiave di locale**, non
un testo.

Tutte le azioni di campo con animazione passano da qui: cosi il comportamento e l'aspetto
sono identici.

## Stato del servizio

`onDuty` locale, aggiornato da `KF_Police:Client:DutyChanged`.

All'ingresso in gioco un thread aspetta `Framework.IsLoaded()` e poi chiede
`duty:state` al server: **lo stato reale lo conosce il server**, non si assume nulla.

## Blip delle stazioni

Un thread al caricamento crea un blip per ogni stazione con `blip.coords`, usando sprite,
display, scala e colore dalla configurazione, `SetBlipAsShortRange(true)` e il `label` come
nome.

Non sono aggiornati: i blip delle stazioni sono statici. Quelli dei colleghi stanno in
`cl_blips.lua`.

## Note e trappole

- **`IsPlayerOnDuty()` è una copia locale.** I `canInteract` delle zone (armeria, garage) la
  usano per non mostrare l'opzione, ma il controllo autorevole è del server
  (`sv_garage.lua` verifica `IsOnDuty`).
- Il thread di sincronizzazione gira **una volta sola**, all'ingresso. Un
  `DutyChanged` mancato lascia lo stato locale sbagliato fino al prossimo cambio.
- `GetNearestVehicle` usa `lib.getClosestVehicle`: include i veicoli non renderizzati solo
  se sono nello streaming del client.
- `GetNearestStation` non è usata da nessuno oggi: è un aggancio per menu futuri che devono
  sapere in quale stazione si è.
- I blip vengono creati e mai rimossi: `onResourceStop` non li pulisce. Un restart della
  risorsa **duplica i blip** delle stazioni fino al riavvio del client.

## Correlati

[config/cfg_stations.md](../config/cfg_stations.md) ·
[server/sv_duty.md](../server/sv_duty.md) · [client/cl_blips.md](cl_blips.md)

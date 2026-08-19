# server/sv_vehicles.lua

**Ruolo:** archivio veicoli e flag persistenti (rubato, sequestrato, BOLO).
**Correzione del bug L3.**
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, dopo `sv_reports.lua`

## Il bug L3

`SetVehicleFlag` mutava solo la tabella in RAM: **rubato e sequestrato si perdevano al
restart**. Ora ogni flag è una riga su `kf_police_vehicle_flags`, con chi e quando l'ha
impostato.

## Endpoint

### `vehicles:search` — `mdt.vehicle.view`

Se `owned_vehicles` non esiste ritorna una pagina vuota invece di errore.

Join `owned_vehicles` + `users` (proprietario) + `kf_police_vehicle_flags`. Ricerca su
targa, blob `vehicle` e nome completo del proprietario. Filtri: `stolen`, `impounded`,
`bolo`.

Lista bianca `SORTABLE`: `plate`, `owner` (→ `owner_name`), `type`.

I flag usano `COALESCE(f.is_stolen, 0)`: un veicolo senza riga di flag esce come regolare.

### `vehicles:get` — `mdt.vehicle.view`

Ritorna `GetVehicleRecord(plate)`, o `vehicle_not_found`.

### `vehicles:setFlag` — `mdt.vehicle.flag`

Delega a `SetVehicleFlags(officer, plate, payload)` e ritorna la scheda ricaricata.

### `vehicles:impounded` — `mdt.vehicle.view`

Elenco completo (non paginato) dei sequestri, per il deposito. Usato da
`client/cl_impound.lua`.

## Funzioni globali

### `GetVehicleRecord(plate)` → tabella|nil

Scheda completa. **Funziona anche per targhe non registrate**: se non c'è la riga in
`owned_vehicles` ma ci sono i flag, ritorna la scheda con `registered = false`. È
l'informazione che serve davvero durante un controllo su strada (rubato / ricercato). Se
non c'è né l'una né gli altri, ritorna `nil`.

Include i rapporti collegati alla targa (max 25).

### `SetVehicleFlags(officer, plate, changes)` → boolean

`INSERT IGNORE` per garantire la riga, poi una `UPDATE` costruita dinamicamente.

`changes` accetta `stolen`, `impounded`, `bolo`, `notes`, `reason`. **Un campo assente non
viene toccato** (`~= nil` è il test): si può cambiare un flag senza azzerare gli altri.

`impounded = true` valorizza anche `impound_reason`, `impound_by` e `impound_at = NOW()`;
`impounded = false` li azzera. Stesso schema per `bolo` con `bolo_reason`.

`officer` può essere `nil` (azione di sistema): in quel caso non scrive l'audit.

Sempre `Invalidate('vehicles', plate)` alla fine.

Chiamata anche da `server/sv_actions.lua` per `impound` e `markStolen` dal campo.

## Note e trappole

- **`reason` è condiviso** fra sequestro e BOLO: cambiare i due flag nella stessa chiamata
  scrive lo stesso motivo su entrambi.
- La chiave è la **targa normalizzata** (`NormalizePlate`: maiuscola, senza spazi ai bordi).
  Gli spazi interni restano: `'LSPD 001'` e `'LSPD  001'` sono targhe diverse.
- `kf_police_vehicle_flags` **non ha vincoli** verso `owned_vehicles`: si possono segnare
  targhe inesistenti. È voluto (i veicoli di servizio e quelli non registrati devono essere
  segnalabili), ma significa che le righe orfane non si ripuliscono da sole.
- `vehicles:impounded` non è paginato: con centinaia di sequestri la risposta diventa
  grande.
- `DecodeVehicleModel` viene da `sv_citizens.lua` (caricato prima): ritorna il nome tecnico
  del modello, non un'etichetta.

## Correlati

[server/sv_actions.md](sv_actions.md) · [client/cl_impound.md](../client/cl_impound.md) ·
[web/pages/VehiclesPage.md](../web/pages/VehiclesPage.md) ·
[web/pages/VehicleSheet.md](../web/pages/VehicleSheet.md)

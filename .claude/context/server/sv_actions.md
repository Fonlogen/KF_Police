# server/sv_actions.lua

**Ruolo:** azioni di campo. Ogni azione rivalida il bersaglio e **misura la distanza sul
server**.
**Contesto:** server
**Caricato da:** `fxmanifest.lua`, **ultimo** dei moduli di dominio

## Il principio

Il payload del client non è mai attendibile. `ValidateTarget` verifica che il bersaglio
esista, che sia un giocatore, e che sia **davvero** entro la distanza consentita:

```lua
local distance = #(GetEntityCoords(officerPed) - GetEntityCoords(targetPed))
if distance > (maxDistance or Config.Actions.MaxDistance) then
    return nil, 'too_far'
end
```

Rifiuta anche `targetSrc == src` (ammanettare se stessi).

## Stato in memoria

| Tabella | Contenuto |
|---|---|
| `restrained` | `identifier → true` per i cittadini ammanettati |
| `dragging` | `identifier agente → identifier cittadino` scortato |

`IsRestrained(identifier)` è la funzione pubblica di lettura.

## Callback

### Manette — `KF_Police:actions:cuff` (`field.cuff`)

Toggle. Ammanettando: verifica l'item `Config.Actions.HandcuffItem` in inventario.
Slegando: interrompe anche la scorta di quel cittadino, cercandola in `dragging`.

Manda `KF_Police:Client:SetRestrained` con il timer configurato.
`KF_Police:Server:CuffExpired` (dal client, a scadenza) pulisce lo stato.

### Scorta — `KF_Police:actions:drag` (`field.cuff`)

Toggle. Per **iniziare** il cittadino deve essere ammanettato (`drag_need_cuffs`); per
**smettere** no.

### Veicolo — `KF_Police:actions:vehicle` (`field.cuff`)

`action = 'in'|'out'`. Usa `MaxVehicleDistance` (4 m). Il posto libero lo trova il client.

### Perquisizione — `KF_Police:actions:search` (`field.search`)

Se `Config.Actions.SearchRequiresRestraint`, il cittadino deve essere ammanettato **oppure
morto** (`xTarget.get('isDead')`). Ritorna `Inventory.GetInventory(target)` e notifica il
perquisito.

### Sequestro item — `KF_Police:actions:seize` (`field.search`)

**Sostituisce `esx_policejob:confiscatePlayerItem`**, aggiungendo i controlli di distanza e
permesso che l'originale non faceva.

Rimuove dal bersaglio, poi consegna all'agente. Se la consegna fallisce, **restituisce
l'oggetto al proprietario**: nessuna sparizione.

### Identificazione — `KF_Police:actions:identify` (`field.identify`)

Ritorna `identifier` e nome. Il client apre il **fascicolo nel MDT** invece di un menu di
testo.

### Licenze — `licenses` / `revokeLicense` (`field.license`)

Legge `user_licenses` LEFT JOIN `licenses` (con `TableExists`). La revoca è una `DELETE`;
se 0 righe, `license_none`.

**Non esiste `grantLicense`**: il locale `license_granted` c'è ma nessun endpoint la
rilascia.

### Lockpick — `KF_Police:actions:lockpick` (`field.lockpick`)

Verifica solo l'item. **Nessun bersaglio**: l'apertura vera la fa il client con
`SetVehicleDoorsLocked`.

### Veicoli — `impound` / `markStolen` / `plateCheck`

Delegano a `SetVehicleFlags` e `GetVehicleRecord` di `sv_vehicles.lua`: i flag sono
persistenti (bug L3).

### Carcere — `jail` / `pendingSentence` (`jail.send`)

`jail` converte i mesi con `SecondsPerMonth` e chiama `JailPlayer`.
`pendingSentence` ritorna i mesi accumulati dai reati non annullati, per proporre la pena
predefinita nel dialogo.

## Pulizia

`playerDropped` rimuove il giocatore da `restrained` e `dragging`, sia come agente sia come
cittadino scortato.

## Note e trappole

- **Lo stato delle manette è in RAM.** Un restart della risorsa libera tutti gli
  ammanettati senza avvisare i client, che restano con l'animazione: il ciclo di
  `cl_cuffs.lua` la riapplica finché il timer locale non scade.
- `lockpick` non valida il veicolo: chi ha il permesso e l'item riceve `ok = true` sempre.
  Il vincolo di distanza è solo lato client.
- Il **perquisito morto** è riconosciuto con `xTarget.get('isDead')`, che dipende da come
  ESX espone lo stato: su alcune configurazioni può essere `nil`, e allora serve comunque
  ammanettare.
- `seize` non registra l'oggetto sequestrato da nessuna parte se non nell'audit: non
  esiste un registro prove.
- Tutti i callback ritornano `{ ok, message }` (non `MdtOk`/`MdtError`): sono callback
  diretti, non endpoint MDT. `cl_actions_*.lua` li interpreta con `notifyResponse`.

## Correlati

[config/cfg_actions.md](../config/cfg_actions.md) ·
[client/cl_actions_citizen.md](../client/cl_actions_citizen.md) ·
[server/sv_vehicles.md](sv_vehicles.md) · [server/sv_jail.md](sv_jail.md)

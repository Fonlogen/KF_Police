# client/cl_drag.lua

**Ruolo:** scorta: il cittadino ammanettato viene agganciato all'agente.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_cuffs.lua`

## Cosa fa

Gira sul client del **cittadino scortato**, non dell'agente.

`KF_Police:Client:SetDragged(state, officerServerId)`:

- **vero** → `attachTo(officerServerId)`: risolve il player locale con
  `GetPlayerFromServerId`, prende il ped e chiama `AttachEntityToEntity` con osso `11816`
  e offset `(0.54, 0.54, 0.0)`. Se la risoluzione fallisce, `draggedBy` torna `nil`;
- **falso** → `DetachEntity(ped, true, false)`.

## Il ciclo di guardia

Ogni 500 ms mentre `draggedBy` è valorizzato:

- se l'agente non è più risolvibile o il suo ped non esiste (si è allontanato oltre lo
  streaming, o si è disconnesso) → **stacca**;
- se il ped non è più agganciato (`IsEntityAttached` falso) → **riprova** ad agganciarsi.

Il riaggancio serve perché l'attach si perde quando l'agente esce dallo streaming e
rientra.

A `draggedBy` nil il ciclo dorme 1 s.

## Note e trappole

- **La distanza e il vincolo "deve essere ammanettato" sono verificati dal server**
  (`sv_actions.lua`): qui non si controlla nulla.
- L'osso `11816` è la mano destra: il cittadino cammina alla destra dell'agente.
- Se l'agente si disconnette, il cittadino si stacca da solo entro 500 ms, ma **il server
  non lo sa**: `dragging` resta popolato fino al `playerDropped` dell'agente, che lo
  pulisce.
- `onResourceStop` stacca il ped: senza, resterebbe agganciato a un'entità che non è più
  gestita.
- Non c'è animazione di camminata forzata: il cittadino usa la sua, agganciata. In
  combinazione con l'animazione delle manette di `cl_cuffs.lua` il risultato è accettabile.

## Correlati

[server/sv_actions.md](../server/sv_actions.md) · [client/cl_cuffs.md](cl_cuffs.md)

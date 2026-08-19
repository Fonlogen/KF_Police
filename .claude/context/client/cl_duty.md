# client/cl_duty.lua

**Ruolo:** entrata e uscita dal servizio.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, primo delle funzioni client

## Cosa fa

Il file più piccolo del progetto. Chiama `duty:toggle` sul server e, in caso di ingresso in
servizio, **salva l'abito civile** prima che lo spogliatoio lo sostituisca con la divisa.

```lua
if response.onDuty and Config.Cloakroom.RestoreCivilian and Clothing.Available() then
    Clothing.SaveCivilian()
end
```

## API pubblica

| Elemento | Uso |
|---|---|
| `ToggleDuty()` | esposta agli altri file client (spogliatoio, MDT) |
| comando `poliziaservizio` | verifica `HasAllowedJob` e chiama il toggle |

## Punti di ingresso al servizio

1. lo **spogliatoio** della stazione (`cl_cloakroom.lua`, se il grado ha `duty.toggle`);
2. il comando `/poliziaservizio`;
3. la **pagina Servizio del MDT** — che non è ancora scritta.

Nessuna dipendenza da `esx_service`.

## Note e trappole

- Il salvataggio dell'abito civile avviene **all'ingresso in servizio**, non quando si
  indossa la divisa. Se entri in servizio già in divisa (perché ce l'avevi da prima), il
  KVP salva la divisa come "abito civile". `cl_cloakroom.lua` ha una protezione
  (`if not wearingUniform`) ma è basata su un flag locale che si azzera a ogni ricarica
  del client.
- Il comando non ha `RegisterKeyMapping`: non c'è un tasto per il servizio.
- Il messaggio mostrato è quello del server (`duty_on`, `duty_off`, `duty_full`).

## Correlati

[server/sv_duty.md](../server/sv_duty.md) · [client/cl_cloakroom.md](cl_cloakroom.md) ·
[config/cfg_duty.md](../config/cfg_duty.md)

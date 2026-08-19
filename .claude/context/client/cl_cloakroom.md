# client/cl_cloakroom.lua

**Ruolo:** spogliatoio: divisa per grado e sesso, extra, abito civile, toggle servizio.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_duty.lua`

## Cosa fa

Registra una zona target per ogni `cloakrooms` di ogni stazione (permesso
`cloakroom.use`), e apre un menu contestuale `ox_lib` con:

1. **Indossa la divisa** — quella del proprio `gradeName` e sesso;
2. **Torna in borghese** — ripristina l'abito civile salvato;
3. una voce per ogni `Config.Cloakroom.Extras` (`bulletproof`, `gilet`);
4. **toggle servizio**, solo se il grado ha `duty.toggle`.

## Le funzioni interne

| Funzione | Comportamento |
|---|---|
| `uniformFor(gradeName)` | `Config.Uniforms[gradeName][sesso]`, ripiego su `male` |
| `applyUniform()` | salva l'abito civile se non si è già in divisa, poi `Clothing.Apply` |
| `applyExtra(extraId)` | applica solo i componenti dell'extra, sopra la divisa |
| `restoreCivilian()` | `Clothing.RestoreCivilian()`, e azzera `wearingUniform` se riesce |

Il flag locale `wearingUniform` evita di sovrascrivere l'abito civile salvato quando si
riapplica la divisa due volte di seguito.

Se la divisa manca o il bridge vestiario non è disponibile: `NotifyLocale('uniform_missing')`
e nulla di distruttivo.

## Note e trappole

- **`wearingUniform` è locale e si azzera a ogni ricarica del client.** Chi rientra in gioco
  in divisa e riapplica la divisa dallo spogliatoio salva la **divisa** come abito civile.
  È il difetto noto dello schema; il vero rimedio sarebbe verificare l'abito attuale, che
  nessun bridge sa fare in modo affidabile.
- Gli extra si applicano **sopra** l'abito corrente, non sostituiscono la divisa: sono
  singoli componenti (`bproof_1` per il giubbotto, `tshirt_1` per il gilet).
- `gilet` usa gli stessi indici di `recruit.tshirt_1`: metterlo sopra la divisa di un
  `officer` sostituisce la maglietta.
- Il menu si registra e si mostra a ogni apertura: le opzioni riflettono lo stato del
  servizio nel momento in cui apri (l'etichetta del toggle cambia).
- Aspetta `Target` in un ciclo prima di registrare le zone: i bridge target sono caricati
  prima, ma il `return` condizionale significa che `Target` può essere `nil` per un istante.

## Correlati

[config/cfg_duty.md](../config/cfg_duty.md) ·
[modules/clothing-cl_appearance.md](../modules/clothing-cl_appearance.md) ·
[client/cl_duty.md](cl_duty.md)

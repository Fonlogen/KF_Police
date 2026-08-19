# shared/locales/en.lua

**Ruolo:** locale inglese. È il **ripiego** di `Locale()` quando la chiave manca nel
locale attivo.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo `it.lua`

## Cosa fa

Popola `Locales['en']` con le stesse ~140 chiavi di `it.lua`, tradotte. Riassegna
`Config.Locales = Locales`.

La catena di ripiego in `Locale()` (`shared/sh_utils.lua`) è:

```
Locales[Config.Locale][key]  ->  Locales['en'][key]  ->  key
```

Quindi una chiave dimenticata in `it.lua` compare **in inglese** invece di sparire. È il
motivo per cui questo file deve restare completo anche se il server gira in italiano.

## Note e trappole

- **Stesse chiavi e stesso numero di segnaposto di `it.lua`.** Se `it.lua` ha
  `charges_added = '%d reati...'` e qui manca `%d`, il ripiego produce una stringa senza
  il numero.
- A differenza di `it.lua`, qui gli accenti non sono un problema (l'inglese non ne ha):
  la convenzione "nessun carattere accentato" resta comunque valida per coerenza.
- Non ci sono chiavi presenti solo qui: la lista è la stessa. Se aggiungi una chiave in
  uno dei due file, aggiungila subito nell'altro.

## Correlati

[shared/locales-it.md](locales-it.md) · [shared/sh_utils.md](sh_utils.md)

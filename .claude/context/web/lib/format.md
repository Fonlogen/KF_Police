# web/src/lib/format.ts

**Ruolo:** formattazione condivisa, locale `it-IT`. Nessuna emoji, nessun carattere
decorativo.
**Contesto:** UI

## API pubblica

### Numeri e valuta

| Funzione | Esempio |
|---|---|
| `money(amount)` | `$1.500` (`toLocaleString('it-IT')`, nessun decimale) |
| `num(value)` | `1.500` |

### Date

| Funzione | Esempio |
|---|---|
| `dateTime(value)` | `19/08/2026 21:47` |
| `dateOnly(value)` | `19/08/2026` |

`parseSql` normalizza `"2026-08-19 21:47:00"` in ISO sostituendo lo spazio con `T`. Se la
data non è interpretabile, **si mostra la stringa grezza** invece di `Invalid Date`.
`null`/`undefined` → `'-'`.

### Durate

| Funzione | Esempio |
|---|---|
| `duration(seconds)` | `1h 05m` / `12m 30s` / `45s` |
| `months(value)` | `1 mese` / `35 mesi` / `-` se `<= 0` |

### Persone

| Funzione | Comportamento |
|---|---|
| `fullName(person)` | `"Mario Rossi"`, ripiego `'Sconosciuto'` |
| `initials(person)` | `"MR"`, ripiego `'?'` — per l'`Avatar` senza foto |

### Etichette

`countLabel(total, extra?)` — produce `"8"` oppure `"8 - 1 ricercato"` gestendo
singolare/plurale. È l'etichetta del contatore nell'intestazione del foglio.

`reportStatus(status)` — `draft` → Bozza, `open` → Aperto, `closed` → Chiuso.
`involvedRole(role)` — `suspect` → Sospettato, `victim` → Vittima, `witness` → Testimone.

Entrambe con ripiego sul valore grezzo se la chiave è sconosciuta.

## Note e trappole

- **`duration()` duplica `FormatDuration()` di `shared/sh_utils.lua`.** Le due
  implementazioni producono lo stesso formato e vanno **cambiate insieme**: altrimenti la
  stessa durata appare scritta in due modi diversi nel tablet (una dal Lua via
  `timeLabel`, una calcolata qui).
- `reportStatus` e `involvedRole` sono **traduzioni cablate in italiano**, non passano dai
  locali Lua. Cambiare `Config.Locale` non le traduce. È una scelta accettata: i testi della
  UI sono in italiano.
- `money()` non gestisce valute diverse dal dollaro: il `$` è cablato.
- `dateTime` usa il fuso del **client**, il database scrive nel fuso del server: se
  divergono, le date mostrate sono spostate.
- `initials` prende solo il primo carattere di nome e cognome: un nome vuoto dà un'iniziale
  sola, non un errore.

## Correlati

[shared/sh_utils.md](../../shared/sh_utils.md) ·
[web/components/Avatar.md](../components/Avatar.md) ·
[web/components/Sheet.md](../components/Sheet.md)

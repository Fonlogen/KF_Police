# shared/sh_utils.lua

**Ruolo:** utilità condivise: traduzione, JSON, sanificazione dell'input NUI, formattazione.
**Contesto:** shared
**Caricato da:** `fxmanifest.lua`, dopo la configurazione e **prima** di `sh_permissions`

## API pubblica

Tutte funzioni globali, senza namespace.

### Traduzione

```lua
Locale(key, ...)  -- ripiego: Locales[Config.Locale] -> Locales['en'] -> la chiave stessa
```

Se ci sono argomenti variadici applica `string.format` dentro un `pcall`: un formato
sbagliato ritorna la stringa non formattata invece di lanciare.

### JSON e tabelle

| Funzione | Comportamento |
|---|---|
| `DecodeJson(value, fallback)` | passa oltre le tabelle, decodifica le stringhe, ritorna `fallback or {}` in caso di errore |
| `EncodeJson(value)` | passa oltre le stringhe già codificate |
| `TableCount(tbl)` | conta le chiavi (anche non contigue) |
| `NormalizeList(value)` | mappa **o** lista → lista Lua contigua |

`NormalizeList` è la chiave della migrazione: i blob storici `criminalRecords` e `notes`
esistono in entrambe le forme (mappa indicizzata e array), e questa funzione le
appiattisce entrambe.

### Sanificazione

| Funzione | Comportamento |
|---|---|
| `Trim(value)` | ritorna **sempre** una stringa, anche da `nil` |
| `SanitizeText(value, maxLength)` | trim + caratteri di controllo → spazio (`\n` preservato) + taglio |
| `StripEmoji(text)` | rimuove le emoji preservando i caratteri tipografici |
| `ClampInt(value, min, max, fallback)` | intero entro l'intervallo |
| `ToBool(value)` | vero per `true`, `1`, `'1'`, `'true'` |
| `NormalizePlate(plate)` | maiuscole, trim, `nil` se vuota |

**`SanitizeText` è la prima riga di ogni endpoint** che accetta testo dalla NUI, con il
limite corrispondente da `Config.Limits`.

`StripEmoji` lavora sui byte UTF-8: sequenze a 4 byte (emoticon, pittogrammi, bandiere),
blocco `E2` da U+2300 in su (simboli e dingbats), blocco `E3` (CJK racchiusi), selettori
di variazione U+FE0E/FE0F. **Preserva** U+2000-U+22FF, cioè apici tipografici e dash: un
testo italiano corretto non viene mutilato.

### Formattazione

| Funzione | Esempio |
|---|---|
| `FormatDuration(seconds)` | `"1h 05m"`, `"12m 30s"`, `"45s"` |
| `SqlNow()` | `os.date('%Y-%m-%d %H:%M:%S')` |

## Note e trappole

- `Locale` legge `Locales` **globale**, popolato dai file in `shared/locales/`. Se
  `sh_utils.lua` girasse prima dei locali, `Locale` ritornerebbe la chiave: l'ordine in
  `fxmanifest.lua` lo garantisce.
- `FormatDuration` esiste in doppio: qui in Lua e come `duration()` in
  `web/src/lib/format.ts`. **Se cambi il formato, cambialo in entrambi**, altrimenti la
  stessa durata appare scritta in due modi diversi nel tablet.
- `StripEmoji` è usata da `sv_reports.lua` (`tags:save`) e da `sv_migrations.lua`
  (pulizia dei tag legacy). È la correzione del bug L11.
- `SqlNow()` usa l'ora **locale del server**, non UTC. Le colonne `DATETIME` con
  `CURRENT_TIMESTAMP` usano l'ora di MySQL: se le due macchine hanno fusi diversi le
  date miste divergono.

## Correlati

[shared/locales-it.md](locales-it.md) · [shared/sh_permissions.md](sh_permissions.md) ·
[web/lib/format.md](../web/lib/format.md)

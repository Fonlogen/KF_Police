# modules/notify/cl_notify.lua

**Ruolo:** notifiche. Se il tablet è aperto vanno dentro il tablet, altrimenti escono come
notifica di gioco.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, subito dopo il bridge framework client

## Cosa fa

```lua
Notify(message, nType)        -- nType: 'info'|'success'|'error'|'warning'
NotifyLocale(key, nType, ...) -- = Notify(Locale(key, ...), nType)
```

`TYPE_MAP` normalizza gli alias: `info`/`inform` → `inform`, `warn`/`warning` →
`warning`.

Lo smistamento:

- **tablet aperto** (`MdtIsOpen()` vero) → `SendNUIMessage({ action = 'mdt:notify', ... })`
  → `MdtProvider` → `ToastStack` dentro il telaio;
- **tablet chiuso** → `lib.notify` di ox_lib, titolo `LSPD`, posizione `top-right`,
  durata `Config.NotificationsDuration` (3000 ms).

Ascolta `KF_Police:Client:Notify`, l'evento che il server usa via
`Framework.Notify(src, ...)`.

## Perché esiste

Con il tablet aperto la NUI ha il focus e copre lo schermo: una notifica di gioco
finirebbe **sotto** il tablet, invisibile. Portarla dentro il telaio è l'unico modo per
farla vedere.

## Note e trappole

- **Dipende da `MdtIsOpen`**, definita in `client/cl_nui.lua`, che nell'ordine di
  `fxmanifest.lua` è caricato **dopo** questo file. Funziona perché la chiamata avviene a
  runtime e il controllo è `if MdtIsOpen and MdtIsOpen()`: prima che `cl_nui` sia caricato,
  `MdtIsOpen` è `nil` e la notifica esce come notifica di gioco. Non invertire quel
  controllo in `if MdtIsOpen()`.
- `Notify('')` o `Notify(nil)` non fa nulla: nessun toast vuoto.
- Le notifiche sono **client-side**: il server non decide dove appaiono, manda solo
  l'evento.
- `NotifyLocale` è la forma preferita nel codice client: tiene i testi nei locali.

## Correlati

[client/cl_nui.md](../client/cl_nui.md) ·
[web/components/Toast.md](../web/components/Toast.md) ·
[shared/locales-it.md](../shared/locales-it.md)

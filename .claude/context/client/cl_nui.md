# client/cl_nui.lua

**Ruolo:** tutto il ponte con la NUI: geometria del tablet, apertura/chiusura, inoltro degli
endpoint, push dal server.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, subito dopo `cl_main.lua`

## Scala dinamica

Il tablet non ha una dimensione assoluta in pixel.

`ComputeTabletGeometry()` calcola **due rettangoli concentrici**:

- la **cornice** (`frameWidth`/`frameHeight`): l'ingombro fisico del dispositivo, cioè
  quello che deve stare dentro lo schermo;
- la **schermata** (`width`/`height`): la finestra utile dentro la cornice, con il
  rapporto di progetto 1280 × 910. Da lei deriva `rootFontSize`.

Passi:

1. legge la risoluzione reale con `GetActiveScreenResolution()`;
2. `growX`/`growY` = quanto la scocca è più grande della finestra trasparente
   (1400/1280 = 1.094 e 1073/888 = 1.208, da `Config.UI.frame`);
3. parte dall'altezza della **cornice** (`sh × heightRatio`) e torna indietro alla
   larghezza della schermata dividendo per `growY`;
4. applica `minWidth`/`maxWidth` **alla schermata**, non alla cornice: è la sua larghezza
   che determina la dimensione del testo;
5. un unico fattore `fit` rimpicciolisce tutto se la cornice non entra nello schermo.
   **Questo vincolo batte `minWidth`**: meglio un tablet piccolo che tagliato;
6. arrotonda la cornice e **ricava la schermata da lì**, così i valori riportati sono
   esattamente quelli che il CSS disegnerà;
7. `rootFontSize = 16 × (width / baseWidth) × Config.UI.scale`.

`frameInset` porta alla NUI la posizione della finestra trasparente in **frazioni della
cornice**: la UI le applica come percentuali e non conosce le misure in pixel del PNG.
Con `Config.UI.frame.enabled = false` `frameInset` è assente, i due rettangoli coincidono
e il risultato è identico a prima della cornice.

La NUI applica `rootFontSize` al `font-size` della radice e tutti i componenti misurano in
`rem`: a 1080p, 1440p e 4K il testo ha la **stessa dimensione apparente**.

Un thread ricontrolla la risoluzione ogni 4 s e rimanda la geometria se cambia (alt-tab,
cambio monitor).

## Apertura e chiusura

`OpenMDT()`: framework caricato → lavoro autorizzato → se già aperto **chiude** (toggle) →
`SetNuiFocus(true, true)` → geometria → `mdt:visible` → thread che chiama `bootstrap` e
manda `mdt:bootstrap` più `PushRadioStateToNui()`.

Se il `bootstrap` fallisce: notifica l'errore e **chiude**.

`CloseMDT()`: `SetNuiFocus(false, false)` sempre (anche se non era aperto: pulisce uno
stato incoerente), poi `mdt:visible` falso, e uscita dalla radio se
`Config.Radio.DisconnectOnClose`.

Comando `Config.OpenCommand` + `RegisterKeyMapping` su **`Config.OpenKey`, che è `F5`**:
correzione del bug L8 (F6 collideva con `police:quickactions` di `esx_policejob`).

## Il ponte NUI → server

```lua
RegisterNUICallback('mdt', function(data, cb)
```

Un solo callback. Se l'endpoint è in `localEndpoints` lo esegue in locale (in `pcall`),
altrimenti lo inoltra a `lib.callback.await('KF_Police:mdt', false, endpoint, payload)`.

`RegisterLocalMdtEndpoint(name, handler)` è l'API per registrare un endpoint locale;
la usano `cl_radio.lua` e questo file stesso.

`RegisterNUICallback('mdt:close')` chiude il tablet (usato dalla X e da ESC).

### Endpoint locali definiti qui

| Endpoint | Ritorna |
|---|---|
| `client:context` | `location` (strada), `time` (ora di gioco) |
| `client:nearby` | `serverId` e `distance` del cittadino più vicino, oppure `no_nearby_player` |

## Apertura diretta su una scheda

`OpenMdtOnCitizen(identifier)` e `OpenMdtOnVehicle(plate)`: aprono il tablet se chiuso,
**aspettano il bootstrap** (fino a 5 s, flag `bootstrapped`), poi mandano
`mdt:open` con `{ view, id }`.

Usate dalle azioni di campo: la carta d'identità e il controllo targa aprono il fascicolo
nel tablet invece di un menu di testo.

## Push dal server

| Evento | Azione |
|---|---|
| `KF_Police:Client:Invalidate` | `mdt:invalidate` **solo se aperto e bootstrappato** |
| `KF_Police:Client:Counters` | `mdt:counters` solo se aperto |
| `KF_Police:Client:DutyChanged` | `mdt:duty` sempre |
| `KF_Police:Client:OpenMDT` | apre il tablet |

Un thread manda `mdt:status` (strada, ora, in veicolo) ogni 5 s **mentre il tablet è
aperto**, e ogni 1.5 s controlla se lo è.

`esx:setJob` con un lavoro non autorizzato chiude il tablet.
`onResourceStop` rilascia il focus NUI: senza, il mouse resterebbe catturato.

## Note e trappole

- **`MdtIsOpen()` è la funzione che `cl_notify.lua` usa** per decidere dove mandare una
  notifica. È definita qui, in un file caricato **dopo** `cl_notify.lua`: il controllo
  difensivo `if MdtIsOpen and MdtIsOpen()` è necessario, non ridondante.
- `bootstrapped` non viene mai rimesso a `false`: dopo la prima apertura resta vero per
  tutta la sessione. Va bene per `OpenMdtOn*`, ma significa che un `Invalidate` arriva alla
  NUI anche dopo una chiusura e riapertura senza nuovo bootstrap (che comunque avviene
  sempre).
- Il toggle in `OpenMDT` significa che premere F5 due volte apre e chiude. Il comando
  `openmdt` ha lo stesso comportamento.
- `lib.callback.await` **blocca** il callback NUI fino alla risposta del server: una query
  lenta blocca quella richiesta, non l'intera UI (le richieste NUI sono indipendenti).
- La geometria è mandata **prima** di `mdt:visible`: la UI ha già le misure quando si
  rende visibile, così non c'è un frame a dimensione sbagliata.
- **La finestra della cornice è dichiarata 2 px più larga del ritaglio reale**
  (`cutoutX 59`, `cutoutWidth 1280` invece di 60 e 1278). Il bordo del PNG è antialiasato
  su esattamente 1 px — a x=60 e x=1337 l'alpha è 54, cioè trasparente al 79% — e siccome
  l'immagine viene stirata l'arrotondamento sub-pixel lasciava quel pixel morbido senza UI
  dietro: in gioco si vedeva 1 px di gioco per lato. Con la sovrapposizione la colonna in
  più della UI finisce sotto la scocca nera, dove non si vede. In verticale la rampa è
  identica (alpha 122 a y=93 e y=980) ma la cucitura non si nota; se comparisse, la
  correzione è `cutoutY = 92` e `cutoutHeight = 890`.

## Correlati

[ARCHITECTURE.md](../ARCHITECTURE.md) §1, §3, §9 ·
[server/sv_main.md](../server/sv_main.md) ·
[web/components/DeviceFrame.md](../web/components/DeviceFrame.md) ·
[web/hooks/useTabletScale.md](../web/hooks/useTabletScale.md)

# client/cl_jail.lua

**Ruolo:** rappresentazione della detenzione: contatore a schermo e confinamento nell'area.
**Contesto:** client
**Caricato da:** `fxmanifest.lua`, dopo `cl_drag.lua`

## Cosa fa

Il tempo residuo è **quello che dice il server**: qui si mostra solo il contatore e si
impedisce al detenuto di allontanarsi.

| Evento | Azione |
|---|---|
| `KF_Police:Client:Jailed` | salva `jailData`, teletrasporta in cella, `RemoveAllPedWeapons` se richiesto, mostra il timer |
| `KF_Police:Client:JailTick` | aggiorna `secondsRemaining` e riscrive il timer |
| `KF_Police:Client:Released` | azzera lo stato, nasconde il timer, teletrasporta al punto di rilascio |

`showTimer()` usa `lib.showTextUI` in `top-center` con
`Locale('jail_time_left', FormatDuration(secondsRemaining))` più il motivo.

## Confinamento

Un ciclo ogni 2 s (3 s se non detenuto): se la distanza dal centro di
`jailData.bounds` (o `Config.Jail.Bounds`) supera il raggio, riporta alle coordinate della
cella (o al centro) e notifica `jail_cannot_leave`.

## API pubblica

`IsLocalPlayerJailed()` — esposta, **nessuno la chiama**. Aggancio per altri script.

## Note e trappole

- **Il confinamento è interamente client-side.** Un client modificato esce dall'area senza
  che il server se ne accorga: il server non verifica la posizione del detenuto. Se serve
  chiuderlo, va aggiunto un controllo periodico lato server in `sv_jail.lua`.
- Il timer si aggiorna **solo quando arriva un `JailTick`**, cioè ogni
  `Config.Jail.Tick` (5 s): il contatore a schermo scende a scatti di 5 s, non
  secondo per secondo.
- `RemoveAllPedWeapons` sul client è **in aggiunta** a `Inventory.StripWeapons` sul server:
  il primo tolgono le armi dal ped, il secondo dall'inventario.
- Il teletrasporto usa `SetEntityCoords` con tutti i flag a `false`: nessun controllo di
  collisione. Coordinate sbagliate in `cfg_jail.lua` mettono il detenuto sotto la mappa.
- `onResourceStop` nasconde il TextUI: senza, il contatore resterebbe a schermo.
- Il controllo ogni 2 s significa che si può uscire dall'area e rientrare senza essere
  riportati indietro, se si è abbastanza rapidi.

## Correlati

[config/cfg_jail.md](../config/cfg_jail.md) · [server/sv_jail.md](../server/sv_jail.md)

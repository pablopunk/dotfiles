# Kanata

Install and enable startup with `dot -i kanata` from `~/.dotfiles`.
The postlink hook needs `sudo`: macOS uses root LaunchDaemons for Kanata and
the standalone virtual HID driver; Linux uses a root systemd service and
loads `uinput` at boot.

## macOS prerequisites

- Kanata 1.12.0 needs [VirtualHIDDevice 6.2.0](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/tag/v6.2.0).
  Kanata 1.13.0 and newer need driver 8.0.0; update both together.
- Approve the driver extension in System Settings.
- Give the Kanata binary Input Monitoring and Accessibility permissions.
- Stop Karabiner-Elements before starting Kanata; uninstall it after testing,
  then reinstall the standalone driver if the uninstaller removes it.

## Rule migration

| Karabiner rule | Kanata behavior |
| --- | --- |
| Caps Lock tap / held layer | Tap Caps Lock; hold for the media/navigation layer; 150 ms threshold, early hold on another key |
| Caps + Q/W/E | Mute / volume down / volume up |
| Caps + A/S/D | macOS and Linux rewind / play-pause / fast-forward; Windows previous track / play-pause / next track |
| Caps + U/I/O/P | Existing right-Option symbol chords on macOS; right-Alt equivalents elsewhere, dependent on the OS layout |
| Caps + H/J/K/L | Left / down / up / right, with other held modifiers retained |
| Physical left Option tap | One-shot Control + Alt + Meta, **without Shift**, with a 1000 ms timeout |
| Physical left Option hold | Normal Option/Alt; Command on the two swapped keyboards |
| Option tap, then press and hold | Held Control + Alt + Meta until release |
| Modifier swaps | macOS VID:PID 12815:20550 and 1452:592 only; handled before the tap/hold choice |
| Grave / ISO backslash swap | macOS only; Linux and Windows retain their native positions |
| F3 / F4 | macOS Mission Control / Launchpad; Fn restores F3/F4 |
| F5 / F6 | macOS **keyboard illumination**, not display brightness; Fn restores F5/F6 |
| Home-row modifiers | Remain disabled; not included in the active keymap |
| Space tap / four-modifier Hyper hold | Remains disabled; not included in the active keymap |
| Menu-bar visibility / ISO virtual keyboard preference | Karabiner settings, not shared remapping rules; check ISO symbol output manually |

The tap/hold timings differ from Karabiner's immediate modifier output and
its default tap-alone timeout; test fast shortcuts and double taps.
The second Option press holds Hyper immediately; a second tap consumes the
pending one-shot rather than toggling each modifier separately.

## Devices and platforms

`start.sh` reads connected devices at service startup and allows only non-ZSA
devices (vendor `12951` / `0x3297` is excluded), including neither Voyager HID
interface; a Voyager connected later is also outside this allowlist.
On macOS it also excludes virtual HID keyboards to prevent feedback.
Restart the service after connecting a new non-ZSA keyboard.
With no eligible device, startup fails and the service retries rather than
using an unrestricted device list.

Kanata 1.12 device-history mappings are macOS-only and are matched at startup.
Linux and Windows use the common Caps and left-Alt rules; matching hardware
swaps on those platforms needs separate device-specific instances or firmware
normalization.
Windows can use the keymap but is not covered by these startup scripts or
the automatic vendor-ID exclusion.

## Checks and manual validation

```sh
kanata --check --cfg ~/.config/kanata/kanata.kbd
bash ~/.config/kanata/start.sh "$(command -v kanata)" ~/.config/kanata --check
```

After setup, test Caps tap/hold, Shift + Caps + arrows, all media keys,
`[]{}` symbol output, normal Alt/Option shortcuts, one-shot timeout,
tap-then-hold Hyper, the swapped keyboards, and an unchanged Voyager.
Hold physical Left Control + Space + Escape to exit Kanata.

macOS logs: `/var/log/kanata.log`; status: `sudo launchctl print system/dev.kanata`.
Linux logs: `journalctl -u kanata.service`; status: `systemctl status kanata.service`.
Stop the old xremap service before using Kanata on Linux.
Restart with `sudo launchctl kickstart -k system/dev.kanata` on macOS or
`sudo systemctl restart kanata.service` on Linux.

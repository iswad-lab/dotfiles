# RME Babyface Pro FS — modes de fonctionnement

Ce dossier contient la config pour la carte son externe **RME Babyface Pro FS**
et l'audio interne du laptop. Deux modes mutuellement exclusifs pour la RME :

## Bascule CC ⇄ Propriétaire (TuxMix)

La bascule se fait par l'**extension du fichier** `50-tuxmix.conf` :

| Mode            | État du fichier                          | Pilotage de la RME          |
|-----------------|------------------------------------------|-----------------------------|
| **CC** (défaut) | `50-tuxmix.conf.disabled` (désactivé)    | Kernel driver (`snd-usb-audio`) via `51-rme.conf` |
| **Propriétaire**| `50-tuxmix.conf` (actif, renommer)       | Driver maison **TuxMix** (TotalMix, mode propriétaire) |

Passer en mode propriétaire :

```bash
mv ~/.config/pipewire/pipewire.conf.d/50-tuxmix.conf.disabled \
   ~/.config/pipewire/pipewire.conf.d/50-tuxmix.conf
systemctl --user restart pipewire pipewire-pulse
# le sink "RME Babyface Pro FS (TuxMix)" apparaît
pactl set-default-sink tuxmix
```

Revenir en mode CC (Class Compliant) :

```bash
mv ~/.config/pipewire/pipewire.conf.d/50-tuxmix.conf \
   ~/.config/pipewire/pipewire.conf.d/50-tuxmix.conf.disabled
systemctl --user restart pipewire wireplumber pipewire-pulse
```

> **Important** : le mode propriétaire et le mode CC ne peuvent pas tourner en
> même temps sur l'USB — un seul streaming session par appareil. Le driver
> TuxMix et le kernel driver `snd-usb-audio` ciblent la même interface.

## Interface interne Ryzen — quantum spécifique

- `custom-settings.conf` : quantum global par défaut = `64` (adapté au CC RME).
  Les `min-quantum`/`max-quantum` sont **volontairement retirés** pour ne pas
  verrouiller toutes les interfaces sur un plancher rigide.
- `52-ryzen-quantum.conf` (WirePlumber) : force `256` sur la carte interne
  Ryzen (`alsa_{output,input}.pci-0000_07_00.6.*`) seule — le 64 y cause des
  sous-runs. Ajuster `node.quantum.min/max` pour tester d'autres valeurs.

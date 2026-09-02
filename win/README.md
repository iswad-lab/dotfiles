# Windows 11 — dual boot helpers

Fichiers destinés à être exécutés **côté Windows** (ils ne sont pas déployés par chezmoi dans `~/`).

## 1. Horloge RTC en UTC (recommandé)

`enable-utc-clock.reg` fait comprendre à Windows que le RTC est en **UTC** (comme Linux).

- **Pourquoi** : sinon, à chaque fois que tu passes de Linux à Windows, l'horloge est décalée (Windows suppose que le RTC est en heure locale).
- **Comment** : double-clic + « Oui » (administrateur), puis redémarre une fois sous Windows.
- **Annuler** : retire la valeur `RealTimeIsUniversal` puis redémarre.

## 2. Désactiver « Fast Startup » (recommandé si tu montes tes NTFS sous Linux)

Windows 11 a un **démarrage rapide** (hybrid shutdown) qui laisse les volumes NTFS dans un état non démonté proprement. Si tu montes `C:` ou la partition `SHARED` en **lecture-écriture** sous Linux, cela peut corrompre le système de fichiers.

Dans une invite **Administrateur** sous Windows :

```powershell
# Désactive l'hibernation + le Fast Startup
powercfg /h off
```

`powercfg /h on` pour réactiver.

## 3. Partitions (rappel)

| Part. | Contenu | UUID | Rôle |
|---|---|---|---|
| `nvme1n1p2` | Windows `C:` | `01DD20323D16A210` | OS Windows — à ne **pas** monter en rw sous Linux (Fast Startup) |
| `nvme1n1p3` | `SHARED` (402 Go) | `5CAC12755C11BA05` | Données partagées entre OS — montable en rw (ntfs-3g) |

L'horloge Linux (`/etc/adjtime` = `UTC`) est déjà correcte — ne rien changer côté Linux.

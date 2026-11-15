# RWP Linux 0.3 Alpha — Construction d'ISO sur GitHub Actions

Ce dépôt fabrique une ISO Debian 13 (Trixie) **amd64/x86-64** avec KDE Plasma 6, Firefox ESR,
NetworkManager, PipeWire, Flatpak, Flathub préconfiguré et l'installateur Debian Live.
**Il ne contient pas d'ISO précompilée.**

## Compilation sans utiliser la RAM locale

1. Sur https://github.com/new, créer un dépôt **public** nommé `rwp-linux` (sans README initial).
2. Décompresser ce ZIP sur ton Mac / ta VM Fedora.
3. Publier tous les fichiers et sous-dossiers dans le dépôt, dont le dossier caché
   `.github/workflows/build-iso.yml` (important !), sur la branche principale `main`.
   Sur le site GitHub, « Add file » → « Upload files » ; sinon utiliser Git.
4. Dans GitHub, cliquer **Actions** → **Build RWP Linux x86-64 ISO** → **Run workflow**.
5. Quand le job est terminé avec succès, ouvrir son résumé et dans **Artifacts**
   télécharger `RWP-Linux-0.3-alpha-amd64`.
6. Décompresser l'archive GitHub téléchargée. Tu obtiendras
   `RWP-Linux-0.3-alpha-amd64.iso` et la somme SHA-256.
   L'ISO est destinée à UTM → Emulate → x86_64.

Si le job échoue, télécharger `RWP-build-logs` (ou consulter le journal en ligne).
L'échec peut venir des dépôts, des limites d'espace disque ou d'un bug du constructeur.
Le workflow est **à déclenchement manuel**, sans déclenchement automatique pour chaque commit.

## Pourquoi un dépôt public ?

Selon la documentation actuelle de GitHub, les runners Ubuntu standard des dépôts publics
disposent de 4 CPU / 16 Gio de RAM et les minutes Actions standard y sont gratuites.
En dépôt privé, la configuration et la facturation diffèrent.
Référence : https://docs.github.com/en/actions/reference/runners/github-hosted-runners

## Sécurité et limites

Le workflow utilise `docker run --privileged` sur un runner **éphémère de GitHub**,
parce que `live-build` doit effectuer des montages. N'exécuter que du code vérifié.
Cette ISO est un **prototype non validé** : sa compilation et son installation n'ont
pas encore été testées de bout en bout. Installer exclusivement sur un disque virtuel
jetable, jamais sur le disque principal.

Cette version corrige le nom du paquet Debian `spectacle` → `kde-spectacle`.
Avant le début du build, les paquets listés sont vérifiés via APT pour éviter
de perdre du temps sur un nom absent.

## Sources

- GitHub-hosted runners : https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- Déclenchement manuel : https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
- Actions Artifact : https://github.com/actions/upload-artifact
- Debian Live Manual : https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html
- Paquet `kde-spectacle` : https://packages.debian.org/trixie/kde-spectacle

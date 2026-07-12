# Présentation Tournois Pétanque Cap Fun

Ce dossier contient la page de présentation statique du projet et les builds Android à télécharger.

## Structure

- `index.html` : page principale, générée automatiquement — ne pas éditer à la main.
- `styles.css` : styles visuels aux couleurs du logo Cap Fun.
- `favicon.svg` / `logo.svg` : le badge pétanque Cap Fun, réutilisé depuis `assets/logo/`.
- `screenshots/` : captures d'écran affichées sur la page.
- `releases/` : builds APK versionnés, téléchargeables depuis la page.
- `generate_site.py` : script qui regénère `index.html` à partir du contenu de `releases/` et `screenshots/`.
- `build_release.sh` : compile l'APK, le copie dans `releases/` avec un nom versionné, puis régénère la page.

## Mettre à jour la page

Depuis la racine du projet :

```bash
docs/build_release.sh
```

Cela va :

1. Compiler un APK release (`flutter build apk --release`).
2. Le copier dans `docs/releases/tournois_petanque-<version>-<horodatage>.apk`.
3. Régénérer `docs/index.html` — le build le plus récent apparaît toujours en premier et devient le lien de téléchargement principal.

Pour ne régénérer que la page (par exemple après avoir ajouté une capture d'écran dans `docs/screenshots/`), sans reconstruire l'APK :

```bash
cd docs
python3 generate_site.py
```

## Publier la page

Sur GitHub, configurez GitHub Pages avec `docs/` comme dossier source de la branche principale. La page sera alors accessible directement, téléchargement d'APK compris.

#!/usr/bin/env python3
"""Generates docs/index.html for the Tournois Pétanque Cap Fun project.

Run after dropping a new APK in docs/releases/ (build_release.sh does this
for you automatically). Screenshots in docs/screenshots/ are picked up
automatically too.
"""
from pathlib import Path
import re
from datetime import datetime

ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent
PUBSPEC = REPO_ROOT / 'pubspec.yaml'
OUTPUT = ROOT / 'index.html'
CONTACT_EMAIL = 'philippe.lam.ny@gmail.com'

VERSION_PATTERN = re.compile(r'^version:\s*([0-9]+(?:\.[0-9]+)*(?:\+[0-9]+)?)', re.MULTILINE)

FEATURES = [
    (
        "Inscription libre des équipes",
        "Autant d'équipes que vous voulez. Nombre impair ? Pas de souci : une équipe se "
        "repose à chaque round, et jamais deux fois la même.",
    ),
    (
        "Round 1 — tirage au sort",
        "Les premiers matchs sont tirés à l'aveugle, pour un départ 100% équitable.",
    ),
    (
        "Rounds 2 & 3 — les meilleurs contre les moins bons",
        "Le classement du moment décide des matchs suivants, en évitant autant que "
        "possible de refaire jouer deux équipes qui se sont déjà affrontées.",
    ),
    (
        "Un chrono par partie",
        "35 minutes par défaut (réglable), avec une alerte à 5 minutes puis un signal "
        "« dernière mène » à 2 minutes de la fin.",
    ),
    (
        "Le score à la roulette",
        "Fini les fautes de frappe : on fait défiler une vraie roulette de boules pour "
        "choisir le score, de 0 à 13.",
    ),
    (
        "Podium automatique",
        "Classement final calculé tout seul, avec médailles or, argent et bronze pour "
        "le trio de tête.",
    ),
]


def parse_version():
    if not PUBSPEC.exists():
        return '0.0.0+0'
    text = PUBSPEC.read_text(encoding='utf-8')
    match = VERSION_PATTERN.search(text)
    return match.group(1) if match else '0.0.0+0'


def parse_build_timestamp(file_name):
    match = re.search(r'([0-9]{8}-[0-9]{4})', file_name)
    if not match:
        return None
    dt = datetime.strptime(match.group(1), '%Y%m%d-%H%M')
    return dt.strftime('%Y-%m-%d %H:%M')


def list_releases():
    release_dir = ROOT / 'releases'
    if not release_dir.exists():
        return []
    files = [p for p in release_dir.iterdir() if p.is_file() and not p.name.startswith('.')]
    files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return files


def web_app_available():
    return (ROOT / 'appli' / 'index.html').exists()


def list_screenshots():
    screenshot_dir = ROOT / 'screenshots'
    if not screenshot_dir.exists():
        return []
    files = [
        p for p in screenshot_dir.iterdir()
        if p.is_file() and p.suffix.lower() in {'.png', '.jpg', '.jpeg', '.webp'}
    ]
    files.sort(key=lambda p: p.name)
    return files


SCREENSHOT_CAPTIONS = {
    'screen_home_empty': "L'accueil, prêt à créer votre premier concours",
    'screen_registration': "Inscription des équipes — nombre impair géré automatiquement",
    'screen_round': "Un round en cours, chrono et exemption compris",
    'screen_score_roulette': "La roulette pour saisir le score, de 0 à 13",
    'screen_standings': "Le classement final et son podium",
}


def build_html(version, releases, web_app):
    updated = datetime.now().strftime('%Y-%m-%d %H:%M')
    if releases:
        latest_date = parse_build_timestamp(releases[0].name)
        if latest_date:
            updated = latest_date

    release_items = []
    if releases:
        for path in releases:
            mb = path.stat().st_size / 1024 / 1024
            built = parse_build_timestamp(path.name) or ''
            release_items.append(
                f'<li><a href="releases/{path.name}" download>{path.name}</a>'
                f'<span class="meta">{mb:.1f} Mo{" · " + built if built else ""}</span></li>'
            )
    else:
        release_items.append(
            '<li>Aucun build disponible pour le moment. Lancez '
            '<code>docs/build_release.sh</code> pour en générer un.</li>'
        )

    default_alt = "Capture d'écran de l'application"
    screenshot_items = []
    for shot in list_screenshots():
        caption = SCREENSHOT_CAPTIONS.get(shot.stem, '')
        caption_html = f'<p>{caption}</p>' if caption else ''
        alt_text = caption or default_alt
        screenshot_items.append(
            f'<div class="screen-card"><img src="screenshots/{shot.name}" '
            f'alt="{alt_text}" />{caption_html}</div>'
        )
    if not screenshot_items:
        screenshot_items.append(
            '<div class="screen-card"><p>Aucune capture pour le moment — ajoutez des '
            'PNG dans <code>docs/screenshots</code>.</p></div>'
        )

    feature_items = ''.join(
        f'<div class="feature-card"><h3>{title}</h3><p>{body}</p></div>'
        for title, body in FEATURES
    )

    latest_release_href = f'releases/{releases[0].name}' if releases else '#builds'
    latest_release_label = 'Télécharger la dernière version' if releases else 'Aucun build pour le moment'

    web_app_cta = (
        '<a class="cta secondary" href="appli/">🌐 Jouer dans le navigateur</a>'
        if web_app else ''
    )

    if web_app:
        web_app_section = '''<section>
      <h2>Utiliser la version web</h2>
      <p>Pas envie d'installer un APK ? L'appli tourne aussi directement dans le navigateur, sans rien installer.</p>
      <ul>
        <li><a href="appli/">Ouvrir l'appli web</a> — fonctionne sur ordinateur, tablette ou mobile.</li>
        <li>Les tournois sont sauvegardés dans le navigateur utilisé (pas de compte, pas de synchronisation entre appareils).</li>
        <li>Ajoutez la page à votre écran d'accueil pour un accès en un tap, comme une vraie appli.</li>
      </ul>
    </section>'''
    else:
        web_app_section = ''

    return f'''<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="theme-color" content="#E4231F" />
  <meta name="description" content="Cap Fun Pétanque — l'appli qui organise vos concours de pétanque en 3 rounds, tire au sort, chronomètre et calcule le classement." />
  <title>Tournois Pétanque Cap Fun</title>
  <link rel="icon" href="favicon.svg" type="image/svg+xml" />
  <link rel="stylesheet" href="styles.css" />
</head>
<body>
  <main>
    <section class="hero">
      <div class="hero-brand">
        <img src="logo.svg" alt="Logo Tournois Pétanque Cap Fun" class="hero-logo" />
        <div>
          <p class="eyebrow">Cap Fun · Application mobile</p>
          <h1>Tournois de pétanque, sans prise de tête !</h1>
          <p class="subtitle">L'appli qui tire les équipes au sort, chronomètre les parties et calcule le classement — pendant que vous, vous jouez aux boules.</p>
          <div class="hero-ctas">
            <a class="cta" href="{latest_release_href}" download>🎯 {latest_release_label}</a>
            {web_app_cta}
          </div>
        </div>
      </div>
      <div class="hero-badges">
        <span>Version {version}</span>
        <span>Dernière génération : {updated}</span>
      </div>
    </section>

    <section>
      <h2>Comment ça marche</h2>
      <div class="features-grid">
        {feature_items}
      </div>
    </section>

    <section class="screens">
      <h2>Aperçu</h2>
      <div class="screens-grid">
        {''.join(screenshot_items)}
      </div>
    </section>

    <section id="builds">
      <h2>Builds &amp; téléchargements</h2>
      <p>Chaque build est versionné et horodaté — le plus récent est toujours en haut.</p>
      <ul class="link-list release-list">
        {''.join(release_items)}
      </ul>
    </section>

    <section>
      <h2>Installer l'APK</h2>
      <p>L'application n'est pas encore sur le Play Store : installez le fichier APK directement.</p>
      <ul>
        <li>Téléchargez l'APK depuis la section <strong>Builds &amp; téléchargements</strong>.</li>
        <li>Ouvrez le fichier sur votre appareil Android.</li>
        <li>Autorisez l'installation depuis des sources externes si demandé : Paramètres &gt; Sécurité &gt; Installer des applications inconnues.</li>
        <li>Acceptez l'installation et lancez l'application — le premier match n'attend que vous.</li>
      </ul>
    </section>

    {web_app_section}

    <section class="callout">
      <h2>Mettre à jour cette page</h2>
      <p>Depuis la racine du projet, lancez :</p>
      <pre>docs/build_release.sh</pre>
      <p>Le script compile un APK release, le copie versionné dans <code>docs/releases/</code> et régénère cette page automatiquement.</p>
    </section>

    <section class="contact-block">
      <h2>Une idée, une envie de fonctionnalité ?</h2>
      <p>Écris-moi :</p>
      <p class="contact-link"><a href="mailto:{CONTACT_EMAIL}?subject=Id%C3%A9e%20Tournois%20P%C3%A9tanque%20Cap%20Fun">{CONTACT_EMAIL}</a></p>
    </section>
  </main>
</body>
</html>
'''


def main():
    version = parse_version()
    releases = list_releases()
    web_app = web_app_available()
    html = build_html(version, releases, web_app)
    OUTPUT.write_text(html, encoding='utf-8')
    print(
        f'Généré {OUTPUT.relative_to(ROOT)} — {len(releases)} build(s), '
        f'{len(list_screenshots())} capture(s), appli web {"présente" if web_app else "absente"}'
    )


if __name__ == '__main__':
    main()

# Soutenance de stage — Marc Duboc

Support de soutenance FISE A2 consacré au stage **Security for UAV-Based 5G-Advanced and 6G Networks**, réalisé à KAUST du 7 avril au 31 juillet 2026.

## Livrables

- `presentation/soutenance-stage-marc-duboc.pptx` : présentation éditable, exactement cinq diapositives ;
- `presentation/soutenance-stage-marc-duboc.pdf` : export final pour la visioconférence ;
- `content/oral-script-full.md` : script principal de 603 mots ;
- `content/oral-script-4min.md` : version de secours de 457 mots ;
- `content/speaker-cards.md` : cartes mémoire ;
- `content/jury-questions.md` : quarante questions avec réponses courtes et développées ;
- `sources/source-traceability.md` : inventaire, chronologie, qualification des résultats et traçabilité ;
- `content/confidentiality-review.md` : décisions d'anonymisation ;
- `content/timing-review.md` : simulation à 125, 135 et 145 mots/minute.

## Modifier le contenu

1. Modifier d'abord `content/slide-content.md`, qui contient le texte affiché et la fonction de chaque zone.
2. Répercuter le changement dans le PowerPoint en préservant les cadres hérités du support de référence.
3. Si le discours change, mettre à jour `content/oral-script-full.md` et les notes orateur du PowerPoint.
4. Mettre à jour `sources/source-traceability.md` et `assets/charts/performance-data.csv` pour toute nouvelle mesure.
5. Reconstruire, exporter et valider avec les commandes ci-dessous.

La refonte suit le langage visuel des deux présentations fournies par Marc : fond clair, grands titres, règle graphite, cartes arrondies et un visuel dominant. Les schémas de méthode et de résultats sont des SVG embarqués ; les photographies proviennent des supports fournis.

## Prérequis

- Python 3.11 ou supérieur avec `lxml` et `pypdf` ;
- Node.js 18 ou supérieur ;
- le runtime de présentation contenant `@oai/artifact-tool` ;
- LibreOffice ou `soffice` pour l'export PDF ;
- Poppler, notamment `pdfinfo`, pour contrôler le PDF.

Variables facultatives :

- `NODE` : chemin explicite vers Node.js ;
- `CODEX_PRESENTATIONS_SKILL_DIR` : dossier du runtime de présentation si sa détection automatique échoue ;
- `SOFFICE` : chemin explicite vers LibreOffice/soffice.

## Police

La seule police requise est **Arial** :

- Arial Bold pour les titres, chiffres et libellés ;
- Arial Regular pour les explications et métadonnées.

En cas de substitution de police, vérifier à nouveau chaque diapositive car les retours à la ligne peuvent changer.

## Modifier le PowerPoint

Le fichier `presentation/soutenance-stage-marc-duboc.pptx` est la version canonique. La refonte a été réalisée par duplication de cadres issus de `Présentation Charlotte V2.pptx`, puis édition des éléments hérités. Ne pas relancer l’ancien générateur sombre : il ne correspond plus au design validé. Pour une refonte automatisée ultérieure, repartir du même support de référence et appliquer la procédure *template-following* du runtime de présentation.

## Exporter le PDF

```bash
./scripts/export_pdf.sh
```

Le script exporte le PowerPoint, vérifie que le PDF contient cinq pages et écrit :

```text
presentation/soutenance-stage-marc-duboc.pdf
```

## Valider automatiquement

```bash
python3 scripts/validate_presentation.py
```

La validation contrôle :

- exactement cinq diapositives et cinq pages PDF ;
- présence des blocs `[Sources]` dans les notes des cinq diapositives ;
- titres d'au moins 20 pt et texte public d'au moins 12 pt hors métadonnées approuvées ;
- existence des médias référencés ;
- conformité des valeurs `89`, `100`, `52` et `68 Mbit/s` avec le CSV source ;
- présence du diagnostic `MCS 5 → 24-27` ;
- absence de marqueur de travail, d'adresse privée, d'identifiant d'abonné, d'adresse électronique et de nom d'hôte historique ;
- absence de débordement hors diapositive ;
- comptage de 603 mots pour le script principal et 457 pour la version de secours.

Un résultat `VALIDATION RÉUSSIE` est nécessaire mais ne remplace pas le contrôle visuel.

## Contrôle visuel final

Après chaque modification :

1. rendre les cinq diapositives en images avec l'outil `render_slides.py` du runtime de présentation ;
2. inspecter chaque page à sa taille réelle, pas seulement une planche contact ;
3. vérifier les retours à la ligne, alignements, contraste et taille des nombres ;
4. exporter le PDF puis rendre ses cinq pages avec Poppler ;
5. relire les notes et refaire la recherche de contenu sensible.

## Vérifier manuellement le nombre de diapositives

Dans PowerPoint, le volet de gauche doit afficher uniquement `1` à `5`. En ligne de commande, `scripts/validate_presentation.py` effectue le même contrôle dans la structure interne du PPTX et dans le PDF.

## Confidentialité

Ne jamais ajouter au support : identifiants d'abonné, secrets, adresses réseau, noms de machines, captures brutes, journaux ou procédures exploitables de falsification d'alerte. Utiliser des rôles génériques et des preuves agrégées. Toute nouvelle capture doit passer par la revue décrite dans `content/confidentiality-review.md`.

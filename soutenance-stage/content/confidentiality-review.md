# Revue de confidentialité et d'intégrité

## Périmètre public du support

Le PowerPoint et son PDF peuvent exposer :

- l'intitulé officiel du stage ;
- les noms des organismes, encadrants et plateformes matérielles ;
- l'architecture fonctionnelle générique CU/DU/F1 ;
- des débits agrégés et qualifiés comme meilleurs runs ;
- les contributions personnelles et les limites scientifiques.

Ils ne doivent jamais exposer :

- identifiants d'abonné ou de carte SIM ;
- clés, mots de passe, jetons, secrets WireGuard ou certificats ;
- adresses IP, noms d'hôtes ou chemins privés de laboratoire ;
- journaux, captures réseau ou configurations brutes ;
- message d'hameçonnage, URL d'essai ou procédure exploitable de falsification ;
- données personnelles de contact présentes dans le document de mission.

## Décisions prises

| Élément source | Risque | Décision finale |
|---|---|---|
| Anciennes captures de console | Adresses et noms internes visibles | Écartées ; remplacées par des schémas natifs |
| Captures de téléphones du document officiel | URL d'essai et interface utilisateur identifiable | Non intégrées au support |
| Rapports techniques | Identifiants d'abonné et paramètres réseau dans certains passages | Utilisés uniquement pour vérifier les affirmations ; aucun extrait brut |
| Résumés privés de runs | Traces internes et chemins locaux | Mention de la catégorie de preuve seulement |
| Valeurs de débit | Risque de comparaison trompeuse | Machine, transport et nature « meilleur run » affichés |
| Objectif de falsification d'alerte | Sujet sensible et potentiellement dual | Formulé comme recherche contrôlée ; aucun mode opératoire |
| Dimensionnement UAV | Peut être pris pour un vol réussi | Mention explicite « vol non réalisé » |
| Mitigation de sécurité | Prévue dans la mission mais non validée | Absente des résultats ; présentée comme suite possible en questions-réponses |

## Contrôle automatisé prévu

Le script `scripts/validate_presentation.py` recherche dans le PPTX et les contenus :

- marqueurs de travail non résolus ;
- motifs d'adresses privées IPv4 ;
- mots associés aux secrets et identifiants d'abonné ;
- noms d'hôtes historiques connus ;
- tailles de police inférieures au seuil ;
- absence du PDF ou nombre de diapositives différent de cinq.

Cette recherche automatique complète une inspection visuelle ; elle ne la remplace pas.

## Statut avant export final

| Contrôle | Statut |
|---|---|
| Aucun secret ou identifiant d'abonné dans le contenu public | Conforme |
| Aucun nom d'hôte ou adresse interne dans le contenu public | Conforme |
| Résultat `68 Mbit/s` qualifié comme meilleur run | Conforme |
| Absence de vol explicitement indiquée | Conforme |
| Absence de mitigation de sécurité revendiquée | Conforme |
| Notes de sources sans données sensibles | Conforme |
| Inspection de toutes les pages du PDF final | Conforme |

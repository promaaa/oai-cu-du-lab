# Trame narrative des cinq diapositives

## Arc général

La soutenance suit une seule question : **comment passer d’un scénario de sécurité UAV/5G à une plateforme expérimentale dont chaque état peut être prouvé ?**

Le récit progresse ainsi :

1. scénario officiel et frontière du travail ;
2. problème de sécurité reformulé en observabilité ;
3. architecture et méthode de preuve ;
4. résultats fonctionnels et repères de performance ;
5. bilan, limites et prochaine validation.

## Diapositive 1 — Sujet officiel et thèse

**Titre visible**

*Security for UAV-Based 5G-Advanced and 6G Networks*

**Message oral**

Le stage ne revendique pas un vol. Il construit le banc au sol nécessaire pour évaluer ensuite un nœud 5G déportable et sa sécurité.

**Rôle du visuel**

La photographie nocturne avec drone installe le scénario sans ajouter de texte explicatif.

## Diapositive 2 — Du scénario au problème scientifique

**Titre visible**

**Sécuriser commence par rendre le système observable**

**Trois idées**

- besoin opérationnel : couverture d’urgence ;
- risque : DU mobile et transport F1 sans fil ;
- mission : prouver le service et le chemin réseau sur un banc au sol.

**Point d’attention**

Le visuel UAV est illustratif. Dire explicitement qu’il ne constitue pas une preuve de vol.

## Diapositive 3 — Architecture et méthode

**Titre visible**

**Un banc 5G conçu comme une chaîne de preuves**

**Chaîne technique**

5G Core + CU sur x86 → F1 sur Ethernet, Wi-Fi/GRE ou 5G/WireGuard → DU ARM + B210 → terminal commercial.

**Gates de validation**

Chemin F1, association CU-DU, Internet sur le terminal, PWS affiché.

**Méthode**

Baseline, hypothèse, mesure, correction, reproduction, rollback.

## Diapositive 4 — Résultats qualifiés

**Titre visible**

**Trois F1 validés ; 68 Mbit/s sur Jetson**

**Ordre de présentation**

1. preuve fonctionnelle de bout en bout ;
2. trois repères de débit avec leurs configurations ;
3. qualification « meilleurs runs distincts » ;
4. diagnostic MSS/BLER/MCS.

**Interdit**

Ne pas présenter les trois valeurs comme une comparaison statistique ni comme des moyennes.

## Diapositive 5 — Bilan et frontière

**Titre visible**

**Une base vérifiable avant l’intégration UAV**

**Trois statuts**

- validé : service de bout en bout ;
- livré : banc reproductible ;
- à faire : répétitions, mesure électrique et intégration UAV.

**Dernière phrase**

Rendre un système distribué observable et réversible avant de le miniaturiser est le principal acquis d’ingénieur du stage.

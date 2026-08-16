# Contenu des cinq diapositives

## 1. Security for UAV-Based 5G-Advanced and 6G Networks

**Sous-titre visible**

Marc Duboc · KAUST — SeRBER · IMT Atlantique · 7 avril–31 juillet 2026

**Intention**

Introduire le sujet officiel et annoncer immédiatement la frontière : le travail présenté est une validation au sol d’un nœud 5G distribué, pas une démonstration en vol.

## 2. Sécuriser commence par rendre le système observable

**Carte gauche**

- **BESOIN** — Rétablir rapidement une couverture 5G après une crise.
- **RISQUE** — Une DU mobile et un F1 sans fil élargissent la surface d’attaque.
- **MISSION** — Construire un banc au sol qui prouve PWS, données et chemin F1.

**Visuel**

Illustration du scénario UAV issue du support de référence. Elle donne le contexte et ne constitue pas une preuve de vol.

## 3. Un banc 5G conçu comme une chaîne de preuves

**Architecture**

- 5G Core + CU sur x86 ;
- F1-C et F1-U sur Ethernet, Wi-Fi/GRE ou 5G/WireGuard ;
- DU sur Raspberry Pi puis Jetson, avec USRP B210 ;
- terminal commercial pour la preuve de service.

**Quatre preuves**

1. chemin F1 réellement emprunté ;
2. association CU-DU établie ;
3. terminal enregistré avec Internet ;
4. alerte PWS affichée.

**Méthode**

Baseline → hypothèse → mesure → correction → reproduction → rollback.

## 4. Trois F1 validés ; 68 Mbit/s sur Jetson

**Preuve fonctionnelle**

F1 sur trois transports, terminal enregistré, Internet et PWS affiché.

**Repères de débit**

- `89 Mbit/s soutenus`, environ `100 Mbit/s en pic` — x86, Ethernet ;
- `52 Mbit/s max` — x86, Wi-Fi/GRE ;
- `68 Mbit/s max` — Jetson, 5G/WireGuard, run final officiellement validé.

Ces sessions ont été réalisées avec des hôtes et conditions distincts. Elles ne constituent pas une moyenne ni un classement contrôlé.

**Diagnostic**

MSS et fenêtre BLER corrigés ; MCS dominant de `5` à `24–27` sur le run Ethernet.

## 5. Une base vérifiable avant l’intégration UAV

**VALIDÉ — Service de bout en bout**

F1 ×3 · Internet UE · PWS affiché.

**LIVRÉ — Banc reproductible**

DU ARM · noyau SCTP · preuves + rollback.

**À FAIRE — Validation en conditions réelles**

Répéter les essais · mesurer la puissance · intégrer l’UAV.

**Repère final**

`68 Mbit/s` — Jetson + 5G/WireGuard, meilleur run validé, pas une moyenne.

**Frontière scientifique**

Pas de vol, pas de campagne RF répétée, pas de mesure électrique intégrée et pas de mitigation de sécurité validée.

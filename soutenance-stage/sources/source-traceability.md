# Traçabilité des sources et cadrage scientifique

## 1. Méthode de qualification

La soutenance doit distinguer quatre niveaux de preuve :

- **Validé** : observation de bout en bout ou mesure consignée dans un rapport daté, avec un état utilisateur ou système observable.
- **Validé comme instantané** : valeur observée dans un essai, mais ni moyenne ni comparaison statistique entre configurations.
- **Consolidé, à confirmer** : valeur reprise dans une synthèse ou un brouillon plus récent, sans trace primaire correspondante disponible dans le corpus consulté.
- **Non validé** : estimation, dimensionnement, essai incomplet ou étape future.

Le support public ne doit contenir ni adresse réseau interne, ni nom d'hôte, ni identifiant d'abonné, ni capture brute, ni secret. Les traces privées ne servent qu'à vérifier la cohérence des affirmations.

## 2. Inventaire raisonné des sources

| ID | Source | Apport | Statut et usage retenu |
|---|---|---|---|
| `REQ` | Cahier des charges de la soutenance fourni avec la demande | Format, cinq diapositives, durée, livrables, posture et contraintes | Source directrice pour la narration et la production |
| `GRID` | *Grille Evaluation Soutenance_Stage FISE A2_V2*, version 2026-06 | Critères BC03 : problématisation, méthode, analyse, contributions, recul, qualité du support et argumentation | Grille de contrôle ; aucune pondération chiffrée cachée n'a été trouvée |
| `MISSION` | *KAUST_IMT_CellularSecurity_v2.pdf*, document officiel fourni le 5 août 2026 | Intitulé, contexte cybersécurité/UAV, objectifs et encadrement | Source de référence pour le titre et la mission officielle |
| `LAB-README` | `README.md` du dépôt canonique | Architecture opérable, transports F1, plateformes DU, procédures de validation et de retour arrière | État fonctionnel consolidé ; ne suffit pas seul pour attester une mesure |
| `LAB-HISTORY` | Historique Git du dépôt canonique | Dates de consolidation, outillage, correctifs, baselines et évolution des débits | Source de chronologie et de contributions ; les anciens documents de statut supprimés sont utilisés comme contexte historique, pas comme état courant |
| `LAB-EVIDENCE` | `docs/evidence/PWS-F1.md`, `BENCHMARKS.md`, `RESOURCE_PROFILE.md` et CSV associés | Preuves assainies du chemin PWS, des essais de service, des débits et des ressources | Source publique principale pour les résultats ; les données privées du laboratoire restent hors du corpus publié |
| `PAPER-DRAFT` | `docs/PDFs/research-paper.tex` | Synthèse scientifique la plus récente, matrice de bancs, diagnostic MCS/BLER, dimensionnement de charge utile, limites | Brouillon local non versionné ; le résultat `68 Mbit/s` a ensuite été confirmé explicitement par l'étudiant le 5 août 2026 |
| `OLD-SLIDES` | [Présentation Charlotte V2](https://docs.google.com/presentation/d/1PTyXXZYdgLUkJzEHDRDvrb-UP5atUvs2Kw81VID5y84/edit) et [Présentation stage](https://docs.google.com/presentation/d/1-PejsoKiz7iE7Y6ZO_rdnELiBxwlDJI5kkbP2ylJjug/edit) | Photos, premiers schémas, contributions, choix de drone et traces de l'évolution du discours | Référence visuelle uniquement ; chiffres anciens, captures internes et illustrations ambiguës écartés |
| `RUNTIME-GATES` | Résumés privés et assainis des portes de validation de juillet 2026 | Prévol matériel, cœur, transport, CU, DU, F1 et retour arrière | Confirme la reproductibilité machine ; ne prouve pas à lui seul PWS, état du téléphone et débit dans le même run |
| `KERNEL` | Dépôt local `jetson-kernel-sctp` | Construction reproductible d'un noyau Jetson avec SCTP, entrée de démarrage séparée, vérification et retour arrière | Preuve d'un livrable technique personnel et réutilisable |
| `KAUST-WEB` | [Groupe SeRBER](https://serber.kaust.edu.sa/) et [profils officiels](https://serber.kaust.edu.sa/profiles/table) | Positionnement du groupe dans la recherche expérimentale en sécurité des réseaux ; fonctions de Marc Dacier et Ammar El Falou | Recoupe l'encadrement KAUST indiqué dans `MISSION` |

### Sources absentes ou incomplètes

- Le document officiel fixe l'intitulé **Security for UAV-Based 5G-Advanced and 6G Networks** et nomme Prof. Marc Dacier, Dr Ammar El Falou et Prof. Charlotte Langlais comme encadrants. L'association au groupe SeRBER est recoupée par les profils KAUST.
- Les répertoires historiques `monolithic`, `cu-du` et `cu-du-backhauling` ne sont pas disponibles comme dépôts Git locaux autonomes ; le dépôt canonique en consolide aujourd'hui les procédures.
- Le commit OAI de référence documenté est `102965a669b9444857c27843ec8ce62780bf9d37`. Le checkout OAI local consulté pointe vers un autre commit de développement ; il ne doit donc pas être présenté comme le commit des mesures.
- Les traces primaires correspondant au résultat Jetson de `68 Mbit/s` n'ont pas été retrouvées dans les résumés de runs consultés ; l'étudiant a néanmoins confirmé le 5 août 2026 qu'il s'agit d'un résultat final officiellement validé.

## 3. Chronologie reconstituée

| Période | Étape et décision d'ingénierie | Résultat ou apprentissage | Sources |
|---|---|---|---|
| 7–20 avril 2026 | État de l'art, émulation et déploiement du cœur 5G | Mise en place du socle ; SCTP identifié comme verrou initial sur Jetson | `LAB-HISTORY` |
| 21–30 avril | Banc x86, B210 et premier terminal commercial ; faisabilité Raspberry Pi à bande réduite | Cellule monolithique et alerte PWS observables ; première baseline radio | `LAB-HISTORY`, `LAB-EVIDENCE` |
| 1–10 mai | Passage en split CU/DU et adaptation du chemin SIB8/PWS sur F1 | Gestionnaire DU, mémoire du payload, décodage explicite et configuration corrigés ; PWS visible sur terminal | `LAB-HISTORY`, `LAB-EVIDENCE` |
| 11–17 mai | Diagnostic d'un terminal non attaché puis d'un débit radio faible | Séparation du plan de données sain et du problème BLER/MCS ; service utilisateur rétabli par profil radio | `LAB-HISTORY`, `LAB-EVIDENCE` |
| 18–19 mai | F1 sur Wi-Fi avec GRE et routage par politique | F1-C/F1-U empruntent le tunnel ; PWS validé ; premier débit encore limité | `LAB-HISTORY`, `LAB-EVIDENCE` |
| 20 mai–1er juin | Backhaul Quectel, QMI et WireGuard | Tunnel 5G prouvé ; l'architecture à une seule radio révèle une dépendance circulaire | `LAB-HISTORY`, `LAB-README` |
| 2–7 juin | Séparation de la cellule d'accès B210 et du modem donneur ; vérifications en cage | Pivot architectural : B210 pour l'accès, Quectel pour le backhaul ; identité de source et chemin paquet contrôlés | `LAB-HISTORY`, `LAB-README` |
| 8–21 juin | Automatisation, prévols, retour arrière, portage Pi et instrumentation BLER/MCS | La limite apparente de débit n'est pas résolue par un hôte plus puissant ; nécessité d'une analyse croisée transport/radio | `LAB-HISTORY`, `LAB-EVIDENCE` |
| 22–24 juin | Réglage MSS/MTU et fenêtre BLER du scheduler | MCS dominant de 5 vers 24–27 ; Ethernet mesuré à 89 Mbit/s soutenus et environ 100 Mbit/s en pic | `LAB-HISTORY`, `LAB-EVIDENCE` |
| 25 juin–2 juillet | Portage Jetson : noyau SCTP, chemin USB 3 et répartition CPU/IRQ | F1, PWS, enregistrement et Internet obtenus sur Jetson ; le chemin X310 à 106 PRB reste bloqué | `LAB-HISTORY`, `LAB-EVIDENCE`, `KERNEL` |
| 3–16 juillet | Stabilisation des profils embarqués et backhaul 5G/WireGuard | Pi et Jetson intégrés à la matrice de validation | `LAB-HISTORY`, `LAB-EVIDENCE` |
| 17–29 juillet | Consolidation du lanceur, des portes de preuve, de la documentation et du dimensionnement | Banc reproductible avec rollback ; meilleur run Jetson final à 68 Mbit/s ; charge utile dimensionnée mais non embarquée ni mesurée en vol | `LAB-HISTORY`, `PAPER-DRAFT`, confirmation du 5 août, `RUNTIME-GATES` |

## 4. Résultats validés, conditionnels et non validés

### Résultats utilisables dans la soutenance

| Affirmation | Qualification | Preuve disponible | Traitement recommandé |
|---|---|---|---|
| Une alerte PWS/SIB8 traverse le split F1 et s'affiche sur un terminal 5G commercial | **Validé de bout en bout** | `LAB-EVIDENCE` | Résultat fonctionnel central de la diapositive 4 |
| Le terminal s'enregistre, obtient une session de données et accède à Internet | **Validé de bout en bout** | `LAB-EVIDENCE` | Présenter comme une chaîne de service, pas comme un simple processus lancé |
| F1 fonctionne sur Ethernet, Wi-Fi/GRE et 5G/WireGuard | **Validé**, avec essais réalisés à des dates et sur des hôtes différents | `LAB-EVIDENCE`, `LAB-README` | Montrer trois transports ; ne pas les classer statistiquement |
| Des DUs réelles fonctionnent sur Raspberry Pi 5 et Jetson Orin Nano avec B210 | **Validé sur banc** | `LAB-EVIDENCE`, `LAB-README` | Prouve l'embarquabilité du calcul, pas un déploiement aérien |
| Un noyau Jetson reproductible avec SCTP et rollback a été produit | **Validé comme livrable** | Dépôt `jetson-kernel-sctp` et historique de juillet | Exemple concret de contribution personnelle |
| Ethernet x86 : 89 Mbit/s soutenus, environ 100 Mbit/s en pic après correction MSS/BLER | **Validé comme instantané instrumenté** | `LAB-EVIDENCE`, brouillon d'article | Afficher `89 soutenus / 100 pic`, avec la mention « un run, pas une moyenne » |
| Wi-Fi/GRE x86 : 52 Mbit/s | **Validé comme meilleur instantané** | `LAB-EVIDENCE` | Repère secondaire ; ne pas l'opposer directement aux autres hôtes |
| Raspberry Pi 5 sur 5G/WireGuard : 48 Mbit/s | **Validé comme meilleur instantané** | `LAB-EVIDENCE` | Repère de faisabilité ARM, avec prudence comparative |
| Jetson sur 5G/WireGuard : 68 Mbit/s | **Validé comme meilleur instantané final** | Brouillon d'article et confirmation explicite de l'étudiant le 5 août 2026 | Afficher `68 Mbit/s`, avec la mention « meilleur run documenté, pas une moyenne » |

### Résultats à ne pas présenter comme acquis

| Affirmation | Statut | Pourquoi | Formulation sûre |
|---|---|---|---|
| Jetson sur 5G/WireGuard à 40–44 Mbit/s | **Résultat intermédiaire** | Anciennes observations, antérieures au meilleur run final | Utiliser en questions-réponses pour expliquer la progression vers 68 Mbit/s |
| Mini-PC sur 5G/WireGuard à 78 Mbit/s | **Consolidé, à confirmer** | Mention de récapitulatif sans campagne primaire retrouvée | Ne pas utiliser dans les cinq diapositives |
| Comparaison de performance intrinsèque des trois transports | **Non démontré** | Hôtes, dates, conditions RF et réglages différents ; valeurs maximales, pas moyennes | Dire « repères de runs distincts », pas « le plus rapide » |
| Charge utile Jetson complète, environ 1,6 kg, batterie 44,4 Wh et plafond 50 W | **Dimensionnement** | Masse itemisée et puissance calculée, pas campagne de mesures électriques intégrée | Présenter au besoin comme faisabilité estimée, pas comme performance validée |
| Vol du système, mobilité aérienne ou couverture en situation | **Non réalisé** | Aucun essai en vol dans le corpus | Dire explicitement « prochaine étape » |
| B205mini-i comme radio d'accès | **Non testé** | Choix envisagé pour réduire la masse | Ne pas l'inclure dans l'architecture validée |
| Plusieurs DUs simultanées ou essaim de drones | **Non réalisé** | Le banc valide une brique, pas un système multi-DU | Le garder pour la perspective de recherche |
| X310 à 106 PRB | **Essai non concluant** | Débordements sur le chemin hôte–radio, même après remplacement du câble | Utiliser comme exemple de limite et de diagnostic, pas comme résultat fonctionnel |
| Intervalles de confiance, moyennes répétées et classement des bearers | **Non disponibles** | Pas de campagne contrôlée à conditions RF fixes | Limite méthodologique explicite |

## 5. Contradictions et arbitrages

1. **Jetson 40–44 contre 68 Mbit/s.** Les anciennes observations documentent 44 puis environ 40 Mbit/s. Le brouillon d'article plus récent annonce 68 Mbit/s après lancement propre, valeur confirmée officiellement par l'étudiant le 5 août. Le support retient donc `68`, en la qualifiant de meilleur run et non de moyenne.
2. **Anciens graphiques contre matrice récente.** Les anciens supports utilisent notamment `150 / 23 / 12 / 50`. Ils sont remplacés par les preuves assainies du dépôt canonique et ne doivent pas être réemployés.
3. **Capacité actuelle contre fraîcheur de preuve.** L'outillage consolidé signale les scénarios comme disponibles, mais une porte machine n'établit pas automatiquement PWS, état du terminal et débit dans un même essai.
4. **« Déploiement réel » contre banc au sol.** Le matériel a été dimensionné pour une charge utile, mais aucun vol n'a été réalisé. Le mot « aérien » ne désigne donc qu'un objectif futur.
5. **Cadre sécurité.** La mission officielle porte sur la sécurité des réseaux 5G-Advanced/6G à base d'UAV et l'étude contrôlée de la falsification d'alertes. Le résultat effectivement démontré est la plateforme expérimentale et le chemin PWS sur F1 ; aucune mitigation de sécurité ni validation en vol ne doit être revendiquée.

## 6. Message central proposé

> J'ai transformé un objectif de recherche sur la sécurité des alertes 5G aéroportées en une plateforme OAI distribuée, embarquable, mesurable et reproductible, tout en établissant clairement ce qui reste à valider avant le vol.

### Idée que le jury doit retenir

Le stage ne se résume ni à l'émission d'une alerte, ni à un record de débit, ni à un drone : il montre une boucle d'ingénierie complète — **baseline, isolation, adaptation, preuve, rollback** — pour rendre un scénario de sécurité 5G expérimentalement défendable.

### Formulation provisoire de la mission

> Construire une station 5G OAI légère et distribuée afin d'étudier, dans un environnement contrôlé, la sécurité des alertes d'urgence sur un réseau compatible UAV.

Intitulé officiel : **Security for UAV-Based 5G-Advanced and 6G Networks**.

## 7. Matrice de traçabilité vers les cinq diapositives

| Diapositive | Affirmations principales | Sources minimales | Risque contrôlé |
|---|---|---|---|
| 1 — contexte et mission | KAUST/SeRBER, sécurité des alertes, architecture CU/DU, dates du stage | `MISSION`, `KAUST-WEB`, `LAB-HISTORY` | Distinguer objectif de sécurité et résultats effectivement obtenus |
| 2 — problème | Déporter la DU sans perdre PWS, données, maîtrise du chemin et rollback | `REQ`, `LAB-README`, `LAB-EVIDENCE` | Ne pas réduire le problème au seul débit |
| 3 — méthode et contributions | Baselines, isolation, pivots, patches PWS, transports, noyau Jetson, outillage | `LAB-EVIDENCE`, `LAB-HISTORY`, `KERNEL` | Distinguer travail personnel et contexte d'équipe |
| 4 — résultats et limites | PWS, service utilisateur, trois transports, ARM, repères de débit, absence de vol | `LAB-EVIDENCE`, `PAPER-DRAFT`, confirmation du 5 août, `RUNTIME-GATES` | Indiquer « meilleurs runs », ne pas transformer les valeurs en comparaison contrôlée |
| 5 — compétences et projet | Diagnostic croisé, reproductibilité, embarqué, méthode transférable | Historique des livrables, `KERNEL`, preuves assainies | Éviter une liste générique de compétences |

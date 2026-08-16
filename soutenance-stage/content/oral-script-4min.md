# Script de secours — quatre minutes

Cette version conserve la problématique, la méthode, les preuves et les limites. Elle supprime les détails secondaires avant toute preuve essentielle.

## Diapositive 1

Bonjour. Mon stage à KAUST s’intitulait *Security for UAV-Based 5G-Advanced and 6G Networks*. Une station 5G portée par drone pourrait rétablir une couverture après une crise, mais le nœud radio devient mobile, exposé et dépendant d’un backhaul. Avant d’étudier une attaque ou une défense, j’ai donc construit au sol un banc OpenAirInterface distribué, observable et réversible, capable de préserver un service d’alerte d’urgence. Je présente ici cette base expérimentale, pas un système déjà volant.

**Transition :** Il fallait transformer cette intention en preuves observables.

## Diapositive 2

Déporter la DU ajoute trois fragilités : le calcul ARM et l’USB vers la radio, F1 sur un lien sans fil, puis la continuité du service jusqu’au téléphone. J’ai retenu quatre preuves : observer le chemin F1 réellement utilisé, établir l’association CU-DU, enregistrer le terminal avec Internet, puis afficher l’alerte PWS. La baseline Ethernet restait disponible pour revenir à un état connu. La sécurité commence ici par une propriété très concrète : pouvoir expliquer et reproduire chaque état du système.

**Transition :** Ces critères ont dicté la méthode d’expérimentation.

## Diapositive 3

Le cœur 5G et la CU restent sur x86. F1 rejoint une DU sur Raspberry Pi puis Jetson, associée à une USRP B210. J’ai exercé Ethernet, Wi-Fi avec GRE, puis 5G avec WireGuard. Un premier montage créait une dépendance circulaire entre accès et backhaul ; j’ai séparé la radio B210 et le modem donneur. J’ai ensuite traité ensemble le noyau SCTP, l’USB 3, le CPU et les métriques radio. À chaque extension, la règle était la même : baseline, hypothèse, mesure, correction, reproduction et rollback.

**Transition :** Cette boucle permet de qualifier les résultats sans les surinterpréter.

## Diapositive 4

Le service a été validé sur trois transports F1, avec Internet et une alerte PWS visibles sur un téléphone commercial. Les valeurs sont des meilleurs runs distincts : 89 mégabits par seconde soutenus sur x86 Ethernet, environ 100 en pic ; 52 sur Wi-Fi/GRE ; et 68 sur Jetson avec 5G/WireGuard, résultat final officiellement validé. Ce ne sont ni des moyennes ni un classement contrôlé. Le diagnostic Ethernet a aussi relié MSS, BLER et adaptation radio, puis fait passer le MCS dominant de 5 à 24–27.

**Transition :** Le bilan sépare maintenant les preuves des travaux encore ouverts.

## Diapositive 5

Le stage livre donc un split CU-DU reproductible, PWS, trois transports, une DU ARM, un noyau Jetson SCTP, des preuves et un rollback. Il ne livre pas encore une base 5G volante ni une mitigation de sécurité validée. La suite consiste à répéter les essais à RF contrôlée, mesurer puissance et température, puis intégrer le nœud avant un vol encadré. Mon principal acquis est cette discipline : rendre un système distribué observable et réversible avant de le miniaturiser, une méthode transférable à la robotique autonome et aux systèmes cyberphysiques.

## Coupures prioritaires dans la version principale

1. Retirer la phrase sur les deux pivots de la diapositive 3.
2. Retirer la valeur Wi-Fi `52 Mbit/s` à l’oral.
3. Résumer le diagnostic à « l’instrumentation BLER/MCS a identifié puis corrigé le goulot ».
4. Sur la dernière diapositive, supprimer la phrase de rattachement au projet de R&D.

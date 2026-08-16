# Script oral principal

Version de référence pour une soutenance de cinq minutes. Le support visible reste volontairement synthétique ; ce texte développe le raisonnement et les limites.

## Diapositive 1 — Security for UAV-Based 5G-Advanced and 6G Networks

Bonjour. Mon stage à KAUST s’intitulait officiellement *Security for UAV-Based 5G-Advanced and 6G Networks*. Une station 5G portée par drone pourrait rétablir rapidement une couverture après une crise, mais le nœud radio devient mobile, exposé et dépendant d’un lien de transport. Avant d’évaluer une attaque ou une défense, il faut donc savoir exactement ce que fait la chaîne. Ma mission a été de construire au sol un banc OpenAirInterface distribué, observable et réversible, capable de préserver un service d’alerte d’urgence de bout en bout. C’est cette base expérimentale — et non un système déjà volant — que je vais présenter.

**Transition :** Le premier enjeu n’était pas le débit ; c’était de rendre chaque état du système vérifiable.

## Diapositive 2 — Sécuriser commence par rendre le système observable

Le sujet officiel parle de sécurité, mais une question vient avant toute mitigation : sait-on prouver ce que fait réellement le système ? Déporter la DU sur une plateforme légère ajoute trois fragilités. D’abord, le calcul embarqué et l’USB vers la radio. Ensuite F1, qui doit traverser Ethernet, Wi-Fi ou 5G sans masquer le chemin des paquets. Enfin, la continuité de service : le téléphone doit s’enregistrer, accéder à Internet et afficher l’alerte PWS. J’ai donc défini quatre preuves d’acceptation : chemin F1 observé, association CU-DU, service de données sur le terminal et alerte visible. La baseline Ethernet restait disponible pour revenir à un état connu.

**Transition :** Ces preuves ont dicté l’architecture du banc et la méthode d’essai.

## Diapositive 3 — Un banc 5G conçu comme une chaîne de preuves

Le cœur 5G et la CU restent sur x86. F1 relie cette partie fixe à une DU portée sur Raspberry Pi puis Jetson, avec une USRP B210 pour l’accès radio. Trois transports ont été exercés : Ethernet pour la référence et le rollback, Wi-Fi avec GRE, puis 5G avec WireGuard. À chaque extension, je n’acceptais pas seulement un processus lancé : il fallait observer le bon chemin F1, l’association CU-DU, l’enregistrement et Internet sur le terminal, puis l’alerte PWS. Deux pivots ont été décisifs : séparer la radio d’accès du modem de backhaul, puis traiter ensemble noyau SCTP, USB 3, CPU et métriques radio. La boucle est restée : baseline, hypothèse, mesure, correction, reproduction.

**Transition :** Cette méthode produit des résultats solides, à condition de qualifier précisément chaque chiffre.

## Diapositive 4 — Trois F1 validés ; 68 Mbit/s sur Jetson

Le résultat principal est fonctionnel : le même service a été validé à travers trois transports F1, avec Internet et une alerte PWS visibles sur un téléphone commercial. Les débits servent de repères, pas de classement : 89 mégabits par seconde soutenus sur x86 Ethernet, environ 100 en pic ; 52 au meilleur run Wi-Fi avec GRE ; et 68 sur Jetson avec 5G et WireGuard, résultat final officiellement validé. Les hôtes et les conditions diffèrent, ce ne sont donc ni des moyennes ni une comparaison contrôlée. L’apport est aussi le diagnostic inter-couches : le réglage MSS et la fenêtre BLER ont fait passer le MCS dominant de 5 à 24–27 sur le run Ethernet.

**Transition :** Le bilan doit maintenant séparer ce qui est prouvé de ce qui reste à démontrer.

## Diapositive 5 — Une base vérifiable avant l’intégration UAV

Le stage livre une plateforme reproductible : split CU-DU, PWS, trois transports, DU sur ARM, noyau Jetson avec SCTP, prévols, preuves et rollback. Il ne livre pas encore une base 5G volante ni une mitigation de sécurité validée. Les prochaines étapes sont donc mesurables : répéter les essais dans une condition RF contrôlée, instrumenter puissance et température, intégrer mécaniquement le nœud, puis préparer un premier essai aérien encadré. Mon principal acquis d’ingénieur est cette discipline : rendre un système distribué observable et réversible avant de le miniaturiser. Elle est directement transférable à mon projet en R&D, robotique autonome et vision 3D à Seoul National University.

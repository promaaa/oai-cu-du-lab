# Cartes mémoire

Ces cartes servent de filet de sécurité. Elles ne doivent pas être lues mot à mot.

## Carte 1 — Contexte

- **Ancre :** KAUST · 7 avril–31 juillet · titre officiel sécurité UAV/5G.
- **Enjeu :** couverture d'urgence rapide, mais alertes exposées.
- **Mission :** banc OAI distribué, observable et réversible au sol.
- **Pointer :** titre officiel, puis préciser « base expérimentale, pas système volant ».
- **Ne pas dire :** que le système a volé ou qu'une mitigation a été validée.
- **Transition :** préserver toute la chaîne, pas seulement lancer les logiciels.

## Carte 2 — Problème

- **Question :** que faut-il rendre observable avant toute mitigation ?
- **Trois couches :** calcul / transport / radio.
- **Quatre preuves :** bon chemin F1 / UE / Internet / PWS.
- **Sécurité expérimentale :** environnement privé et contrôlé.
- **Retour arrière :** Ethernet.
- **Transition :** expériences isolées par rapport à la baseline.

## Carte 3 — Méthode

- **Architecture :** Core/CU x86 → F1 → DU ARM/B210 → UE.
- **Transports :** Ethernet → Wi-Fi/GRE → 5G/WireGuard.
- **Pivot :** radio unique impossible → B210 accès + modem donneur.
- **Embarqué :** Pi, Jetson, SCTP, USB 3.
- **Boucle :** baseline → hypothèse → mesure → correction → reproduction.
- **Transition :** preuves oui, comparaison statistique non.

## Carte 4 — Résultats

- **Chaîne validée :** UE + Internet + PWS via F1.
- **Trois F1 :** Ethernet / Wi-Fi-GRE / 5G-WireGuard.
- **Repères :** 89 soutenus, 100 pic / 52 / Jetson 68.
- **Qualifier :** meilleurs runs distincts, pas moyennes.
- **Diagnostic :** MSS + BLER → MCS 5 vers 24–27.
- **Livrables :** banc, noyau SCTP, preuves, rollback.
- **Limites :** pas de vol, répétitions RF, puissance mesurée.

## Carte 5 — Bilan

- **Validé :** service de bout en bout.
- **Livré :** banc reproductible.
- **À faire :** répétitions, puissance mesurée, intégration UAV.
- **Transfert :** systèmes cyberphysiques, robotique, vision 3D.
- **Conclusion caméra :** pas de vol revendiqué ; nœud dé-risqué avant vol.

## Carte urgence — si le temps manque

- Diapositive 1 : mission en une phrase.
- Diapositive 2 : trois couches + quatre preuves.
- Diapositive 3 : deux contributions + un pivot.
- Diapositive 4 : PWS/Internet, `89`, `68`, limites.
- Diapositive 5 : diagnostic inter-couches + phrase finale.

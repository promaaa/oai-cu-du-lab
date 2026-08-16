# Questions probables du jury

Les réponses directes visent 15 à 25 secondes. Les versions développées visent 45 à 60 secondes et ne doivent être utilisées que si le jury relance.

## A. Compréhension générale et cadre sécurité

### 1. Pouvez-vous résumer votre stage en une phrase ?

**Réponse directe :** J'ai construit et validé une plateforme 5G OpenAirInterface distribuée, avec une DU sur calcul ARM et trois transports F1, afin d'étudier au sol la sécurité des alertes d'urgence destinées à une future station compatible UAV.

**Réponse développée :** Le sujet officiel portait sur la sécurité des réseaux 5G-Advanced et 6G utilisant des UAV. Pour rendre ce sujet expérimentalement testable, il fallait d'abord une station légère, une alerte réellement observable sur un terminal et une architecture où la DU peut être éloignée du cœur. J'ai donc travaillé sur le split CU/DU, le transport F1 par Ethernet, Wi-Fi ou 5G, le portage Raspberry Pi et Jetson, puis la mesure et la reproductibilité. Le résultat est un banc au sol fonctionnel et documenté. Il ne constitue pas encore un déploiement en vol ni une mitigation de sécurité validée.

**Faits à citer :** cinq mois environ ; trois transports F1 ; PWS et Internet sur terminal commercial ; Jetson `68 Mbit/s` au meilleur run.

**Piège à éviter :** résumer le stage à « faire voler une antenne » ou à « envoyer une fausse alerte ».

### 2. Quel était le besoin de KAUST ?

**Réponse directe :** L'équipe avait besoin d'une plateforme cellulaire légère et maîtrisée pour étudier les risques liés aux alertes d'urgence dans un contexte UAV, sans dépendre d'une infrastructure commerciale ni perdre la capacité de mesurer chaque couche.

**Réponse développée :** Le besoin combinait sécurité et expérimentation. Une alerte publique est diffusée largement ; si sa chaîne de confiance est insuffisante, elle devient un objet de recherche important. Mais une étude sérieuse nécessite un réseau privé autorisé, une radio contrôlée, un terminal d'essai et des preuves depuis la CU jusqu'à l'affichage. L'architecture devait aussi anticiper un nœud déportable, donc limiter le calcul embarqué et accepter un backhaul variable. Mon travail a transformé ce besoin en critères mesurables et en procédures reproductibles, plutôt qu'en une démonstration ponctuelle difficile à refaire.

**Faits à citer :** document officiel de mission ; plateforme OAI privée ; approche expérimentale SeRBER ; rollback Ethernet.

**Piège à éviter :** prétendre que KAUST demandait déjà un produit industriel certifié.

### 3. Pourquoi le scénario UAV est-il pertinent ?

**Réponse directe :** Un UAV peut déployer rapidement une couverture temporaire lors d'une catastrophe ou dans une zone isolée. En contrepartie, il impose des contraintes de masse, d'énergie, de calcul et de backhaul, tout en augmentant la surface d'attaque.

**Réponse développée :** L'intérêt d'un UAV est la rapidité de déploiement et la possibilité de rapprocher la radio des utilisateurs sans infrastructure fixe. Cette mobilité rend néanmoins le système plus contraint et plus exposé : ressources embarquées limitées, lien de retour sans fil, navigation et radio susceptibles d'interférences. Dans mon stage, je n'ai pas validé le vol. J'ai travaillé sur la brique préalable : une DU compacte, un backhaul hétérogène et une chaîne PWS observable. Le dimensionnement de masse et d'énergie permet de sélectionner une plateforme future, mais il reste une estimation tant qu'une intégration et des mesures réelles ne sont pas faites.

**Faits à citer :** Pi/Jetson ; B210 ; Quectel ; charge utile dimensionnée mais non volée.

**Piège à éviter :** annoncer une autonomie ou une couverture aérienne qui n'a pas été mesurée.

### 4. Quelle est précisément votre contribution personnelle ?

**Réponse directe :** J'ai déployé le banc, complété le chemin PWS sur F1, construit les transports GRE et WireGuard, porté la DU sur Pi et Jetson, produit le noyau SCTP Jetson, diagnostiqué le goulot MCS/BLER et créé les outils de prévol, preuve et rollback.

**Réponse développée :** Mon travail personnel couvre quatre blocs vérifiables. Côté protocole, j'ai complété le traitement Write-Replace Warning côté DU et sécurisé le transfert mémoire du payload SIB8. Côté réseau, j'ai mis en place le routage GRE puis le chemin 5G/WireGuard en prouvant l'interface réellement utilisée. Côté embarqué, j'ai porté la DU sur Raspberry Pi et Jetson, avec un noyau SCTP reproductible et des réglages USB/CPU. Enfin, j'ai instrumenté BLER, MCS et taille de paquets pour expliquer le débit, puis consolidé l'ensemble dans une console opérateur, des portes de validation, de la documentation et un rollback.

**Faits à citer :** preuves assainies PWS et benchmarks ; dépôt du noyau ; historique du dépôt canonique.

**Piège à éviter :** s'attribuer OAI, le cœur 5G initial de l'équipe ou les travaux des encadrants.

### 5. Quel écart existe entre la mission officielle et le résultat final ?

**Réponse directe :** La mission visait l'étude d'une falsification d'alerte sur une station compatible UAV. J'ai validé la plateforme et le chemin d'alerte nécessaires à cette étude, mais pas le vol ni une mitigation de sécurité complète.

**Réponse développée :** L'objectif officiel comportait trois ambitions : une gNB légère, l'expérimentation des alertes et une contribution scientifique. Le stage a fortement avancé la première et la base expérimentale de la deuxième : PWS traverse le split et atteint un téléphone sur plusieurs transports et plateformes. Le travail a aussi alimenté un brouillon d'article. En revanche, je distingue la capacité à émettre et observer une alerte dans un réseau privé de la validation d'une attaque réaliste ou d'une contre-mesure. De même, « compatible UAV » signifie ici dimensionné et dé-risqué au banc, pas certifié ou testé en vol.

**Faits à citer :** intitulé officiel ; PWS de bout en bout ; brouillon d'article ; aucune campagne de vol.

**Piège à éviter :** masquer cet écart ou le présenter comme un échec total.

### 6. Pourquoi parler de sécurité si votre résultat principal est une plateforme réseau ?

**Réponse directe :** Une expérimentation de sécurité n'est défendable que si l'infrastructure sous-jacente est maîtrisée. La plateforme rend le chemin d'alerte observable et reproductible ; elle est donc l'instrument nécessaire pour étudier ensuite la menace et les mitigations.

**Réponse développée :** Sans baseline stable, une alerte absente peut venir d'un défaut radio, d'un problème F1 ou d'une mesure de sécurité ; on ne peut rien conclure. Mon apport a été de séparer ces causes et de prouver la chaîne jusqu'au terminal. PWS est ici à la fois le cas d'usage et une porte de validation applicative. Le support n'affirme pas qu'une solution de sécurité a été validée. Il montre que le laboratoire dispose désormais d'une plateforme où une étude contrôlée peut comparer comportements, conditions et futures contre-mesures sans confondre panne d'infrastructure et effet de sécurité.

**Faits à citer :** PWS affiché ; F1 packet-path ; baseline Ethernet ; procédures relançables.

**Piège à éviter :** laisser croire que la simple diffusion PWS constitue une mitigation.

## B. Architecture 5G, OAI, CU/DU et PWS

### 7. À quoi servent la CU et la DU ?

**Réponse directe :** La CU porte les fonctions plus centralisables de contrôle et de traitement haut niveau. La DU exécute les fonctions radio plus proches du temps réel et pilote la radio d'accès. Elles communiquent par l'interface F1.

**Réponse développée :** La séparation permet de laisser le cœur et la CU sur une machine fixe disposant de ressources, tandis que la DU reste près de la radio. Dans ce banc, la CU prépare notamment le contrôle de l'alerte et l'envoie sur F1 ; la DU reçoit cette procédure, transmet le contenu vers la pile radio et programme SIB8 sur la cellule. Cette répartition est intéressante pour un futur UAV parce qu'elle réduit ce qui doit être embarqué. Elle crée aussi une dépendance au transport F1 : si latence, routage ou capacité sont insuffisants, le service peut se dégrader même si chaque processus fonctionne isolément.

**Faits à citer :** CU fixe ; DU ARM + B210 ; F1-C et F1-U ; SIB8 programmé côté DU.

**Piège à éviter :** dire que toute la couche physique est dans la CU ou que F1 est le lien radio avec le téléphone.

### 8. Qu'est-ce que l'interface F1 ?

**Réponse directe :** F1 est l'interface normalisée entre CU et DU. F1-C transporte le contrôle, notamment la procédure d'alerte, et F1-U transporte le plan utilisateur. Dans mon banc, elle passe sur différents réseaux IP.

**Réponse développée :** F1 relie les deux parties d'une gNB désagrégée. Son plan de contrôle utilise notamment SCTP, tandis que le plan utilisateur transporte les données encapsulées. Mon sujet consistait à faire fonctionner cette interface non seulement sur un Ethernet direct, mais aussi sur un tunnel GRE au-dessus du Wi-Fi et sur WireGuard au-dessus d'un modem 5G. L'enjeu n'était pas seulement la connectivité IP : il fallait prouver le chemin réellement emprunté, préserver le contrôle, les données et la diffusion PWS, puis comparer chaque essai à la baseline Ethernet.

**Faits à citer :** trois bearers ; SCTP ; GRE ; WireGuard ; PWS et données.

**Piège à éviter :** appeler F1 « fronthaul » vers le téléphone ; le téléphone utilise la radio d'accès.

### 9. Pourquoi séparer CU et DU ?

**Réponse directe :** La séparation permet de centraliser les fonctions lourdes et d'alléger le nœud radio distant. Elle rend aussi possible un backhaul flexible, au prix de contraintes supplémentaires de transport et de synchronisation.

**Réponse développée :** Pour un nœud déportable, embarquer le cœur, la CU, la DU et toute l'infrastructure augmente masse, énergie et complexité. Le split conserve une partie centralisée et place seulement la DU avec la radio. Cela ouvre plusieurs supports F1, y compris un lien mobile. En revanche, la séparation introduit des paquets supplémentaires, des exigences SCTP, des problèmes de routage et de MTU, ainsi qu'une dépendance à la qualité du backhaul. Le stage montre donc les deux faces du choix : un potentiel d'embarquabilité plus réaliste, mais seulement si le chemin F1 et la chaîne radio sont instrumentés et reproductibles.

**Faits à citer :** DU Pi/Jetson ; transports hétérogènes ; diagnostic MTU/MSS ; rollback Ethernet.

**Piège à éviter :** présenter le split comme automatiquement plus performant que le mode monolithique.

### 10. Pourquoi avoir choisi OpenAirInterface ?

**Réponse directe :** OAI fournit une implémentation 5G ouverte et modifiable, compatible avec des radios logicielles et un split CU/DU réel. C'était indispensable pour instrumenter F1 et adapter le chemin PWS jusque dans le code.

**Réponse développée :** Une solution commerciale aurait limité l'accès au code, aux journaux et aux paramètres internes. Avec OAI, j'ai pu identifier le traitement Write-Replace Warning, compléter le gestionnaire côté DU, suivre le payload SIB8 et observer BLER et MCS. OAI est aussi compatible avec la B210 et avec un cœur 5G privé, ce qui permet une validation sur terminal commercial. Le compromis est une intégration plus exigeante : dépendances système, versions, noyau SCTP et paramètres radio doivent être maîtrisés. C'est pourquoi le commit OAI, les patches et les procédures de lancement sont essentiels à la reproductibilité.

**Faits à citer :** code ouvert ; B210 ; CU/DU ; patches PWS ; commit documenté.

**Piège à éviter :** affirmer qu'OAI est représentatif de toutes les performances d'un équipement industriel.

### 11. Qu'est-ce que SIB8 et le Public Warning System ?

**Réponse directe :** Le PWS diffuse des alertes à tous les terminaux d'une zone. Dans la configuration étudiée, SIB8 porte l'information d'alerte sur l'interface radio ; la CU déclenche la procédure et la DU la programme pour le terminal.

**Réponse développée :** L'intérêt d'une alerte publique est sa diffusion large, sans session applicative individuelle. Dans le split étudié, la CU prépare le message et utilise la procédure F1AP Write-Replace Warning. La DU doit décoder cette demande, transférer correctement le contenu vers les couches radio et programmer SIB8. J'ai dû compléter ce chemin côté DU et corriger la gestion mémoire. La validation finale ne repose pas seulement sur un journal : le terminal commercial reste enregistré et affiche effectivement l'alerte. C'est important pour la sécurité, car la réception visible par l'utilisateur est le comportement que l'étude cherche ensuite à comprendre et à protéger.

**Faits à citer :** Write-Replace Warning ; gestionnaire DU ; terminal commercial ; rapport 10.

**Piège à éviter :** détailler un mode opératoire d'abus ou affirmer que tous les réseaux utilisent exactement la même présentation utilisateur.

### 12. Comment avez-vous validé que PWS passait réellement par F1 ?

**Réponse directe :** J'ai combiné trois preuves : la procédure de contrôle observée entre CU et DU, la programmation SIB8 côté DU et l'affichage de l'alerte sur le téléphone. Une simple ligne de log n'aurait pas suffi.

**Réponse développée :** La validation est une chaîne. D'abord, la CU émet la procédure F1AP attendue. Ensuite, le gestionnaire DU la reçoit sans erreur et transmet le payload à la couche radio. Enfin, le terminal connecté à la cellule affiche l'alerte. Pour les transports non Ethernet, j'ai aussi vérifié que les paquets F1 empruntaient l'interface ou le tunnel sélectionné. L'association de ces éléments évite deux faux positifs : croire qu'un message local a été diffusé sans passer par F1, ou considérer la présence d'un paquet comme une preuve d'effet utilisateur.

**Faits à citer :** preuve assainie du chemin PWS/F1 ; observation sur UE.

**Piège à éviter :** montrer une capture brute avec des identifiants ou citer un simple « process up » comme preuve.

### 13. Pourquoi trois transports F1 ?

**Réponse directe :** Ethernet fournit la référence stable ; Wi-Fi/GRE teste un lien local sans fil ; 5G/WireGuard représente un backhaul mobile routé. Ensemble, ils permettent d'isoler ce qui dépend du transport et ce qui dépend de la DU ou de la radio.

**Réponse développée :** La diversité des transports répond à deux objectifs. D'abord, progresser sans perdre une baseline : Ethernet sert de rollback et de contrôle. Ensuite, rapprocher progressivement le banc du cas d'usage : Wi-Fi introduit un lien radio local, puis le modem 5G introduit un accès mobile et un tunnel sécurisé. GRE a servi à forcer un chemin logique symétrique sur le Wi-Fi ; WireGuard a fourni une superposition IP maîtrisée au-dessus du modem. Les essais n'ont pas été une compétition entre bearers : ils ont permis de vérifier la portabilité du split et d'identifier les contraintes propres à chaque chemin.

**Faits à citer :** Ethernet direct ; Wi-Fi/GRE ; Quectel/WireGuard ; packet-path.

**Piège à éviter :** dire que 5G/WireGuard est intrinsèquement plus rapide parce qu'un run donne une valeur supérieure.

### 14. Pourquoi utiliser à la fois une B210 et un modem Quectel ?

**Réponse directe :** La B210 fournit la cellule d'accès au téléphone. Le Quectel fournit un backhaul 5G distinct pour F1. Cette séparation évite qu'un redémarrage de la DU coupe le lien dont elle dépend pour joindre la CU.

**Réponse développée :** Le premier essai cherchait à réutiliser une même infrastructure radio pour l'accès et le backhaul. Cela créait une dépendance circulaire : lorsque la DU redémarrait sa cellule d'accès, le modem perdait précisément la connectivité nécessaire au retour F1. Le pivot a consisté à séparer les rôles. La B210 reste la radio d'accès pilotée par la DU ; le modem Quectel s'attache à une cellule donneuse distincte et transporte WireGuard vers la CU. Ce choix ajoute du matériel, mais il rend le chemin causalement compréhensible et relançable.

**Faits à citer :** échec du scénario à radio partagée ; pivot de juin ; WireGuard sur modem donneur.

**Piège à éviter :** dire que la liaison B210–téléphone est le backhaul ou F1.

## C. Méthodologie expérimentale et performance

### 15. Pourquoi avoir choisi cette méthodologie ?

**Réponse directe :** Le système combine réseau, calcul et radio ; changer plusieurs variables à la fois rend le diagnostic ambigu. J'ai donc utilisé une baseline, une hypothèse par essai, plusieurs preuves indépendantes et un rollback systématique.

**Réponse développée :** Dans un système distribué, le même symptôme — par exemple un faible débit — peut venir du chemin IP, du scheduler radio, du CPU, de l'USB ou du terminal. La méthode devait réduire cet espace de causes. Je partais d'un Ethernet connu, je formulais une hypothèse, je changeais un élément, puis je vérifiais le chemin paquet, l'état CU/DU, l'état du terminal et les métriques radio. Si l'essai échouait, le rollback permettait de vérifier que la référence n'avait pas été dégradée. Cette méthode a notamment empêché d'attribuer trop vite le plafond de débit à la seule puissance du processeur.

**Faits à citer :** baseline Ethernet ; quatre portes ; gates machine ; mesure BLER/MCS ; rollback.

**Piège à éviter :** parler de méthode scientifique sans reconnaître l'absence de répétitions contrôlées pour les débits.

### 16. Quelles preuves considériez-vous nécessaires pour déclarer un essai réussi ?

**Réponse directe :** Je séparais les portes machine et les preuves de bout en bout : matériel et transport prêts, CU/DU associés, bon chemin F1, terminal enregistré, session de données, Internet, PWS observé et retour arrière disponible.

**Réponse développée :** Les prévols vérifient l'état du matériel, du cœur, du modem, du tunnel et des interfaces avant de lancer OAI. Ensuite, les journaux et le chemin paquet prouvent l'association F1 et le transport choisi. Enfin, le téléphone fournit la preuve utilisateur : enregistrement, session PDU, trafic externe et alerte affichée. Toutes ces preuves n'étaient pas systématiquement présentes dans un même ancien run ; c'est précisément pourquoi la documentation distingue capacité disponible, fraîcheur de preuve et validation de bout en bout. Pour un run final, j'exigerais un manifeste horodaté et assaini réunissant toutes les portes.

**Faits à citer :** `RUNTIME-GATES` ; PWS UE ; Internet ; packet-path ; rollback.

**Piège à éviter :** dire que toutes les anciennes mesures respectent déjà exactement le même protocole.

### 17. Comment savez-vous que la baisse de performance venait de la DU et non du réseau ?

**Réponse directe :** Je ne l'ai pas supposé. J'ai comparé la baseline, vérifié le chemin IP, observé BLER et MCS, puis modifié séparément l'hôte, la taille des paquets et les seuils radio. Le résultat a montré une interaction, pas une cause unique « DU ».

**Réponse développée :** Le débit restait faible même après passage sur une machine plus puissante, ce qui affaiblissait l'hypothèse d'un simple manque de CPU. Le plan de données et le chemin F1 étaient fonctionnels, mais le MCS restait au plancher tandis que le BLER dépassait la fenêtre d'augmentation du scheduler. L'encapsulation F1 et la taille de segments influençaient les blocs transportés sur la radio. Le réglage MSS, associé à une fenêtre BLER cohérente avec la condition mesurée, a permis au MCS de monter de 5 vers 24–27 et au débit Ethernet d'atteindre 89 Mbit/s soutenus. La conclusion est donc inter-couches : transport et scheduler radio interagissaient.

**Faits à citer :** MCS 5 puis 24–27 ; BLER observé ; MSS 1360 ; 89 soutenus / 100 pic.

**Piège à éviter :** affirmer que toute baisse future aura la même cause ou que le réglage BLER est universel.

### 18. Les comparaisons ont-elles été réalisées dans des conditions identiques ?

**Réponse directe :** Non. Les valeurs présentées sont des meilleurs runs sur des hôtes, dates et conditions RF différents. Elles prouvent la faisabilité de chaque configuration, mais pas un classement statistique des transports.

**Réponse développée :** C'est une limite importante. Les essais ont évolué avec les patches, les profils radio, les plateformes et les conditions RF. Par exemple, le `52 Mbit/s` Wi-Fi est un run x86, alors que le `68 Mbit/s` 5G est un run Jetson plus récent. Je les affiche comme repères associés à leur configuration, sans barre proportionnelle ni conclusion « tel bearer est plus rapide ». Une comparaison rigoureuse demanderait un commit figé, la même radio, le même terminal, une condition RF contrôlée, des répétitions randomisées et des statistiques comme moyenne, dispersion et intervalle de confiance.

**Faits à citer :** mention visible « meilleurs runs distincts » ; x86/Wi-Fi contre Jetson/5G ; absence d'intervalles de confiance.

**Piège à éviter :** transformer les trois chiffres en benchmark équitable.

### 19. Pourquoi le réglage MSS a-t-il influencé un débit radio ?

**Réponse directe :** L'encapsulation du plan utilisateur change la taille des paquets. Des segments trop grands favorisaient fragmentation et gros blocs de transport, ce qui augmentait les erreurs radio et maintenait le MCS au plancher. Le MSS a réduit cet effet.

**Réponse développée :** F1-U ajoute de l'encapsulation au trafic utilisateur. Avec un MTU et un MSS mal coordonnés, les segments négociés conduisaient à des paquets fragmentés ou à des blocs de transport très grands. Dans la condition radio mesurée, cela augmentait les erreurs et le BLER filtré restait au-dessus du seuil qui permet au scheduler d'augmenter le MCS. Le réglage MSS à 1360 a réduit la taille utile, tandis que l'ajustement de la fenêtre BLER a rendu l'adaptation cohérente avec la mesure. L'important est la causalité expérimentale : plusieurs métriques changent ensemble et le débit est restauré, mais ce paramètre n'est pas présenté comme optimum universel.

**Faits à citer :** GTP-U/F1-U ; MSS `1360` ; BLER environ 22–35 % avant réglage ; MCS 24–27 après.

**Piège à éviter :** dire que MSS agit directement sur la modulation sans chaîne intermédiaire.

### 20. Quelles métriques avez-vous utilisées ?

**Réponse directe :** J'ai combiné débit terminal, BLER, MCS, état d'enregistrement, session PDU, trafic Internet, association F1, chemin paquet, charge système et état USB. Aucune métrique isolée ne suffisait.

**Réponse développée :** Les métriques couvrent trois niveaux. Au niveau service : PWS affiché, enregistrement, session de données et débit vu par le terminal. Au niveau protocole : association F1-C, présence de F1-U et interface réellement empruntée. Au niveau radio et machine : BLER, MCS, erreurs ou overflows UHD, vitesse USB, CPU et interruptions. Cette combinaison permet d'éviter des conclusions trompeuses. Un débit faible avec F1 sain et MCS au plancher dirige vers la chaîne radio ; des overflows avant l'attachement sur X310 dirigent vers le chemin hôte–radio ; un tunnel actif sans paquets F1 ne valide pas le backhaul.

**Faits à citer :** quatre portes utilisateur ; MCS/BLER ; USB 480M contre 5000M ; packet-path.

**Piège à éviter :** citer des journaux bruts ou identifiants devant le jury.

### 21. Pourquoi GRE pour le Wi-Fi ?

**Réponse directe :** GRE fournissait un chemin logique explicite pour F1 au-dessus du Wi-Fi et permettait de vérifier la symétrie du routage. Le défi principal était d'éviter qu'un retour emprunte discrètement l'Ethernet.

**Réponse développée :** Les hôtes avaient plusieurs interfaces et pouvaient choisir une route différente de celle voulue. Un simple ping Wi-Fi ne prouvait donc pas que F1-C et F1-U utilisaient bien le lien sans fil. Le tunnel GRE créait des extrémités logiques dédiées ; le routage par politique forçait les flux attendus dans les deux sens. J'ai ensuite observé les paquets sur les interfaces pertinentes. Ce choix visait surtout la maîtrise expérimentale du chemin, pas le chiffrement. Pour la liaison mobile, WireGuard répondait mieux au besoin d'une superposition routée et protégée.

**Faits à citer :** routage asymétrique initial ; policy routing ; preuve de chemin GRE.

**Piège à éviter :** présenter GRE comme une protection cryptographique.

### 22. Pourquoi WireGuard pour le backhaul 5G ?

**Réponse directe :** WireGuard créait une adresse et un chemin F1 stables au-dessus d'un modem mobile dont l'adressage et le routage pouvaient varier. Il apportait aussi une protection du tunnel, sans sécuriser à lui seul toute l'architecture.

**Réponse développée :** Le modem Quectel fournit une connectivité IP via une cellule donneuse, mais ce chemin n'offre pas naturellement des extrémités F1 stables et directement joignables. WireGuard crée une superposition point à point sur laquelle CU et DU peuvent lier leurs interfaces F1. Il permet aussi de vérifier que les paquets sortent bien par le modem et évite un repli silencieux vers Ethernet ou Wi-Fi. Son chiffrement protège le tunnel, mais il ne résout ni la confiance dans le terminal, ni l'authenticité de l'alerte radio, ni la sécurité opérationnelle globale. Ces problèmes doivent rester séparés.

**Faits à citer :** modem donneur distinct ; tunnel point à point ; garde contre le fallback ; F1-C/F1-U.

**Piège à éviter :** dire que WireGuard corrige la vulnérabilité PWS.

### 23. Quel problème SCTP avez-vous rencontré sur Jetson ?

**Réponse directe :** Le noyau Jetson fourni ne permettait pas l'usage SCTP nécessaire à F1-C. J'ai produit un noyau compatible, une installation reproductible, une entrée de démarrage séparée et une procédure de vérification et de rollback.

**Réponse développée :** Les premiers essais ont montré que le blocage ne venait pas d'OAI lui-même mais du support SCTP du noyau Jetson. Plusieurs tentatives de module étaient fragiles à cause de l'alignement entre BSP, sources et chaîne de compilation. J'ai donc construit un noyau correspondant à la version Jetson Linux documentée, avec SCTP activé en module. Pour limiter le risque, l'installation ne remplace pas aveuglément l'entrée de démarrage connue : elle crée un chemin séparé, vérifie le module et documente le retour arrière. Ce livrable transforme un dépannage local en procédure réutilisable.

**Faits à citer :** Jetson Linux R36.4.4 ; SCTP en module ; dépôt `jetson-kernel-sctp` ; entrée séparée.

**Piège à éviter :** prétendre que l'architecture ARM exige intrinsèquement un patch noyau ; c'était la configuration de distribution utilisée.

### 24. Pourquoi tester Raspberry Pi et Jetson ?

**Réponse directe :** Les deux plateformes explorent des compromis différents de coût, puissance, ressources et maturité logicielle. Les tester montre que la DU n'est pas liée à un seul hôte embarqué.

**Réponse développée :** Le Raspberry Pi est accessible et léger, mais plus contraint pour le traitement radio et l'I/O. Le Jetson offre davantage de ressources et s'aligne avec le projet officiel, tout en introduisant ses propres contraintes de noyau et de plateforme. L'objectif n'était pas de déclarer un vainqueur universel, mais de démontrer la portabilité de la DU et d'identifier les conditions d'exécution : support SCTP, chemin USB 3 réel, modes de performance, distribution CPU/interruptions et profil radio. Le Pi a atteint un meilleur run de 48 Mbit/s sur 5G/WireGuard ; le Jetson, 68 Mbit/s dans le run final validé.

**Faits à citer :** Pi `48` ; Jetson `68` ; B210 ; réglages USB/CPU.

**Piège à éviter :** comparer l'efficacité énergétique sans mesures électriques intégrées.

### 25. Que s'est-il passé avec l'USRP X310 ?

**Réponse directe :** Le test à 106 PRB n'a pas atteint l'attachement du terminal : le chemin hôte–radio se comportait comme un lien 1 GbE et produisait des overflows. Changer le câble n'a pas suffi ; l'hypothèse du câble a donc été écartée.

**Réponse développée :** L'X310 devait explorer une radio différente et une bande passante plus large. F1 et le chemin PWS atteignaient l'état prêt, mais le streaming radio échouait avant une validation visible sur téléphone. Même un mode réduit dépassait la capacité pratique du chemin négocié, et un nouveau câble n'a pas établi un véritable lien hôte–radio à haut débit. Ce résultat négatif est utile : il déplace l'effort futur vers la preuve d'un chemin 10 GbE complet — interface, négociation, MTU et UHD — avant de retoucher OAI ou le cœur.

**Faits à citer :** 106 PRB ; overflows ; comportement 1 GbE ; besoin d'un chemin 10 GbE prouvé.

**Piège à éviter :** dire que l'X310 est incompatible avec OAI ou que le câble était certainement défectueux.

### 26. Quel a été votre principal échec ?

**Réponse directe :** Le premier backhaul mobile utilisait une architecture circulaire : la radio d'accès redémarrée par la DU coupait le modem qui devait transporter F1. Cet échec m'a conduit à séparer radio d'accès et modem donneur.

**Réponse développée :** Le tunnel WireGuard et le chemin modem pouvaient fonctionner isolément, mais le lancement complet échouait. La cause était architecturale, pas un détail de configuration : le même domaine radio servait à la fois de réseau donneur et de cellule contrôlée par la DU. Quand la cellule était relancée, le backhaul disparaissait et empêchait le retour F1. J'ai donc abandonné ce montage au lieu de multiplier les contournements. Le nouveau design utilise une B210 pour le terminal et un modem Quectel attaché à une cellule donneuse distincte. Cet échec a amélioré l'architecture et la méthode de validation.

**Faits à citer :** tunnel prouvé avant échec complet ; dépendance circulaire ; pivot documenté.

**Piège à éviter :** répondre uniquement par un bug corrigé ; le jury cherche la prise de recul.

## D. Résultats, limites et reproductibilité

### 27. Quels résultats sont réellement reproductibles ?

**Réponse directe :** Les procédures de déploiement, les prévols, le choix du transport, le lancement CU/DU, PWS, le noyau Jetson et le rollback sont reproductibles. Les débits restent des meilleurs runs et demandent une campagne répétée pour une reproductibilité statistique.

**Réponse développée :** Je distingue reproductibilité opérationnelle et reproductibilité métrologique. La première est couverte par le dépôt canonique : entrées documentées, commit OAI, profils générés hors Git, portes de validation et retour Ethernet. Le noyau Jetson possède aussi une procédure de construction et de vérification. Pour les performances, les valeurs ont été observées et le `68 Mbit/s` Jetson a été validé comme meilleur run final, mais le corpus ne contient pas encore une série à conditions RF fixes avec moyenne et dispersion. Je peux donc reproduire le scénario et viser le résultat ; je ne revendique pas encore une distribution statistique stable.

**Faits à citer :** `./oai-lab` ; gates ; commit OAI documenté ; noyau ; meilleurs runs.

**Piège à éviter :** confondre « relançable » avec « même débit garanti à chaque essai ».

### 28. Comment justifiez-vous précisément les 68 Mbit/s ?

**Réponse directe :** C'est le meilleur run Jetson final, consigné dans le brouillon d'article et confirmé comme résultat officiellement validé. Je l'étiquette comme maximum documenté, sans en faire une moyenne ni une comparaison équitable avec les autres transports.

**Réponse développée :** Les anciennes observations montrent d'abord la progression à 44 puis environ 40 Mbit/s. Le brouillon scientifique plus récent rapporte 68 Mbit/s après un lancement propre, avec le profil Jetson corrigé et la plage MCS complète. Cette valeur a été confirmée le 5 août comme résultat final validé. La traçabilité conserve néanmoins l'historique et signale que la trace primaire assainie du run n'était pas dans l'archive locale consultée. Sur la diapositive, j'utilise donc « 68 Mbit/s max » et « meilleurs runs distincts », pas une barre de moyenne ou une promesse de débit.

**Faits à citer :** progression `40–44` puis `68` ; brouillon d'article ; confirmation du 5 août ; conditions Jetson/5G-WireGuard.

**Piège à éviter :** dire « 68 Mbit/s en moyenne » ou cacher l'absence de série répétée.

### 29. Le système est-il réellement déployable sur un drone ?

**Réponse directe :** Pas encore au sens d'un système validé en vol. La DU fonctionne sur matériel compact et la charge utile a été dimensionnée, mais l'intégration électrique, les vibrations, la thermique, l'autonomie et la liaison en mobilité restent à tester.

**Réponse développée :** Le stage réduit plusieurs risques : compatibilité ARM, radio B210 sur USB 3, backhaul mobile, PWS et données sur terminal, plus une estimation de masse et d'énergie. Cela rend le scénario plausible sur une plateforme de charge utile adaptée. Mais un système aérien doit encore intégrer alimentation, conversion, refroidissement, fixation, antennes, compatibilité électromagnétique et sécurité de vol. Il faut aussi mesurer la consommation réelle sous charge radio et tester le backhaul en mobilité. Ma formulation est donc « nœud compatible avec une future intégration UAV » et non « station aérienne opérationnelle ».

**Faits à citer :** environ 1,6 kg dimensionnés pour la charge utile Jetson ; batterie 44,4 Wh envisagée ; aucun vol.

**Piège à éviter :** convertir le dimensionnement en autonomie garantie.

### 30. Qu'auriez-vous fait avec un mois supplémentaire ?

**Réponse directe :** J'aurais figé le commit et la configuration, exécuté une campagne répétée sous RF contrôlée, mesuré puissance et température, puis préparé une intégration au sol complète avant tout vol.

**Réponse développée :** La priorité serait la qualité des preuves. Je définirais une matrice réduite mais contrôlée : mêmes CU, DU, B210, terminal, position RF, trafic, durée et commit. Chaque bearer serait répété plusieurs fois dans un ordre randomisé, avec débit, BLER, MCS, CPU, température et consommation électrique synchronisés. J'archiverais des manifestes assainis et calculerais moyenne, dispersion et intervalles. Ensuite seulement, je ferais une intégration mécanique et électrique, un test au sol avec alimentation embarquée, puis un vol captif ou très contrôlé selon les règles locales. En parallèle, je préparerais une expérimentation défensive sur l'authenticité des alertes.

**Faits à citer :** limites actuelles : répétitions, puissance, vol ; ordre de réduction du risque.

**Piège à éviter :** proposer immédiatement un vol sans étapes de sécurité et de métrologie.

### 31. Pourquoi n'avez-vous pas réalisé une campagne statistique complète ?

**Réponse directe :** Le stage devait d'abord lever plusieurs blocages fonctionnels et matériels. Les configurations ont évolué jusqu'à la fin ; répéter tôt aurait mesuré des systèmes différents. J'ai privilégié la stabilisation et documenté cette limite.

**Réponse développée :** Une campagne statistique n'a de sens qu'avec une configuration figée. Or les patches PWS, les transports, le profil radio, le noyau Jetson et les réglages BLER/MSS ont évolué successivement. Le temps disponible a été consacré à obtenir une chaîne complète et reproductible. J'ai néanmoins conservé les conditions essentielles des meilleurs runs et surtout évité d'utiliser les chiffres comme moyennes. La suite logique est maintenant de geler le commit OAI, les patches et le profil, puis de lancer une campagne sous RF contrôlée. Reconnaître cette limite évite une conclusion plus forte que les données.

**Faits à citer :** évolution avril–juillet ; brouillon d'article ; snapshots et non moyennes.

**Piège à éviter :** dire que quelques tests suffisent à une généralisation statistique.

### 32. Quel est l'intérêt industriel de votre travail ?

**Réponse directe :** Le principal intérêt est une méthode de déploiement et de diagnostic pour une RAN désagrégée sur matériel accessible : transports interchangeables, preuves de bout en bout et retour arrière rapide. Cela réduit le coût et le risque d'expérimentation.

**Réponse développée :** Une organisation qui évalue une couverture temporaire, un réseau privé ou une RAN distribuée a besoin de savoir non seulement si une démo fonctionne, mais comment la relancer, identifier un goulot et revenir à une référence. Le dépôt consolide ces opérations et supporte plusieurs DUs et backhauls sans exposer les configurations privées. Le diagnostic MSS/BLER illustre aussi la valeur d'une observation inter-couches : un problème apparemment radio venait en partie de la taille des paquets et de la logique d'adaptation. Ce n'est pas un produit certifié, mais un banc R&D réutilisable pour comparer des architectures avant industrialisation.

**Faits à citer :** matériel COTS ; trois bearers ; console opérateur ; rollback ; preuves utilisateur.

**Piège à éviter :** promettre une mise sur le marché ou une conformité opérateur non étudiée.

### 33. Quelles parties restent expérimentales ?

**Réponse directe :** Les valeurs de débit sont des meilleurs runs, la puissance est estimée, l'intégration UAV n'a pas volé, l'X310 à 106 PRB a échoué et aucune architecture multi-DU ou mitigation de sécurité n'a été validée.

**Réponse développée :** Le noyau, les transports et le chemin PWS sont des livrables fonctionnels de banc. En revanche, cinq éléments restent ouverts : une campagne répétée à RF fixe ; la mesure électrique et thermique intégrée ; la validation mécanique et en vol ; le chemin X310 réellement haut débit ; enfin l'étude défensive des alertes et le passage éventuel à plusieurs DUs. Le dimensionnement de charge utile et les choix de drone sont donc des recommandations, pas des mesures. Cette frontière est consignée dans la traçabilité et visible sur la diapositive de résultats.

**Faits à citer :** liste des limites ; X310 ; absence de vol ; absence de multi-DU.

**Piège à éviter :** répondre seulement « tout fonctionne sauf le drone ».

## E. Sécurité, confidentialité et éthique

### 34. Comment avez-vous encadré l'expérimentation de sécurité ?

**Réponse directe :** Les essais ont été menés sur un réseau privé, avec du matériel et des terminaux de test contrôlés. Le support ne contient ni paramètres exploitables, ni identifiants, ni procédure d'abus ; il présente uniquement l'objectif scientifique et les preuves nécessaires.

**Réponse développée :** Le sujet touche à une fonction sensible destinée au public. L'expérimentation doit donc rester autorisée, isolée et observable. Le banc utilise un cœur privé, une cellule de laboratoire et un terminal de test. Les documents publics sont assainis : pas d'identifiants d'abonné, d'adresses internes, de clés, de journaux bruts ou de captures réseau. Je distingue aussi la validation d'un chemin PWS de la démonstration détaillée d'une attaque. Pour une poursuite du travail, j'ajouterais une analyse de menace, des règles d'essai écrites, un périmètre RF contrôlé et une revue éthique avant toute campagne de sécurité.

**Faits à citer :** réseau privé ; cage utilisée dans certains essais ; politique de confidentialité du dépôt.

**Piège à éviter :** divulguer une configuration, un message malveillant ou un identifiant réel.

### 35. Avez-vous proposé ou validé une mitigation contre la falsification d'alertes ?

**Réponse directe :** Non, pas comme résultat final validé. J'ai construit la plateforme et la chaîne de preuve qui permettront d'évaluer des mitigations. Je préfère séparer cette capacité expérimentale d'une solution de sécurité qui demanderait son propre protocole de validation.

**Réponse développée :** Le document initial mentionnait la proposition de mitigations, mais les sources de fin de stage valident surtout PWS sur F1, les transports, les plateformes ARM et la reproductibilité. Je ne transforme donc pas une intention en résultat. Une mitigation pourrait agir sur l'authentification, la confiance du terminal, la détection réseau ou les procédures opérationnelles, mais chacun de ces axes implique des hypothèses et parfois des modifications de standard ou d'équipement. La plateforme offre désormais le contrôle nécessaire pour comparer un comportement de référence et une contre-mesure, en observant à la fois le protocole et l'effet utilisateur.

**Faits à citer :** objectif initial versus résultats finaux ; chaîne PWS validée ; aucune campagne de mitigation.

**Piège à éviter :** improviser une contre-mesure comme si elle avait été implémentée.

### 36. Comment garantissez-vous la confidentialité des résultats ?

**Réponse directe :** J'exclus du support les identifiants d'abonné, adresses internes, noms de machines, secrets, journaux et captures brutes. Les chiffres affichés sont agrégés et chaque source publique est distinguée des preuves privées assainies.

**Réponse développée :** La confidentialité est traitée à trois niveaux. Dans Git, les configurations générées, clés, données d'abonné, logs et captures sont exclus. Dans la présentation, les architectures utilisent des rôles génériques — CU, DU, modem, terminal — sans topologie interne exploitable. Enfin, la traçabilité conserve la provenance des résultats sans publier la preuve brute : elle indique le rapport, le run ou la confirmation, puis qualifie la force de la preuve. Un script de validation recherche aussi des motifs sensibles connus et des marqueurs oubliés avant l'export.

**Faits à citer :** règles du dépôt ; revue de confidentialité ; validation automatique.

**Piège à éviter :** afficher une ancienne capture de terminal ou de console contenant des détails internes.

## F. Organisation, apprentissages et projet professionnel

### 37. Comment avez-vous organisé votre travail sur la durée du stage ?

**Réponse directe :** J'ai structuré le stage en cinq phases : reproduction du socle, PWS sur F1, diversification des transports, portage embarqué, puis mesure et capitalisation. Chaque phase conservait une baseline et produisait une trace ou un livrable.

**Réponse développée :** La chronologie n'était pas un plan figé, car plusieurs résultats ont imposé des pivots. Avril a servi à rendre le système monolithique observable. Mai a porté le split et le chemin PWS, puis le Wi-Fi. Juin a introduit le backhaul 5G et l'instrumentation, avec l'abandon de l'architecture circulaire. Fin juin et juillet ont ciblé le diagnostic de débit, le Pi, le Jetson et la reproductibilité. Les rapports datés ont servi de journal de décision. En fin de stage, j'ai regroupé commandes, prévols, preuves et rollback dans un dépôt canonique afin que l'équipe puisse reprendre le travail.

**Faits à citer :** historique Git ; cinq phases ; preuves assainies ; console opérateur.

**Piège à éviter :** présenter la frise comme si aucun imprévu n'avait modifié le plan.

### 38. Qu'avez-vous appris que vous n'auriez pas appris uniquement à l'école ?

**Réponse directe :** J'ai appris qu'un système réel ne respecte pas les frontières des cours : un débit radio peut dépendre du MTU, un protocole du noyau et une radio du placement des interruptions. Il faut construire une preuve inter-couches.

**Réponse développée :** La formation m'a donné les bases de réseau, de radio, de programmation et de raisonnement. Le stage m'a appris à les relier sous contraintes réelles. Le changement d'un processeur ne résout pas un mauvais chemin USB ; un tunnel actif ne prouve pas que F1 l'emprunte ; un terminal enregistré ne garantit ni Internet ni PWS. J'ai aussi appris la valeur opérationnelle d'un rollback et d'une documentation qui peut être exécutée par quelqu'un d'autre. Enfin, j'ai découvert qu'un résultat négatif bien instrumenté — comme l'X310 ou la radio partagée — peut faire gagner plus de temps qu'une démonstration fragile.

**Faits à citer :** MSS/BLER/MCS ; USB 3 ; packet-path ; deux pivots.

**Piège à éviter :** répondre par des qualités génériques sans exemple technique.

### 39. Pourquoi ce stage est-il cohérent avec votre projet professionnel ?

**Réponse directe :** Je vise la R&D sur des systèmes embarqués et cyberphysiques. Ce stage m'a fait travailler exactement à l'interface entre algorithmes, calcul, réseau, capteurs radio et validation expérimentale, méthode que je poursuivrai en robotique et vision 3D.

**Réponse développée :** La continuité n'est pas que thématique. En 5G comme en robotique autonome, une performance globale dépend de plusieurs couches : acquisition, calcul temps réel, communication, énergie et environnement. Le stage m'a appris à construire une baseline, synchroniser les métriques, isoler une cause et documenter le retour arrière. Ce sont les mêmes réflexes qui seront nécessaires pour évaluer une chaîne de perception ou un système autonome au 3D Vision Lab de Seoul National University. Je veux donc poursuivre en R&D, sur des systèmes où une hypothèse doit être démontrée sur une plateforme réelle et reproductible.

**Faits à citer :** Jetson ; inter-couches ; SNU 3D Vision Lab ; systèmes cyberphysiques.

**Piège à éviter :** prétendre que réseaux cellulaires et vision 3D sont la même spécialité.

### 40. Quel travail l'équipe peut-elle reprendre après votre départ ?

**Réponse directe :** Elle peut redéployer les scénarios par transport et plateforme, reconstruire le noyau Jetson, vérifier les portes de service, revenir à l'Ethernet, puis lancer la campagne répétée et l'intégration UAV à partir d'une base documentée.

**Réponse développée :** Les livrables ne sont pas seulement des fichiers de configuration locaux. Le dépôt canonique fournit une interface opérateur, des profils générés à partir d'entrées privées, des prévols, des portes de preuve et des procédures de rollback. Le dépôt noyau fixe la version Jetson et la méthode SCTP. Les rapports conservent les décisions, y compris les impasses. À court terme, l'équipe peut figer le commit, relancer la matrice réduite et archiver des runs assainis. À moyen terme, elle peut mesurer l'alimentation intégrée, tester une radio plus légère, puis préparer une validation aérienne et une campagne de sécurité défensive.

**Faits à citer :** deux dépôts ; documentation ; rollback ; prochaines étapes explicites.

**Piège à éviter :** dire que tout est automatique ou indépendant de l'accès au laboratoire.

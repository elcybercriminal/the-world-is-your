# Validation de livraison — Prisme 0.1.0

## Vérifications exécutées

- TypeScript : compilation sans erreur.
- Vite : génération du bundle de production.
- Capacitor : création du projet Android et synchronisation des assets/plugins.
- Tests Node : 6 tests réussis, incluant parsing sûr des iframe/BBCodes, rejet de JavaScript et domaines trompeurs, validation des pseudos et URL.
- Test PostgreSQL/PGlite : exécution complète du schéma avec rôles Auth/Storage simulés, création des profils, conversation canonique, lecture par le destinataire, refus d'accès par un troisième compte, protection du texte et des reçus, fichiers privés, blocage et absence d'accès anonyme.
- Test React/JSDOM : entrée dans la démonstration, fil, like, favori, commentaire, ouverture/fermeture plein écran, message texte, changement de thème, modification du profil, publication d'un embed, publication de deux fichiers image et persistance du message après navigation. Aucun rendu graphique n'est produit par ce test.

## Non vérifié

- Aucun APK compilé : le wrapper Gradle a échoué lors de son téléchargement avec `java.net.SocketException: Network is unreachable`. Le projet et le workflow GitHub sont livrés, leur compilation Android reste à confirmer.
- Aucun navigateur graphique exécuté : Chromium a refusé de démarrer dans l'environnement (`socket() failed: Operation not permitted`). Il n'y a donc pas de validation visuelle réelle ni de mesure de fluidité.
- Gestes natifs de swipe, caméra, microphone, clavier, statut Android, liens de récupération et compatibilité appareil : validation manuelle nécessaire.
- Aucun backend Supabase de l'utilisateur configuré ou modifié. Les tests SQL dans PGlite ne certifient pas le service Auth/Storage distant. Inscription, confirmation e-mail, récupération, upload réel et échanges entre deux comptes restent à tester une fois le projet connecté.
- Aucun test de charge, audit exhaustif ou publication sur un store effectué.

## Recette sur deux téléphones avant diffusion

1. Inscrire deux comptes distincts, confirmer les e-mails et compléter chaque profil.
2. Publier deux photos et une vidéo depuis le premier téléphone ; vérifier le second.
3. Ouvrir la grille : horizontal = média du carrousel ; vertical = publication suivante.
4. Quitter le viewer et vérifier l'arrêt de la vidéo/du lecteur intégré précédent.
5. Tester likes, favoris privés, commentaire, abonnement et suppression propriétaire.
6. Envoyer texte, photo, vidéo et vocal ; lire sur l'autre téléphone ; vérifier « Ouvert ».
7. Ouvrir une photo de chat, revenir avec Retour Android ; ouvrir le clavier et vérifier le champ.
8. Refuser puis autoriser caméra/micro ; vérifier les messages d'erreur et réessayer.
9. Passer entre clair, sombre et automatique ; vérifier le contraste sur petit écran.
10. Tester les liens de confirmation/récupération quand l'application est ouverte puis fermée.
11. Bloquer un compte ; confirmer le refus d'envoi et d'accès à la conversation.
12. Couper Internet pendant un upload : vérifier l'erreur, la conservation du formulaire et la reprise manuelle.

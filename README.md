# Prisme 0.1.0

Application sociale Android, thème clair/sombre/automatique, accents Pride. Projet neuf et autonome. Le nom est provisoire. Lire **COMMENCER-ICI.txt** pour les étapes depuis un téléphone.

## Architecture

React 19 + TypeScript + Vite, embarqués dans une WebView Android via Capacitor 7. Pas besoin d'héberger l'interface sur un site : les assets sont inclus dans l'APK après `cap sync`. Le backend prévu est Supabase Auth/PostgreSQL/Storage. La configuration publique vide laisse accessible une démonstration locale clairement signalée, persistée dans IndexedDB. Aucune ancienne application n'a été modifiée.

La conversation utilise une liste chronologique avec traits de couleur, médias ouvrables et lecteur vocal. Les messages sont conservés. Le chargement utilise une interrogation périodique (3 s dans le chat / 4 s pour la liste), suspendue quand la page est masquée, sans simulation de réponse. Ce mécanisme n'est pas du push en arrière-plan et ses coûts de requêtes sont à surveiller.

## Développement

Node 22 recommandé. Java 21 et Android SDK 35 pour compiler Android.

```sh
npm ci
npm run dev
npm test
npm run test:ui
npm run android
cd android
./gradlew assembleDebug
```

Sortie attendue : `android/app/build/outputs/apk/debug/app-debug.apk`.
La compilation Android n'a pas abouti dans l'environnement de création : aucun APK n'est inclus. Le workflow GitHub fourni exécute les tests puis la compilation. Le minimum Android déclaré est API 23 ; Android System WebView doit être récent pour les API web utilisées. Android 12 est la cible prioritaire de validation. Aucune compatibilité physique n'a encore été certifiée.

L'APK de debug sert aux essais. Pour une diffusion, configurer une clé de signature de release conservée durablement, une version croissante, et la chaîne de publication adaptée. Les APK de debug de différentes exécutions GitHub peuvent avoir des signatures différentes.

## Backend

Dans un **nouveau projet Supabase**, exécuter `supabase/INSTALL.sql` une fois. Le script est transactionnel, non idempotent, sans suppression de tables existantes. Les comptes créent leur profil via un déclencheur. Ajouter `fr.prisme.social://auth` aux URL de redirection autorisées dans Supabase. Configurer les e-mails de confirmation/récupération et tester l'ouverture des liens à froid et à chaud sur Android.

Renseigner `public/config.json` avant la compilation :

```json
{"supabaseUrl":"https://PROJECT.supabase.co","supabaseAnonKey":"PUBLIC_PUBLISHABLE_OR_ANON_KEY"}
```

Une clé publique est normalement distribuée avec l'application. Les privilèges SQL et RLS assurent les autorisations. Aucune clé de service ne doit être embarquée. Le panneau de configuration locale rejette les clés secrètes et service_role.

Tables : profiles, posts, likes, saves, comments, follows, threads, messages, blocks, reports. Relations et index déclarés, privilèges par colonne, conversations canoniques sans doublon via RPC, reçus modifiables uniquement par le destinataire. Les utilisateurs ne peuvent pas changer le contenu d'un message déjà envoyé ni se faire passer pour un autre.

`media` est un bucket public pour les publications et avatars : toute personne connaissant une URL publique peut lire le fichier. Les profils et les lignes de publications sont réservés aux membres. `chat-media` est privé ; un fichier n'est lisible que par les participants autorisés et l'app produit des liens signés d'une heure. Un lien signé déjà délivré reste valable jusqu'à son expiration, même après un blocage. Les messages ne sont pas chiffrés de bout en bout.

Limite applicative et bucket : 50 Mo par fichier ; carrousels de 10 médias. Aucun transcodage serveur. Un transfert réseau échoué conserve le formulaire pour permettre un nouvel essai. Les fichiers partiellement publiés peuvent rester orphelins après une erreur : prévoir un nettoyage serveur des objets non référencés. La suppression d'une publication retire la ligne et ses relations, mais ne supprime pas automatiquement le fichier du bucket pour éviter de casser d'autres références.

Les signalements arrivent dans `reports`, à traiter par l'administrateur depuis le dashboard avec ses droits serveur. Il n'y a pas de console d'administration mobile. Prévoir quotas, limites d'usage et modération adaptés avant ouverture publique, ainsi qu'une procédure de suppression de compte et de ses fichiers.

## Navigation et gestes

Carrousels horizontaux avec CSS Scroll Snap ; pager vertical plein écran distinct, ancrage à chaque publication. Les axes suivent le défilement natif de WebView. Les vidéos internes sont muettes au démarrage ; une seule publication est active dans le fil ou le viewer. Les vidéos inactives sont mises en pause. Les lecteurs externes ne sont montés qu'à la demande et démontés quand on les quitte. Leur surface capture les gestes : le bord droit et les flèches restent disponibles pour changer de publication.

Le bouton Retour Android ferme d'abord les superpositions puis remonte les écrans ; une confirmation est demandée pour quitter à l'accueil. `adjustMarginsForEdgeToEdge: auto`, `adjustResize` et VisualViewport sont prévus pour les barres système et le clavier. La position et les gestes doivent encore être testés sur appareil réel.

## Recherche, pagination et limites

Le fil charge 30 publications par lot avec bouton supplémentaire. Le profil interroge les publications de son propriétaire ou ses favoris, indépendamment du fil. Explorer filtre le lot chargé ; le classement populaire utilise likes et commentaires sur ce lot, ce n'est pas une recommandation globale. Les conversations affichent jusqu'aux 200 messages les plus récents ; il n'y a pas encore de chargement de l'historique plus ancien. Les commentaires sont limités aux 200 premiers chargés.

Les photos de démonstration sont des assets d'illustration Unsplash ; les profils, légendes et relations de démonstration sont fictifs. Les données réelles sont séparées de ces exemples.

Non inclus : appels WebRTC, notifications push, stories, Bitmoji, IA, carte, messages éphémères, alerte de capture, transcription vocale, chiffrement de bout en bout. Les boutons d'appel sont explicitement désactivés. Aucun comportement de Snapchat n'est prétendu disponible s'il ne l'est pas.

## Vérifications

Voir `VALIDATION.md`. Tests locaux de logique, de politiques PostgreSQL dans PGlite et de parcours React dans JSDOM. Ces tests ne remplacent pas un appareil Android, la validation visuelle, les permissions matérielles ni deux vrais comptes Supabase.

Références techniques utilisées : [Capacitor Android](https://capacitorjs.com/docs/v7/android), [migration Capacitor 7](https://capacitorjs.com/docs/v7/updating/7-0), [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [contrôle des accès Storage](https://supabase.com/docs/guides/storage/security/access-control).

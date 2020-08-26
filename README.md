# Processus simple de création d&#39;Infrastructure as Code (IaC) sur Azure grâce à Terraform

# Introduction

Terraform est un outil qui permet de déployer, mettre à jour et détruire des infrastructures à partir de fichiers. On parle d&#39;Infrastructure en Code (Infrastructure as Code, IaC).

Terraform n&#39;a pas besoin d&#39;être installé sur Azure, c&#39;est un outil local (relatif à votre shell bien qu&#39;il puisse être utilisé à travers CloudShell) qui interprète des fichiers YAML pour communiquer avec des fournisseurs (Providers). Azure est un provider mais Terraform peut communiquer avec de nombreux autres providers (officiels : [https://www.terraform.io/docs/providers/index.html](https://www.terraform.io/docs/providers/index.html) / communautaires : [https://www.terraform.io/docs/providers/type/community-index.html](https://www.terraform.io/docs/providers/type/community-index.html)). En fait, Terraform peut communiquer avec tous les services disposant d&#39;une API pour être managés mais aussi d&#39;autres providers locaux (fichiers, générateur de suites aléatoires, heure…).

Terraform créé un état de l&#39;infrastructure dans un fichier. Lorsque vous souhaitez ajouter des ressources, Terraform va calculer la différence entre l&#39;état actuel et l&#39;état souhaité et pourra appliquer les changements pour arriver à l&#39;état souhaité. A l&#39;inverse, pour supprimer ou modifier des ressources, le processus est identique. Attention, si des modifications sont apportées en dehors de Terraform (par exemple à travers le portail Azure), tout sera supprimé lors de la prochaine application de votre configuration si vous n&#39;avez pas intégré les modifications dans vos fichiers Terraform.

Lorsque vous travaillez avec Terraform, il faut donc bien garder en tête que ce n&#39;est pas un outil pour créer des ressources n&#39;importe où mais un outil pour créer, maintenir et supprimer une seule infrastructure à la fois. Si vous souhaitez travailler sur plusieurs projets, plusieurs clients, plusieurs environnements qui n&#39;ont pas de liens entre eux, il faut donc créer un fichier d&#39;état par projet/infra/client.

Le fichier d&#39;état `.tfstate` peut être stocké localement sur votre poste mais dans ce cas, vous seul avez la possibilité de maintenir l&#39;infrastructure avec Terraform. C&#39;est acceptable en développement mais pas en production. Il faut donc rendre le fichier d&#39;état accessible sur une ressource partagée comme un compte de stockage Azure.

Une fois les fichiers de configuration de votre projet prêts, le processus est simple :

- Vous initialisez pour qu&#39;il détecte tous les fichiers du répertoire et télécharge les connecteurs liés aux providers déclarés (les connecteurs sont des exécutables permettant de dialoguer avec les providers)
- Vous planifiez le déploiement (ou la destruction) en chargeant si besoin des paramètres supplémentaires. Cette planification génère un fichier « plan » qui reprend tout ce qui est à faire par rapport à l&#39;état actuel.
- Vous appliquez le plan

Les fichiers de votre projet sont lus de façon arbitraire par Terraform. Il n&#39;y a pas de convention pour spécifier les premiers fichiers à lire, ni comment nommer les fichiers à part leur extension : `.tf`.

Il faut donc prévoir les dépendances entre les ressources directement dans les fichiers.

Il est aussi possible d&#39;avoir des fichiers contenant des variables spécifiques (par exemple des mots de passe que vous ne souhaitez pas rendre publiques sur GitHub ou dans des processus d&#39;évolution d&#39;une infrastructure, le type d&#39;environnement).

Néanmoins, les bonnes pratiques conseils d&#39;avoir :

- `main.tf` pour décrire le projet
- `output.tf` pour récupérer les sorties des ressources
- `providers.tf` pour déclarer les providers
- `version.tf` pour fixer la version de Terraform ou (pour des raisons de compatibilité)
- `variables.tf` pour déclarer les variables utilisées

Il est possible de créer des modules dans Terraform pour découper les projets importants en petites parties. Ces modules peuvent aussi être réutilisés ailleurs sur d&#39;autres projets mais en aucun cas il faut les imaginer comme des librairies de modules.

# Concernant cette documentation

Nous partirons du principe que vous avez déjà un compte auprès de votre providers (si besoin), que votre provider Cloud est Azure, que vous utilisez un ordinateur Windows avec Powershell et Terraform en local.

Néanmoins, la démarche fonctionne avec les autres providers, sur MacOs et Linux, avec un shell Linux ou CloudShell.

Le code est mis en forme et les variables que vous avez à modifier sont sous la forme `\&lt;VARNAME\&gt;` (tout en majuscule, attaché, en anglais et avec des pointes qu&#39;il faut supprimer aussi).

Pour comprendre et modifier certaines commande, il est recommander de lire la documentation sur les requêtes dans Azure CLI : [https://docs.microsoft.com/en-us/cli/azure/query-azure-cli?view=azure-cli-latest](https://docs.microsoft.com/en-us/cli/azure/query-azure-cli?view=azure-cli-latest)

Lors de la création de vos ressources, il est conseillé de suivre une convention de nommage (nomenclature). Voici les conseils de Microsoft pour les ressources Azure : [https://docs.microsoft.com/fr-fr/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging](https://docs.microsoft.com/fr-fr/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

# Installation de Terraform

Nous commençons par installer Terraform.

Lien vers le téléchargement de Terraform : [https://www.terraform.io/downloads.html](https://www.terraform.io/downloads.html)

Terraform est un exécutable qui ne s&#39;installe pas, il doit simplement être posé dans un dossier inclus dans votre PATH.

Pour garder un système cohérent, je préconise d&#39;imiter Docker et de créer un dossier Terraform dans C:\Programmes, d&#39;y déposer l&#39;exécutable. Vous pouvez le mettre aussi dans un dossier d&#39;outil dans votre répertoire ou là où vous le souhaitez.

Puis, il faut l&#39;ajouter au PATH de votre système. Pour ce faire, il faut lancer en tant qu&#39;Administrateur la commande suivante :
```shell
[Environment]::SetEnvironmentVariable(&quot;Path&quot;, $env:Path + &quot;; C:\Program Files\Terraform&quot;, &quot;Machine&quot;)
```

# Installation de GIT (facultatif)

Si vous souhaitez utiliser les fichiers mis à disposition sur GitHub ou même créer un nouveau dépôt pour partager votre configuration, vous pouvez installer le client Git. Il vous permettra de faire toutes les manipulations vers GitHub.

L&#39;installation est classique.

Lien vers le téléchargement de Git : [https://git-scm.com/download/win](https://git-scm.com/download/win)

# Installation de Visual Studio Code (facultatif)

Il existe de nombreux éditeurs de code (Notepad++, Sublime Text, Vim…) mais les ayant tous essayés, j&#39;ai une préférence pour Visual Studio Code.

L&#39;installation est classique.

Lien vers le téléchargement de Visual Studio Code : [https://code.visualstudio.com/Download](https://code.visualstudio.com/Download)

De plus, n&#39;hésitez pas à installer des extensions pour Azure, Terraform…

# Installation de Azure CLI

Pour profiter des outils en ligne de commande Azure à travers Powershell, il faut installer Azure CLI.

Le téléchargement et l&#39;installation sont classiques.

Lien vers le téléchargement de Azure CLI : [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&amp;tabs=azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&amp;tabs=azure-cli)

# Connexion à votre compte Azure

Une fois Azure CLI installé, connectez votre Powershell à votre compte Azure via la commande :

```shell
az login
```

_Explication de la commande :_

- _az : utiliser des commandes fournies par Azure CLI (ne sera plus détaillée ici)_
- _login : indiquer que l&#39;on souhaite se connecter à son compte Azure pour utiliser Azure CLI. Pour se déconnecter, utilisez « az logout »._
- _Plus d&#39;info sur la commande :_ [https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login](https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login)

Une page web va s&#39;ouvrir, choisissez le compte lié à l&#39;abonnement que vous souhaitez utiliser.

# Sélectionner le bon abonnement

Vous êtes connecté à votre compte et votre abonnement par défaut a été sélectionné.

Listez l&#39;ensemble des abonnements avec leur IDs, celui par defaut aura `IsDefault` à `true` :
```shell
az account list --output table
```
_Explication de la commande :_

- _account list : récupérer la liste des abonnements du compte_
- _--output table : affiche sous forme de tableau_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list)_

Si vous souhaitez en choisir un autre abonnement que celui par défaut :
```shell
az account set --subscription &quot;\&lt;SUBSCRIPTIONID\&gt;&quot;
```
_Explication de la commande :_

- _account set : définir l&#39;abonnement du compte_
- _--subscription &quot;\&lt;SUBSCRIPTIONID\&gt;&quot; : fournir l&#39;id de l&#39;abonnement à définir par défaut_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-set](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-set)_

Pour contrôler que vous avez bien sélectionné l&#39;abonnement, vous pouvez récupérer l&#39;id de l&#39;abonnement :
```shell
az account show --query &quot;{abonnement:id, tenant:tenantId}&quot;
```
_Explication de la commande :_

- _account show : affiche les détails l&#39;abonnement du compte_
- _--query &quot;{abonnement:id, tenant:tenantId}&quot; : filtre la sortie pour afficher &#39;id&#39; et &#39;tenantID&#39; et chacun de ces paramètres a un préfix devant pour rendre plus lisible (&#39;abonnement&#39; et &#39;tenant&#39;)_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-show](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-show)_

Le tenantId doit correspondre au répertoire (Azure Active Directory). S&#39;il ne correspond pas ou si vous n&#39;avez pas les droits de création sur ce répertoire, créer un nouveau répertoire Azure Active Directory et basculer votre abonnement dessus.

Notez l&#39;ID de l&#39;abonnement, ça nous servira par la suite.

# Créer un principal de service

Il faut maintenant créer un principale de service sur l&#39;abonnement, que l&#39;on va nommer Terraform pour avoir les droits de créer les ressources sur Azure depuis Terraform.
```shell
az ad sp create-for-rbac --name=&quot;terraform&quot; --role=&quot;Owner&quot; --scopes=&quot;/subscriptions/\&lt;SUBSCRIPTIONID\&gt;&quot;
```
_Explication de la commande :_

- _ad sp : gérer le service principal sur Azure Active Directory pour automatiser l&#39;authentification_
- _create-for-rbac : créer un principal de service et le configurer pour accéder aux ressources Azure_
- _--name=&quot;terraform&quot; : spécifier le nom du principal de service_
- _--role=&quot;Owner&quot; : définir le rôle du principal de service à Owner pour qu&#39;il puisse créer et gérer ses services sur cet abonnement_
- _--scopes=&quot;/subscriptions/\&lt;SUBSCRIPTIONID\&gt;&quot; : spécifier l&#39;abonnement sur lequel créer ce principal de service_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create-for-rbac](https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create-for-rbac)_

Cette commande va vous retourner des valeurs qu&#39;il va falloir conserver car certaines n&#39;apparaissent qu&#39;une fois (le password).

Nous avons besoins des informations `appID`, `password`, `tenant`.

Note : Si vous perdez le password, relancez la commande qui va mettre à jour le principale de service et générer un nouveau mot de passe.

# Choisir la région Azure

Vous allez devoir choisir une région pour stocker votre fichier d&#39;état, puis une ou plusieurs régions pour le déploiement de vos ressources. Pour connaitre le code de votre région, voici la commande listant les régions disponibles :
```shell
az account list-locations --query &#39;sort\_by([].{Nom:displayName, Code\_region:name}, &amp;Nom)&#39; --output table
```
_Explication de la commande :_

- _account list-locations: lister les régions disponibles pour l&#39;abonnement_
- _--query &#39;sort\_by([].{Nom:displayName, Code\_region:name}, &amp;Nom)&#39; : réduire l&#39;affichage pour n&#39;avoir que &#39;displayName&#39; et &#39;name&#39; de toutes les valeurs disponibles (&#39;[].&#39;), mettre des titres aux colonnes avec &#39;Nom&#39; et &#39;Code\_region&#39; pour la lisibilité et trier par ordre alphabétique sur &#39;Nom&#39; (avec &amp;Nom) grâce à &#39;sort\_by&#39;_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list-locations](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list-locations)_

# Créer un groupe de ressource pour le fichier d&#39;état Terraform

Le fichier d&#39;état enregistre l&#39;état du dernier déploiement. Pour travailler en équipe ou éviter une perte de ce fichier (panne de disque dur, ordinateur volé…), il est vivement conseillé de créer un fichier sur un support accessible et pérenne.

Nous allons donc créer un compte de stockage sur Azure dans un groupe de ressources dédié à Terraform.

Commençons par la création du groupe de ressources :
```shell
az group create --name \&lt;NAME\&gt; --location \&lt;REGION\&gt;
```
_Explication de la commande :_

- _group create : créer un nouveau groupe de ressources_
- _--name \&lt;NAME\&gt; : spécifier le nom du groupe de ressources_
- _--location \&lt;REGION\&gt; : spécifier la région dans laquelle créer le groupe de ressources_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-create](https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-create)_

# Créer le stockage pour Terraform

Nous créons d&#39;abord le compte de stockage sur Azure puis nous créerons un conteneur.
```shell
az storage account create --name \&lt;NAME\&gt; --resource-group \&lt;RESOURCEGROUP\&gt; --location \&lt;REGION\&gt;
```
_Explication de la commande :_

- _storage account create : créer un compte de stockage_
- _--name \&lt;NAME\&gt; : spécifier le nom du compte de stockage_
- _--resource-group \&lt;RESOURCEGROUP\&gt; --location \&lt;REGION\&gt; : specifier le groupe de ressources et la région_
- _--sku \&lt;SKU\&gt; : le SKU par défaut est Standard\_RARGS mais vous pouvez spécifier un SKU autre à partir de cette liste ([https://docs.microsoft.com/en-us/rest/api/storagerp/srp\_sku\_types](https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types))_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create](https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create)_

Avec ce nouveau compte de stockage (\&lt;ACCOUNTNAME\&gt;), nous pouvons créer un conteneur à l&#39;intérieur.
```shell
az storage container create --name \&lt;NAME\&gt; --account-name \&lt;ACCOUNTNAME\&gt; --public-access container --resource-group \&lt;RESOURCEGROUP\&gt;
```
_Explication de la commande :_

- _storage container create : créer un conteneur dans le compte de stockage_
- _--name \&lt;NAME\&gt; : spécifier le nom du conteneur_
- _--account-name \&lt;ACCOUNTNAME\&gt; : spécifier le compte de stockage sur lequel créer le conteneur_
- _--public-access container : rend le contenu accessible publiquement_
- _--resource-group \&lt;RESOURCEGROUP\&gt; --location \&lt;REGION\&gt; : spécifier le groupe de ressources et la région_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-create](https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-create)_

Le conteneur est créer, il faut maintenant pouvoir récupérer les identifiants pour se connecter dessus.
```shell
az storage account show-connection-string --name \&lt;ACCOUNTNAME\&gt; --resource-group \&lt;RESOURCEGROUP\&gt;
```
_Explication de la commande :_

- _storage container show-connection-string : récupérer les chaines de connexion du compte de stockage_
- _--name \&lt;ACCOUNTNAME\&gt; : spécifier le nom du compte de stockage_
- _--resource-group \&lt;RESOURCEGROUP\&gt; : spécifier le groupe de ressources_
- _Plus d&#39;info sur la commande : [https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-show-connection-string](https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-show-connection-string)_

Récupérer et garder la sortie de la commande, nous en aurons besoin pour connecter Terraform.

# Création des fichiers de configuration Terraform

Le stockage est prêt, tout est installé, il faut maintenant créer nos premiers fichiers Terraform.

Pour obtenir les modèles des fichiers depuis la dernière version en ligne, placez vous dans votre répertoire de travail et clonez le dépôt Git :
```shell
cd \&lt;WORKINGDIR\&gt;
git clone https://github.com/pezzos/terraform-azure-metsys.git
```
Les deux premiers blocs du fichier provider.tf contiennent la description du backend Terraform et le provider. Nous aurions pu faire deux fichiers séparés, un pour le backend et un pour lister tous les providers mais comme Terraform ne fait pas de distinction, nous avons trouvé plus pratique de grouper ces deux blocs.

La définition du backend sert à décrire où est stocké le fichier d&#39;état de Terraform
```hcl
terraform {
  backend &quot;azurerm&quot; {
    resource\_group\_name = &quot;\&lt;RESOURCEGROUP\&gt;&quot;
    storage\_account\_name = &quot;\&lt;ACCOUNTNAME\&gt;&quot;
    container\_name = &quot;\&lt;CONTAINERNAME\&gt;&quot;
    key = &quot;\&lt;PROJECTNAME\&gt;.tfstate&quot;
  }
}
```
Il faut donc fournir le compte de stockage avec le groupe de ressource dans lequel il est, le conteneur qui stocke le fichier d&#39;état le nom du fichier d&#39;état. Si vous décidez d&#39;utiliser ce conteneur pour plusieurs projets, choisissez un nom de fichier d&#39;état (&#39;key&#39;) avec un nom distinct.

Le second bloque dit simplement à Terraform de charger ce qu&#39;il faut pour communiquer avec Azure RM et de figer la version du provider à 2.24. Le numéro de version est facultatif mais permet de fixer la version sur votre projet pour vous assurer que votre projet fonctionne malgré les évolutions du provider. Vous pouvez changer la version du provider en la récupérant sur la page GitHub du projet du provider (ici https://github.com/terraform-providers/terraform-provider-azurerm).
```hcl
provider &quot;azurerm&quot; {
  version = &quot;~\&gt; 2.24&quot;
  features {}
}
```
# Initialisation de votre projet avec Terraform

Vos fichiers sont configurés avec vos informations, Terraform a tout ce qu&#39;il faut pour démarrer. Initialisez le projet pour charger l&#39;extension du provider.
```shell
cd \&lt;WORKINGDIR\&gt;/\&lt;PROJECT\&gt;
terraform init
```
# Création de la planification

Terraform est initialisé, il faut maintenant planifier les déploiements.
```shell
cd \&lt;WORKINGDIR\&gt;/\&lt;PROJECT\&gt;
terraform plan
```
Là, comme nous n&#39;avons rien mis dans nos fichiers, il n&#39;y a évidemment rien à planifier :

No changes. Infrastructure is up-to-date.

Ajoutons des ressources.

# Création de ressources

Pour commencer simplement, ouvrez le fichier main.tf présent dans la démo et décommentez le premier bloc.
```hcl
resource &quot;azurerm\_resource\_group&quot; &quot;example&quot; {
  name     = &quot;demo&quot;
  location = &quot;France Central&quot;
}
```
Ici, on créé une `resource` de type `azurerm\_resource\_group` que l&#39;on nomme `example` à travers Terraform. Le fait de nommer la ressource permet de s&#39;en resservir à travers Terraform (par exemple, pour fournir le nom du groupe de ressource sur une machine virtuelle).

En paramètre de ce bloc, on indique le nom du groupe de ressource (ici &#39;demo&#39;) et sa localisation.

_Note : sur chaque ressource utilisée dans le dossier de démo, un lien vers la documentation de la ressource est ajouté en commentaire._

# Déploiement des ressources

Vous avez une première ressource de déclarée dans vos fichiers. Utilisons Terraform pour la déployer. Comme précédemment, allez dans votre répertoire de travail et lancez la planification, puis déployez (apply).
```shell
cd \&lt;WORKINGDIR\&gt;/\&lt;PROJECT\&gt;
terraform plan
terraform apply
```
On constate qu&#39;à l&#39;étape de planification, la liste des changements apparait avec des symboles pour indiquer si la ressource est ajouté, modifié ou supprimé. Un résumé totalise les différents changements.

Lorsque l&#39;on déploie avec &#39;apply&#39;, toute l&#39;étape de planification se fait à nouveau et une question est posée pour valider le déploiement. Pour éviter ça, il faut stocker la planification dans un fichier (avec l&#39;argument `--out run.tfplan` et la fournir comme plan pour le déploiement.
```hcl
cd \&lt;WORKINGDIR\&gt;/\&lt;PROJECT\&gt;
terraform plan --out run.tfplan
terraform apply run.tfplan
```
Voilà, vous avez déployé une ressource sur Azure grâce à Terraform.

# Mise à jour des ressources

Dans le fichier main.tf, décommentez la seconde partie. Dans cet exemple, vous allez déployer un machine virtuelle.

Comme précédemment, il faut planifier le déploiement et déployer.
```shell
cd \&lt;WORKINGDIR\&gt;/\&lt;PROJECT\&gt;
terraform plan --out run.tfplan
terraform apply run.tfplan
```
Le déploiement peut durer quelques minutes, c&#39;est normal.

Une fois terminé, vous pouvez constater que le groupe de ressources précédemment créé n&#39;est pas modifié, seule la seconde partie du code est déployé (le réseau et sous-réseau, l&#39;interface réseau et la machine virtuelle).

# Destruction des ressources

Maintenant que nous avons pu installer le nécessaire, vu le fonctionnement de Terraform et déployé une petite infrastructure de démo, nous pouvons tout détruire.

Le processus est similaire, on planifie la destruction grâce à l&#39;argument `--destroy` et on la déploie.

```shell
cd \&lt;WORKINGDIR\&gt;/\&lt;PROJECT\&gt;
terraform plan --out run.tfplan --destroy
terraform apply run.tfplan
```
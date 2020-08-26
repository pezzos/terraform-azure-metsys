# Processus simple de création d'Infrastructure as Code (IaC) sur Azure grâce à Terraform

# Introduction

>Ce processus a été élaboré lors d'un projet chez [Metsys](https://www.metsys.fr/)

Terraform est un outil qui permet de déployer, mettre à jour et détruire des infrastructures à partir de fichiers. On parle d'Infrastructure en Code (Infrastructure as Code, IaC).

Terraform n'a pas besoin d'être installé sur Azure, c'est un outil local (relatif à votre shell bien qu'il puisse être utilisé à travers CloudShell) qui interprète des fichiers YAML pour communiquer avec des fournisseurs (Providers). Azure est un provider mais Terraform peut communiquer avec de nombreux autres providers [officiels](https://www.terraform.io/docs/providers/index.html) et [communautaires](https://www.terraform.io/docs/providers/type/community-index.html)). En fait, Terraform peut communiquer avec tous les services disposant d'une API pour être managés mais aussi d'autres providers locaux (fichiers, générateur de suites aléatoires, heure…).

Terraform créé un état de l'infrastructure dans un fichier. Lorsque vous souhaitez ajouter des ressources, Terraform va calculer la différence entre l'état actuel et l'état souhaité et pourra appliquer les changements pour arriver à l'état souhaité. A l'inverse, pour supprimer ou modifier des ressources, le processus est identique. Attention, si des modifications sont apportées en dehors de Terraform (par exemple à travers le portail Azure), tout sera supprimé lors de la prochaine application de votre configuration si vous n'avez pas intégré les modifications dans vos fichiers Terraform.

Lorsque vous travaillez avec Terraform, il faut donc bien garder en tête que ce n'est pas un outil pour créer des ressources n'importe où mais un outil pour créer, maintenir et supprimer une seule infrastructure à la fois. Si vous souhaitez travailler sur plusieurs projets, plusieurs clients, plusieurs environnements qui n'ont pas de liens entre eux, il faut donc créer un fichier d'état par projet/infra/client.

Le fichier d'état `.tfstate` peut être stocké localement sur votre poste mais dans ce cas, vous seul avez la possibilité de maintenir l'infrastructure avec Terraform. C'est acceptable en développement mais pas en production. Il faut donc rendre le fichier d'état accessible sur une ressource partagée comme un compte de stockage Azure.

Une fois les fichiers de configuration de votre projet prêts, le processus est simple :

- Vous initialisez pour qu'il détecte tous les fichiers du répertoire et télécharge les connecteurs liés aux providers déclarés (les connecteurs sont des exécutables permettant de dialoguer avec les providers)
- Vous planifiez le déploiement (ou la destruction) en chargeant si besoin des paramètres supplémentaires. Cette planification génère un fichier « plan » qui reprend tout ce qui est à faire par rapport à l'état actuel.
- Vous appliquez le plan

Les fichiers de votre projet sont lus de façon arbitraire par Terraform. Il n'y a pas de convention pour spécifier les premiers fichiers à lire, ni comment nommer les fichiers à part leur extension : `.tf`.

Il faut donc prévoir les dépendances entre les ressources directement dans les fichiers.

Il est aussi possible d'avoir des fichiers contenant des variables spécifiques (par exemple des mots de passe que vous ne souhaitez pas rendre publiques sur GitHub ou dans des processus d'évolution d'une infrastructure, le type d'environnement).

Néanmoins, les bonnes pratiques conseils d'avoir :

- `main.tf` pour décrire le projet
- `output.tf` pour récupérer les sorties des ressources
- `providers.tf` pour déclarer les providers
- `version.tf` pour fixer la version de Terraform ou (pour des raisons de compatibilité)
- `variables.tf` pour déclarer les variables utilisées

Il est possible de créer des modules dans Terraform pour découper les projets importants en petites parties. Ces modules peuvent aussi être réutilisés ailleurs sur d'autres projets mais en aucun cas il faut les imaginer comme des librairies de modules.

# Concernant cette documentation

Nous partirons du principe que vous avez déjà un compte auprès de votre providers (si besoin), que votre provider Cloud est Azure, que vous utilisez un ordinateur Windows avec Powershell et Terraform en local.

Néanmoins, la démarche fonctionne avec les autres providers, sur MacOs et Linux, avec un shell Linux ou CloudShell.

Le code est mis en forme et les variables que vous avez à modifier sont sous la forme `<VARNAME>` (tout en majuscule, attaché, en anglais et avec des pointes qu'il faut supprimer aussi).

Pour comprendre et modifier certaines commande, il est recommander de lire la documentation sur [les requêtes dans Azure CLI](https://docs.microsoft.com/en-us/cli/azure/query-azure-cli?view=azure-cli-latest)

Lors de la création de vos ressources, il est conseillé de suivre une convention de nommage (nomenclature). Voici [les conseils de Microsoft pour les ressources Azure](https://docs.microsoft.com/fr-fr/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

# Installation de Terraform

Nous commençons par installer Terraform.

[Lien vers le téléchargement de Terraform](https://www.terraform.io/downloads.html)

Terraform est un exécutable qui ne s'installe pas, il doit simplement être posé dans un dossier inclus dans votre PATH.

Pour garder un système cohérent, je préconise d'imiter Docker et de créer un dossier Terraform dans C:\Programmes, d'y déposer l'exécutable. Vous pouvez le mettre aussi dans un dossier d'outil dans votre répertoire ou là où vous le souhaitez.

Puis, il faut l'ajouter au PATH de votre système. Pour ce faire, il faut lancer en tant qu'Administrateur la commande suivante :
```shell
[Environment]::SetEnvironmentVariable("Path", $env:Path + "; C:\Program Files\Terraform", "Machine")
```

# Installation de GIT (facultatif)

Si vous souhaitez utiliser les fichiers mis à disposition sur GitHub ou même créer un nouveau dépôt pour partager votre configuration, vous pouvez installer le client Git. Il vous permettra de faire toutes les manipulations vers GitHub.

L'installation est classique.

[Lien vers le téléchargement de Git](https://git-scm.com/download/win)

# Installation de Visual Studio Code (facultatif)

Il existe de nombreux éditeurs de code (Notepad++, Sublime Text, Vim…) mais les ayant tous essayés, j'ai une préférence pour Visual Studio Code.

L'installation est classique.

[Lien vers le téléchargement de Visual Studio Code](https://code.visualstudio.com/Download)

De plus, n'hésitez pas à installer des extensions pour Azure, Terraform…

# Installation de Azure CLI

Pour profiter des outils en ligne de commande Azure à travers Powershell, il faut installer Azure CLI.

Le téléchargement et l'installation sont classiques.

[Lien vers le téléchargement de Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&tabs=azure-cli)

# Connexion à votre compte Azure

Une fois Azure CLI installé, connectez votre Powershell à votre compte Azure via la commande :

```shell
az login
```

>_Explication de la commande :_
>- _az : utiliser des commandes fournies par Azure CLI (ne sera plus détaillée ici)_
>- _login : indiquer que l'on souhaite se connecter à son compte Azure pour utiliser Azure CLI. Pour se déconnecter, utilisez « az logout »._
>- _Plus d'info sur la commande :_ [lien](https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login)

Une page web va s'ouvrir, choisissez le compte lié à l'abonnement que vous souhaitez utiliser.

# Sélectionner le bon abonnement

Vous êtes connecté à votre compte et votre abonnement par défaut a été sélectionné.

Listez l'ensemble des abonnements avec leur IDs, celui par defaut aura `IsDefault` à `true` :
```shell
az account list --output table
```
>_Explication de la commande :_
>- _account list : récupérer la liste des abonnements du compte_
>- _--output table : affiche sous forme de tableau_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list)_

Si vous souhaitez en choisir un autre abonnement que celui par défaut :
```shell
az account set --subscription "<SUBSCRIPTIONID>"
```
>_Explication de la commande :_
>- _account set : définir l'abonnement du compte_
>- _--subscription "<SUBSCRIPTIONID>" : fournir l'id de l'abonnement à définir par défaut_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-set)_

Pour contrôler que vous avez bien sélectionné l'abonnement, vous pouvez récupérer l'id de l'abonnement :
```shell
az account show --query "{abonnement:id, tenant:tenantId}"
```
>_Explication de la commande :_
>- _account show : affiche les détails l'abonnement du compte_
>- _--query "{abonnement:id, tenant:tenantId}" : filtre la sortie pour afficher 'id' et 'tenantID' et chacun de ces paramètres a un préfix devant pour rendre plus lisible ('abonnement' et 'tenant')_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-show)_

Le tenantId doit correspondre au répertoire (Azure Active Directory). S'il ne correspond pas ou si vous n'avez pas les droits de création sur ce répertoire, créer un nouveau répertoire Azure Active Directory et basculer votre abonnement dessus.

Notez l'ID de l'abonnement, ça nous servira par la suite.

# Créer un principal de service

Il faut maintenant créer un principale de service sur l'abonnement, que l'on va nommer Terraform pour avoir les droits de créer les ressources sur Azure depuis Terraform.
```shell
az ad sp create-for-rbac --name="terraform" --role="Owner" --scopes="/subscriptions/<SUBSCRIPTIONID>"
```
>_Explication de la commande :_
>- _ad sp : gérer le service principal sur Azure Active Directory pour automatiser l'authentification_
>- _create-for-rbac : créer un principal de service et le configurer pour accéder aux ressources Azure_
>- _--name="terraform" : spécifier le nom du principal de service_
>- _--role="Owner" : définir le rôle du principal de service à Owner pour qu'il puisse créer et gérer ses services sur cet abonnement_
>- _--scopes="/subscriptions/<SUBSCRIPTIONID>" : spécifier l'abonnement sur lequel créer ce principal de service_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create-for-rbac)_

Cette commande va vous retourner des valeurs qu'il va falloir conserver car certaines n'apparaissent qu'une fois (le password).

Nous avons besoins des informations `appID`, `password`, `tenant`.

Note : Si vous perdez le password, relancez la commande qui va mettre à jour le principale de service et générer un nouveau mot de passe.

# Choisir la région Azure

Vous allez devoir choisir une région pour stocker votre fichier d'état, puis une ou plusieurs régions pour le déploiement de vos ressources. Pour connaitre le code de votre région, voici la commande listant les régions disponibles :
```shell
az account list-locations --query 'sort\_by([].{Nom:displayName, Code\_region:name}, &Nom)' --output table
```
>_Explication de la commande :_
>- _account list-locations: lister les régions disponibles pour l'abonnement_
>- _--query 'sort\_by([].{Nom:displayName, Code\_region:name}, &Nom)' : réduire l'affichage pour n'avoir que 'displayName' et 'name' de toutes les valeurs disponibles ('[].'), mettre des titres aux colonnes avec 'Nom' et 'Code\_region' pour la lisibilité et trier par ordre alphabétique sur 'Nom' (avec &Nom) grâce à 'sort\_by'_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list-locations)_

# Créer un groupe de ressource pour le fichier d'état Terraform

Le fichier d'état enregistre l'état du dernier déploiement. Pour travailler en équipe ou éviter une perte de ce fichier (panne de disque dur, ordinateur volé…), il est vivement conseillé de créer un fichier sur un support accessible et pérenne.

Nous allons donc créer un compte de stockage sur Azure dans un groupe de ressources dédié à Terraform.

Commençons par la création du groupe de ressources :
```shell
az group create --name <NAME> --location <REGION>
```
>_Explication de la commande :_
>- _group create : créer un nouveau groupe de ressources_
>- _--name <NAME> : spécifier le nom du groupe de ressources_
>- _--location <REGION> : spécifier la région dans laquelle créer le groupe de ressources_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-create)_

# Créer le stockage pour Terraform

Nous créons d'abord le compte de stockage sur Azure puis nous créerons un conteneur.
```shell
az storage account create --name <NAME> --resource-group <RESOURCEGROUP> --location <REGION>
```
>_Explication de la commande :_
>- _storage account create : créer un compte de stockage_
>- _--name <NAME> : spécifier le nom du compte de stockage_
>- _--resource-group <RESOURCEGROUP> --location <REGION> : specifier le groupe de ressources et la région_
>- _--sku <SKU> : le SKU par défaut est Standard\_RARGS mais vous pouvez spécifier un SKU autre à partir de [cette liste](https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types))_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-create)_

Avec ce nouveau compte de stockage (<ACCOUNTNAME>), nous pouvons créer un conteneur à l'intérieur.
```shell
az storage container create --name <NAME> --account-name <ACCOUNTNAME> --public-access container --resource-group <RESOURCEGROUP>
```
>_Explication de la commande :_
>- _storage container create : créer un conteneur dans le compte de stockage_
>- _--name <NAME> : spécifier le nom du conteneur_
>- _--account-name <ACCOUNTNAME> : spécifier le compte de stockage sur lequel créer le conteneur_
>- _--public-access container : rend le contenu accessible publiquement_
>- _--resource-group <RESOURCEGROUP> --location <REGION> : spécifier le groupe de ressources et la région_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-create)_

Le conteneur est créer, il faut maintenant pouvoir récupérer les identifiants pour se connecter dessus.
```shell
az storage account show-connection-string --name <ACCOUNTNAME> --resource-group <RESOURCEGROUP>
```
>_Explication de la commande :_
>- _storage container show-connection-string : récupérer les chaines de connexion du compte de stockage_
>- _--name <ACCOUNTNAME> : spécifier le nom du compte de stockage_
>- _--resource-group <RESOURCEGROUP> : spécifier le groupe de ressources_
>- _Plus d'info sur la commande : [lien](https://docs.microsoft.com/en-us/cli/azure/storage/account?view=azure-cli-latest#az-storage-account-show-connection-string)_

Récupérer et garder la sortie de la commande, nous en aurons besoin pour connecter Terraform.

# Création des fichiers de configuration Terraform

Le stockage est prêt, tout est installé, il faut maintenant créer nos premiers fichiers Terraform.

Pour obtenir les modèles des fichiers depuis la dernière version en ligne, placez vous dans votre répertoire de travail et clonez le dépôt Git :
```shell
cd <WORKINGDIR>
git clone https://github.com/pezzos/terraform-azure-metsys.git
```
Les deux premiers blocs du fichier provider.tf contiennent la description du backend Terraform et le provider. Nous aurions pu faire deux fichiers séparés, un pour le backend et un pour lister tous les providers mais comme Terraform ne fait pas de distinction, nous avons trouvé plus pratique de grouper ces deux blocs.

La définition du backend sert à décrire où est stocké le fichier d'état de Terraform
```hcl
terraform {
  backend "azurerm" {
    resource\_group\_name = "<RESOURCEGROUP>"
    storage\_account\_name = "<ACCOUNTNAME>"
    container\_name = "<CONTAINERNAME>"
    key = "<PROJECTNAME>.tfstate"
  }
}
```
Il faut donc fournir le compte de stockage avec le groupe de ressource dans lequel il est, le conteneur qui stocke le fichier d'état le nom du fichier d'état. Si vous décidez d'utiliser ce conteneur pour plusieurs projets, choisissez un nom de fichier d'état ('key') avec un nom distinct.

Le second bloque dit simplement à Terraform de charger ce qu'il faut pour communiquer avec Azure RM et de figer la version du provider à 2.24. Le numéro de version est facultatif mais permet de fixer la version sur votre projet pour vous assurer que votre projet fonctionne malgré les évolutions du provider. Vous pouvez changer la version du provider en la récupérant sur la page GitHub du projet du provider (ici https://github.com/terraform-providers/terraform-provider-azurerm).
```hcl
provider "azurerm" {
  version = "~> 2.24"
  features {}
}
```
# Initialisation de votre projet avec Terraform

Vos fichiers sont configurés avec vos informations, Terraform a tout ce qu'il faut pour démarrer. Initialisez le projet pour charger l'extension du provider.
```shell
cd <WORKINGDIR>/<PROJECT>
terraform init
```
# Création de la planification

Terraform est initialisé, il faut maintenant planifier les déploiements.
```shell
cd <WORKINGDIR>/<PROJECT>
terraform plan
```
Là, comme nous n'avons rien mis dans nos fichiers, il n'y a évidemment rien à planifier :

No changes. Infrastructure is up-to-date.

Ajoutons des ressources.

# Création de ressources

Pour commencer simplement, ouvrez le fichier main.tf présent dans la démo et décommentez le premier bloc.
```hcl
resource "azurerm\_resource\_group" "example" {
  name     = "demo"
  location = "France Central"
}
```
Ici, on créé une `resource` de type `azurerm\_resource\_group` que l'on nomme `example` à travers Terraform. Le fait de nommer la ressource permet de s'en resservir à travers Terraform (par exemple, pour fournir le nom du groupe de ressource sur une machine virtuelle).

En paramètre de ce bloc, on indique le nom du groupe de ressource (ici 'demo') et sa localisation.

_Note : sur chaque ressource utilisée dans le dossier de démo, un lien vers la documentation de la ressource est ajouté en commentaire._

# Déploiement des ressources

Vous avez une première ressource de déclarée dans vos fichiers. Utilisons Terraform pour la déployer. Comme précédemment, allez dans votre répertoire de travail et lancez la planification, puis déployez (apply).
```shell
cd <WORKINGDIR>/<PROJECT>
terraform plan
terraform apply
```
On constate qu'à l'étape de planification, la liste des changements apparait avec des symboles pour indiquer si la ressource est ajouté, modifié ou supprimé. Un résumé totalise les différents changements.

Lorsque l'on déploie avec 'apply', toute l'étape de planification se fait à nouveau et une question est posée pour valider le déploiement. Pour éviter ça, il faut stocker la planification dans un fichier (avec l'argument `--out run.tfplan` et la fournir comme plan pour le déploiement.
```hcl
cd <WORKINGDIR>/<PROJECT>
terraform plan --out run.tfplan
terraform apply run.tfplan
```
Voilà, vous avez déployé une ressource sur Azure grâce à Terraform.

# Mise à jour des ressources

Dans le fichier main.tf, décommentez la seconde partie. Dans cet exemple, vous allez déployer un machine virtuelle.

Comme précédemment, il faut planifier le déploiement et déployer.
```shell
cd <WORKINGDIR>/<PROJECT>
terraform plan --out run.tfplan
terraform apply run.tfplan
```
Le déploiement peut durer quelques minutes, c'est normal.

Une fois terminé, vous pouvez constater que le groupe de ressources précédemment créé n'est pas modifié, seule la seconde partie du code est déployé (le réseau et sous-réseau, l'interface réseau et la machine virtuelle).

Dans cette seconde partie du main.tf, on constate que certaines valeurs ne sont pas renseignées mais qu’à la place, des variables permettent de récupérer les valeurs de ressources précédemment créées.

```hcl
resource "azurerm_virtual_network" "example" {
  name                = "vnet-example-fc-01"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
```

Dans cette exemple, au lieu de spécifier à nouveau la région et le nom du groupe de ressources, on récupère les valeurs `location` et `name` de la ressource `azurerm_resource_group` qui a pour nom `example`.


# Destruction des ressources

Maintenant que nous avons pu installer le nécessaire, vu le fonctionnement de Terraform et déployé une petite infrastructure de démo, nous pouvons tout détruire.

Le processus est similaire, on planifie la destruction grâce à l'argument `--destroy` et on la déploie.

```shell
cd <WORKINGDIR>/<PROJECT>
terraform plan --out run.tfplan --destroy
terraform apply run.tfplan
```
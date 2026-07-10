------------------------------------------------------------------------------------------------------
ATELIER FROM IMAGE TO CLUSTER
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : Cet atelier consiste à **industrialiser le cycle de vie d’une application** simple en construisant une **image applicative Nginx** personnalisée avec **Packer**, puis en déployant automatiquement cette application sur un **cluster Kubernetes** léger (K3d) à l’aide d’**Ansible**, le tout dans un environnement reproductible via **GitHub Codespaces**.
L’objectif est de comprendre comment des outils d’Infrastructure as Code permettent de passer d’un artefact applicatif maîtrisé à un déploiement cohérent et automatisé sur une plateforme d’exécution.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
**Faites un Fork de ce projet**. Si besion, voici une vidéo d'accompagnement pour vous aider dans les "Forks" : [Forker ce projet](https://youtu.be/p33-7XQ29zQ) 
  
Ensuite depuis l'onglet [CODE] de votre nouveau Repository, **ouvrez un Codespace Github**.

DONE 
  
---------------------------------------------------
Séquence 2 : Création du cluster Kubernetes K3d
---------------------------------------------------
Objectif : Créer votre cluster Kubernetes K3d  
Difficulté : Simple (~5 minutes)
---------------------------------------------------
Vous allez dans cette séquence mettre en place un cluster Kubernetes K3d contenant un master et 2 workers.  
Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Création du cluster K3d**  
```
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```
```
k3d cluster create lab \
  --servers 1 \
  --agents 2
```
**vérification du cluster**  
```
kubectl get nodes
```
**Déploiement d'une application (Docker Mario)**  
```
kubectl create deployment mario --image=sevenajay/mario
kubectl expose deployment mario --type=NodePort --port=80
kubectl get svc
```
**Forward du port 80**  
```
kubectl port-forward svc/mario 8080:80 >/tmp/mario.log 2>&1 &
```
**Réccupération de l'URL de l'application Mario** 
Votre application Mario est déployée sur le cluster K3d. Pour obtenir votre URL cliquez sur l'onglet **[PORTS]** dans votre Codespace et rendez public votre port **8080** (Visibilité du port).
Ouvrez l'URL dans votre navigateur et jouer !

---------------------------------------------------
Séquence 3 : Exercice
---------------------------------------------------
Objectif : Customisez un image Docker avec Packer et déploiement sur K3d via Ansible
Difficulté : Moyen/Difficile (~2h)
---------------------------------------------------  
Votre mission (si vous l'acceptez) : Créez une **image applicative customisée à l'aide de Packer** (Image de base Nginx embarquant le fichier index.html présent à la racine de ce Repository), puis déployer cette image customisée sur votre **cluster K3d** via **Ansible**, le tout toujours dans **GitHub Codespace**.  

**Architecture cible :** Ci-dessous, l'architecture cible souhaitée.   
  
![Screenshot Actions](Architecture_cible.png)   
  
---------------------------------------------------  
## Processus de travail
1. Installation du cluster Kubernetes K3d (Séquence 1)
2. Installation de Packer et Ansible
3. Build de l'image customisée (Nginx + index.html)
4. Import de l'image dans K3d
5. Déploiement du service dans K3d via Ansible
6. Ouverture des ports et vérification du fonctionnement

---------------------------------------------------
Séquence 4 : Documentation  
Difficulté : Facile (~30 minutes)
---------------------------------------------------
**Complétez et documentez ce fichier README.md** pour nous expliquer comment utiliser votre solution.  
Faites preuve de pédagogie et soyez clair dans vos expliquations et processus de travail.  
   
---------------------------------------------------
Evaluation
---------------------------------------------------
Cet atelier, **noté sur 20 points**, est évalué sur la base du barème suivant :  
- Repository exécutable sans erreur majeure (4 points)
- Fonctionnement conforme au scénario annoncé (4 points)
- Degré d'automatisation du projet (utilisation de Makefile ? script ? ...) (4 points)
- Qualité du Readme (lisibilité, erreur, ...) (4 points)
- Processus travail (quantité de commits, cohérence globale, interventions externes, ...) (4 points) 

-------------------------------------------------------------------------------------------------------------------------------
# Atelier From Image to Cluster

## Objectif

Industrialiser le cycle de vie d'une application Nginx :

1. **Packer** construit une image Docker Nginx personnalisée qui embarque le `index.html` du repository.
2. **K3d** fournit un cluster Kubernetes local léger (1 master + 2 workers).
3. **Ansible** importe l'image dans le cluster et déploie automatiquement le `Deployment` + `Service` Kubernetes correspondants.
4. L'ensemble tourne dans **GitHub Codespaces**, sans dépendance externe.

```
index.html ──(Packer)──▶ image Docker nginx-custom ──(k3d image import)──▶ cluster K3d
                                                              │
                                                     (Ansible) ▼
                                              Deployment + Service Kubernetes
```

## Structure du projet

```
.
├── index.html                     # Page servie par Nginx (à personnaliser)
├── packer/
│   └── docker-nginx.pkr.hcl       # Build de l'image Nginx customisée
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/hosts.ini        # Inventaire (exécution en local)
│   └── deploy.yml                 # Import image + déploiement K8s
├── Makefile                       # Orchestration de bout en bout
└── README.md
```

## Prérequis

- Un Codespace GitHub ouvert sur ce repository (voir Séquence 1).
- Rien d'autre à installer manuellement : `make` s'occupe d'installer `k3d`, `packer` et `ansible` s'ils sont absents.

## Utilisation rapide (tout automatique)

```bash
make all
```

Cette commande enchaîne, dans l'ordre :

| Étape | Cible Makefile | Ce qu'elle fait |
|---|---|---|
| 1 | `cluster` | Installe k3d si besoin, crée le cluster `lab` (1 master + 2 workers) |
| 2 | `packer-build` | Construit l'image `nginx-custom:latest` avec Packer (Nginx + `index.html`) |
| 3 | `deploy` | Lance le playbook Ansible : importe l'image dans K3d, applique le Deployment et le Service Kubernetes |
| 4 | `port-forward` | Expose l'application sur `localhost:8081` |

## Étapes détaillées (si vous préférez piloter à la main)

### 1. Créer le cluster K3d
```bash
make cluster
kubectl get nodes
```
Vous devez voir 1 nœud `server` et 2 nœuds `agent`, tous à l'état `Ready`.

### 2. Construire l'image customisée avec Packer
```bash
make packer-build
```
Packer part de l'image officielle `nginx:stable-alpine`, y copie le `index.html` présent à la racine du repository dans `/usr/share/nginx/html/`, puis tague le résultat `nginx-custom:latest` dans le registre Docker local du Codespace.

Vérification :
```bash
docker images | grep nginx-custom
```

### 3. Déployer sur K3d avec Ansible
```bash
make deploy
```
Le playbook `ansible/deploy.yml` :
- vérifie que l'image `nginx-custom:latest` existe bien en local (sinon il échoue avec un message explicite invitant à lancer `make packer-build`) ;
- vérifie que le cluster `lab` existe (sinon il échoue en invitant à lancer `make cluster`) ;
- importe l'image dans le cluster K3d via `k3d image import` (indispensable : K3d ne voit pas le registre Docker de l'hôte par défaut) ;
- génère et applique un `Deployment` (2 réplicas) et un `Service` de type `NodePort` pour l'application ;
- attend que le rollout soit terminé (`kubectl rollout status`).

### 4. Exposer et tester l'application
```bash
make port-forward
```
Puis, dans l'onglet **PORTS** du Codespace :
1. Repérez le port `8081`.
2. Passez sa visibilité en **Public**.
3. Ouvrez l'URL générée : vous devez voir votre page `index.html`, servie depuis le cluster Kubernetes.

### 5. Vérifier l'état du déploiement
```bash
make status
```
Affiche les pods, le deployment et le service associés au label `app=nginx-custom`.

## Nettoyage

```bash
make clean
```
Supprime le Deployment, le Service, et détruit le cluster K3d `lab`.

## Personnalisation

- **Changer la page servie** : modifiez `index.html` à la racine du repo, puis relancez `make packer-build && make deploy`.
- **Changer le nombre de réplicas / le port** : variables `replicas`, `node_port`, `container_port` en tête de `ansible/deploy.yml`.
- **Nom du cluster** : variable `CLUSTER_NAME` dans le `Makefile` (et `cluster_name` dans `deploy.yml` — gardez les deux synchronisées).

## Résumé des commandes essentielles

```bash
make all            # tout en une commande
make cluster        # étape 1 : cluster K3d
make packer-build   # étape 2 : build image Packer
make deploy          # étape 3 : import + déploiement Ansible
make port-forward    # étape 4 : exposition locale
make status          # vérification
make clean            # nettoyage complet
```

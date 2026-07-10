CLUSTER_NAME := lab
APP_NAME := nginx-custom
LOCAL_PORT := 8081

.PHONY: all cluster install-tools packer-build deploy port-forward status clean

all: cluster packer-build deploy port-forward

## Installe k3d, Packer et Ansible si absents
install-tools:
	@which k3d      >/dev/null 2>&1 || curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
	@which packer   >/dev/null 2>&1 || (curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
		sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" && \
		sudo apt-get update && sudo apt-get install -y packer)
	@which ansible-playbook >/dev/null 2>&1 || (sudo apt-get update && sudo apt-get install -y ansible)

## Crée le cluster K3d (1 master + 2 workers) s'il n'existe pas déjà
cluster: install-tools
	@k3d cluster list | grep -q $(CLUSTER_NAME) || k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 2
	kubectl get nodes

## Construit l'image Nginx customisée avec Packer
packer-build: install-tools
	cd packer && packer init . && packer build .

## Importe l'image dans K3d et déploie via Ansible
deploy: install-tools
	cd ansible && ansible-playbook deploy.yml

## Expose l'application en local (port-forward)
port-forward:
	@pkill -f "port-forward svc/$(APP_NAME)" 2>/dev/null || true
	kubectl port-forward svc/$(APP_NAME) $(LOCAL_PORT):80 > /tmp/$(APP_NAME).log 2>&1 &
	@echo "Application disponible sur le port $(LOCAL_PORT)."
	@echo "Rendez ce port PUBLIC depuis l'onglet PORTS du Codespace pour obtenir l'URL."

## Affiche l'état du déploiement
status:
	kubectl get all -l app=$(APP_NAME)

## Nettoie les ressources créées (deployment, service, cluster)
clean:
	kubectl delete deployment $(APP_NAME) --ignore-not-found
	kubectl delete svc $(APP_NAME) --ignore-not-found
	k3d cluster delete $(CLUSTER_NAME)

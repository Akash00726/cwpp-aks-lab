#!/bin/bash
set -euo pipefail

# ==============================================================================
# How to Use the Script:
# 1. Preparation:
#    - Ensure Azure CLI, kubectl, helm, and git are installed.
#    - Run 'chmod +x lab.sh' to make the script executable.
#    - Authenticate to Azure using 'az login'.
# 2. Workflow:
#    - Check environment: ./lab.sh doctor
#    - Deploy infrastructure: ./lab.sh create
#    - Set up the cluster: ./lab.sh bootstrap
#    - Deploy your application: ./lab.sh deploy
#    - Monitoring: ./lab.sh status
#    - Clean up: ./lab.sh destroy
# ==============================================================================

# --- Configuration ---
LOCATION="${LOCATION:-centralindia}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-cwpp-lab}"
AKS_NAME="${AKS_NAME:-aks-cwpp-lab}"
ACR_NAME="${ACR_NAME:-acrcwpplab}"
GITHUB_APP_ID="2d4e1dff-f101-4ee4-bf89-6000997fe7e9"
TAGS="Environment=Dev Owner=SecurityTeam Project=CWPP-Lab"

trap 'echo "ERROR: Script failed at line $LINENO. Please review the output above."; exit 1' ERR

doctor(){ 
    echo "VERBOSE: Checking required dependencies..."
    for c in az kubectl helm docker git; do 
        command -v $c >/dev/null || { echo "ERROR: $c is missing"; exit 1; }
    done
    az account show >/dev/null || { echo "ERROR: Not logged into Azure"; exit 1; }
    echo "VERBOSE: All dependencies and authentication checks passed."
}

create(){
    echo "VERBOSE: Setting subscription context..."
    az account set --subscription "e9eb27d2-7b83-4e01-9cd3-49f193b4ba97"
    echo "VERBOSE: Starting infrastructure provisioning for $RESOURCE_GROUP in $LOCATION..."
    
    if [ $(az group exists -n "$RESOURCE_GROUP") = false ]; then
        echo "VERBOSE: Resource Group not found. Creating $RESOURCE_GROUP..."
        az group create -n "$RESOURCE_GROUP" -l "$LOCATION" --tags $TAGS
    else
        echo "VERBOSE: Resource Group $RESOURCE_GROUP already exists."
    fi
    
    echo "VERBOSE: Creating Azure Container Registry $ACR_NAME..."
    az acr create -g "$RESOURCE_GROUP" -n "$ACR_NAME" --sku Basic --admin-enabled false
    
    echo "VERBOSE: Registry created. Pausing for 20 seconds..."
    sleep 20
    
    ACR_ID=$(az acr show -n "$ACR_NAME" --query id -o tsv | tr -d '\r')
    
    echo "VERBOSE: Resolving Object ID for Service Principal $GITHUB_APP_ID..."
    # Extract the Object ID (id) using the App ID (appId)
    SP_OBJECT_ID=$(az ad sp show --id "$GITHUB_APP_ID" --query id -o tsv | tr -d '[:space:]')
    
    if [ -z "$SP_OBJECT_ID" ]; then
        echo "ERROR: Could not resolve Object ID for $GITHUB_APP_ID"
        exit 1
    fi
    echo "VERBOSE: DEBUG - Object ID length is: ${#SP_OBJECT_ID}"
    echo "VERBOSE: Assigning AcrPush role to Object ID: $SP_OBJECT_ID"
    echo "VERBOSE: ACR ID - $ACR_ID"
    az role assignment create --assignee "$SP_OBJECT_ID" --role "AcrPush" --scope "$ACR_ID"
    
    echo "VERBOSE: Provisioning AKS cluster $AKS_NAME (this may take several minutes)..."
    az aks create -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
        --tier free --node-count 1 --node-vm-size Standard_B2s \
        --enable-managed-identity --enable-oidc-issuer --enable-workload-identity \
        --attach-acr "$ACR_NAME" --generate-ssh-keys --tags $TAGS
    
    echo "VERBOSE: Downloading AKS credentials..."
    az aks get-credentials -g "$RESOURCE_GROUP" -n "$AKS_NAME" --overwrite-existing
    echo "VERBOSE: Infrastructure setup complete."
}

bootstrap(){
    echo "VERBOSE: Bootstrapping Kubernetes namespaces..."
    for ns in argocd cwpp-dev cwpp-test cwpp-prod falco monitoring security; do 
        echo "VERBOSE: Ensuring namespace '$ns' exists..."
        kubectl create ns $ns --dry-run=client -o yaml | kubectl apply -f -
    done
    
    echo "VERBOSE: Installing Argo CD into namespace 'argocd'..."
    kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "VERBOSE: Waiting for Argo CD to be available..."
    kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s
    echo "VERBOSE: Cluster bootstrap complete."
}

deploy(){ echo "VERBOSE: Applying GitOps application manifests..."; kubectl apply -f argocd/application.yaml; }
info(){ echo "VERBOSE: Fetching environment info..."; az acr show -n "$ACR_NAME" --query loginServer -o tsv; kubectl get nodes -o wide; }
status(){ echo "VERBOSE: Querying cluster status..."; kubectl get nodes; kubectl get pods -A; }
login(){ echo "VERBOSE: Authenticating Docker to $ACR_NAME..."; az acr login -n "$ACR_NAME"; }

destroy(){
    read -p "Type DELETE to remove $RESOURCE_GROUP: " a
    if [ "$a" = "DELETE" ]; then
        echo "VERBOSE: Deleting resource group $RESOURCE_GROUP. This may take some time..."
        # Removed --no-wait to make this a synchronous, blocking operation
        az group delete -n "$RESOURCE_GROUP" --yes
        echo "VERBOSE: Resource group $RESOURCE_GROUP has been successfully deleted."
    else
        echo "VERBOSE: Deletion cancelled."
    fi
}

case "${1:-help}" in
    create|bootstrap|deploy|info|status|doctor|login|destroy) "${1}" ;;
    *) echo "Usage: ./lab.sh {create|bootstrap|deploy|info|status|doctor|login|destroy}";;
esac
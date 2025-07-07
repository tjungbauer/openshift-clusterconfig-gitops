#!/bin/bash
#set -euf -o pipefail
RED='\033[37;41m'  # White text with red background
CYAN_BG='\033[30;46m' # Black text with cyan background
GREEN='\033[30;42m'  # Black text with green background
NC='\033[0m' # No Color

TIMER=${TIMER:-45} # Sleep timer to initially wait for the gitops-operator to be deployed before starting testing the deployments. 
RECHECK_TIMER=${RECHECK_TIMER:-10}

HELM_BIN="/usr/bin/env helm"
HELM_CHARTS="https://charts.stderr.at/"

function error() {
    printf "%b%s%b" "${RED}" "$1" "${NC}"
    exit 1
}

function add_helm_repo() {

    printf "\nAdding Helm Repo %s\n" "${HELM_CHARTS}"
    $HELM_BIN repo add --force-update tjungbauer ${HELM_CHARTS}
    $HELM_BIN repo update > /dev/null
}

# check if operator is already installed
function check_op_status() {
    local get_status
    get_status=$(oc get subscription.operators.coreos.com/openshift-gitops-operator -n openshift-gitops-operator -o jsonpath='{.status.conditions[0].reason}')

    if [[ "$get_status" == "AllCatalogSourcesHealthy" ]]; then
        printf "\nSubscription does exist already\n"
        return 0
    else
        return 1
    fi
}

function wait_for_resource() {
    local resource=$1
    local namespace=${2:-}
    printf "\n%bWaiting for %s %b\n" "${CYAN_BG}" "${resource}" "${NC}"
    until oc get "$resource" ${namespace:+-n $namespace} 1>/dev/null 2>&1; do
        printf "."
        sleep $RECHECK_TIMER
    done
    printf "\n%b%s is ready%b\n" "${GREEN}" "$resource" "${NC}"
}

# Deploy openshift-gitops-operator
function deploy() {

    printf "\nCheck if GitOps Operator is already deployed\n"

    if check_op_status; then
        printf "Operator is already installed. Verifying if Pods are running\n"
        wait_for_argocd_pods
    else

        printf "\n%bDeploying OpenShift GitOps Operator%b\n" "${RED}" "${NC}"

        add_helm_repo

        oc adm new-project openshift-gitops-operator 1>/dev/null 2>&1 || true
        printf "\n"
        $HELM_BIN template --set 'helper-operator.enabled=true' --set 'helper-status-checker.enabled=true' --set 'gitopsinstances.openshift_gitops.clusterAdmin=disabled' --verify -f values-openshift-gitops.yaml tjungbauer/openshift-gitops | oc create -f -

        printf "\nGive the gitops-operator some time to be installed. %bWaiting for %s seconds...%b\n" "${RED}" "${TIMER}" "${NC}"
        TIMER_TMP=0
        while [[ $TIMER_TMP -le $TIMER ]]
            do 
            printf "."
            sleep 1
            let "TIMER_TMP=TIMER_TMP+1"
          done
        printf "\nLet's continue\n"

        wait_for_resource crd/argocds.argoproj.io
        wait_for_resource ns/openshift-gitops
        wait_for_resource deployment/cluster openshift-gitops
        wait_for_argocd_pods
        sleep $RECHECK_TIMER
        configure_argocd

    fi

    deploy_app_of_apps

    printf "\n%bArgo CD for cluster configuration has been deployed. You can now use it to synchronize required configurations.%b\n" "${GREEN}" "${NC}"

}

# Be sure that all Deployments are ready
function wait_for_argocd_pods() {
    local deployments=(openshift-gitops-server)
    for i in "${deployments[@]}"; do
        printf "\n%bWaiting for deployment $i %b\n" "${CYAN_BG}" "${NC}"
        oc rollout status deployment "$i" -n openshift-gitops
    done
}

# Configure the Argo CD Operator CRD
function configure_argocd() {
  
    printf "\n%bLets configure ArgoCD CRD%b\n" "${RED}" "${NC}"

    $HELM_BIN template --set 'gitopsinstances.openshift_gitops.enabled=true' --set 'gitopsinstances.openshift_gitops.clusterAdmin=enabled' --verify -f values-openshift-gitops.yaml tjungbauer/openshift-gitops | oc replace -f -
    oc apply -f https://raw.githubusercontent.com/tjungbauer/helm-charts/main/charts/openshift-gitops/PATCH_openshift-gitops-crb.yaml
  
    printf "\n%bRestarting all ArgoCD CRD pods%b\n" "${RED}" "${NC}"
    oc delete pods --all -n openshift-gitops 1>/dev/null 2>&1

    sleep $RECHECK_TIMER
    wait_for_argocd_pods

    printf "%bGitOps Operator ready... again%b\n" "${GREEN}" "${NC}\n"

}

# Deploy the Application of Applications
function deploy_app_of_apps() {
    printf "\n"
    $HELM_BIN upgrade --install --dependency-update --values ./base/init_app_of_apps/values.yaml --set 'namespace=openshift-gitops' app-of-apps ./base/init_app_of_apps
}

command -v $HELM_BIN >/dev/null 2>&1 || error "Could not execute helm binary!"
# Let's deploy "latest" from now on, since this is the new channel to use
deploy "latest"

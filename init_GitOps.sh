#!/bin/bash
#set -euf -o pipefail
RED='\033[37;41m'  # White text with red background
CYAN_BG='\033[30;46m' # Black text with cyan background
GREEN='\033[30;42m'  # Black text with green background
NC='\033[0m' # No Color
TIMER=45 # Sleep timer to initially wait for the gitops-operator to be deployed before starting testing the deployments. 
RECHECK_TIMER=10

HELM="/usr/bin/env helm"
HELM_CHARTS="https://charts.stderr.at/"

function error() {
    echo "$1"
    exit 1
}

function add_helm_repo() {

  printf "\nAdding Helm Repo %s\n" "${HELM_CHARTS}"
  $HELM repo add --force-update tjungbauer ${HELM_CHARTS}
  $HELM repo update > /dev/null

}

# check if operator is already installed
function check_op_status() {
  get_status=`oc get subscription.operators.coreos.com/openshift-gitops-operator -n openshift-operators -o jsonpath='{.status.conditions[0].reason}'`

  if [ $get_status == "AllCatalogSourcesHealthy" ]; then
      return 0
  else
      return 1
  fi

}

# Deploy openshift-gitops-operator
function deploy() {

  printf "\nCheck if GitOps Operator is already deployed\n"
  check_op_status

  local res=$?
  if [ $res -eq "0" ]; then
      printf "Operator is already installed. Verifying if Pods are running \n"
  else

    printf "\n%bDeploying OpenShift GitOps Operator%b\n" "${RED}" "${NC}"

    add_helm_repo

    oc adm new-project openshift-gitops-operator
    $HELM upgrade --install \
        --set 'gitops.subscription.channel='$1 \
        --set 'gitops.enabled=true' \
        --set 'gitops.clusterAdmin=true' \
        --set 'gitops.namespace.name=openshift-gitops-operator' \
        --create-namespace openshift-gitops-operator tjungbauer/openshift-gitops

    printf "\nGive the gitops-operator some time to be installed. %bWaiting for %s seconds...%b\n" "${RED}" "${TIMER}" "${NC}"
    TIMER_TMP=0
    while [[ $TIMER_TMP -le $TIMER ]]
      do 
        echo -n "."
        sleep 1
        let "TIMER_TMP=TIMER_TMP+1"
      done
    printf "\nLet's continue\n"

    printf "\n%bWaiting for openshift-gitops namespace to be created. Checking every %s seconds.%b\n" "${RED}" "${RECHECK_TIMER}" "${NC}"
    until oc get ns openshift-gitops
    do
      sleep $RECHECK_TIMER;
    done

    printf "\n%bWaiting for deployments to start. Checking every %s seconds.%b\n" "${RED}" "${RECHECK_TIMER}" "${NC}"
    until oc get deployment cluster -n openshift-gitops
    do
      sleep $RECHECK_TIMER;
    done

  fi

  printf "\nWaiting for all pods to be created"
  waiting_for_argocd_pods

  printf "%bGitOps Operator ready%b\n" "${GREEN}" "${NC}"

  patch_argocd

  deploy_app_of_apps

  printf "\n%bArgo CD for cluster configuration has been deployed. You can now use it to synchronize required configurations.%b\n" "${GREEN}" "${NC}"

}

# Be sure that all Deployments are ready
function waiting_for_argocd_pods() {

  deployments=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)
  for i in "${deployments[@]}";
  do
    printf "\n%bWaiting for deployment $i %b\n" "${CYAN_BG}" "${NC}"
    oc rollout status deployment "$i" -n openshift-gitops
  done
}

# PATCH the ArgoCD Operator CRD
function patch_argocd() {
  
  printf "\nLets use our patched ArgoCD CRD\n"

  patch_argo=`oc apply -f https://raw.githubusercontent.com/tjungbauer/helm-charts/main/charts/openshift-gitops/PATCH_openshift-gitops.yaml`
  add_crb=`oc apply -f https://raw.githubusercontent.com/tjungbauer/helm-charts/main/charts/openshift-gitops/PATCH_openshift-gitops-crb.yaml`

  if [[ "$patch_argo" == *"unchanged"* ]] && [[ "$add_crb" == *"unchanged"* ]]; then
    echo "ArgoCD already patched"
  else

    oc delete pods --all -n openshift-gitops

    sleep $RECHECK_TIMER
    waiting_for_argocd_pods

    printf "%bGitOps Operator ready... again%b\n" "${GREEN}" "${NC}\n"

  fi

}

# Deploy the Application of Applications
function deploy_app_of_apps() {

  $HELM upgrade --install --values ./base/init_app_of_apps/values.yaml --namespace=openshift-gitops app-of-apps ./base/init_app_of_apps

}

$HELM >/dev/null 2>&1 || error "Could not execute helm binary!"

# Let's deploy "latest" from now on, since this is the new channel to use
deploy "latest"

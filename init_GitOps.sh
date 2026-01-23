#!/bin/bash
set -euo pipefail

# Colors
readonly RED='\033[37;41m'
readonly CYAN_BG='\033[30;46m'
readonly GREEN='\033[30;42m'
readonly YELLOW='\033[0;33m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Configuration (can be overridden via environment)
readonly DEBUG=${DEBUG:-false}
readonly TIMER=${TIMER:-45}
readonly RECHECK_TIMER=${RECHECK_TIMER:-10}
readonly HELM_CHARTS="https://charts.stderr.at/"
readonly HELM_REPO_NAME="tjungbauer"
readonly GITOPS_NAMESPACE="openshift-gitops"
readonly GITOPS_OPERATOR_NAMESPACE="openshift-gitops-operator"

# Find helm binary
HELM_BIN=$(command -v helm) || { echo "helm not found in PATH"; exit 1; }
readonly HELM_BIN

#######################################
# Print debug message (only when DEBUG=true)
# Arguments:
#   $1 - Message
#######################################
debug() {
    if [[ "$DEBUG" == "true" ]]; then
        printf "%b[DEBUG]%b %s\n" "${YELLOW}" "${NC}" "$1"
    fi
}

#######################################
# Print debug message for commands (only when DEBUG=true)
# Arguments:
#   $1 - Command description
#   $@ - Command and arguments
#######################################
debug_cmd() {
    if [[ "$DEBUG" == "true" ]]; then
        printf "%b[DEBUG]%b Executing: %b%s%b\n" "${YELLOW}" "${NC}" "${DIM}" "$*" "${NC}"
    fi
}

#######################################
# Print error message and exit
# Arguments:
#   $1 - Error message
#######################################
error() {
    printf "%b%s%b\n" "${RED}" "$1" "${NC}" >&2
    exit 1
}

#######################################
# Print info message
# Arguments:
#   $1 - Message
#######################################
info() {
    printf "\n%b%s%b\n" "${CYAN_BG}" "$1" "${NC}"
}

#######################################
# Print success message
# Arguments:
#   $1 - Message
#######################################
success() {
    printf "%b%s%b\n" "${GREEN}" "$1" "${NC}"
}

#######################################
# Check required dependencies
#######################################
check_dependencies() {
    local deps=("helm" "oc")
    
    debug "Checking required dependencies: ${deps[*]}"
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            debug "Found $dep at $(command -v "$dep")"
        else
            error "Required command not found: $dep"
        fi
    done

    # Verify cluster connection
    debug "Verifying OpenShift cluster connection..."
    if oc whoami >/dev/null 2>&1; then
        debug "Logged in as: $(oc whoami)"
        debug "Current context: $(oc whoami --show-context 2>/dev/null || echo 'N/A')"
        debug "API server: $(oc whoami --show-server 2>/dev/null || echo 'N/A')"
    else
        error "Not logged into OpenShift cluster. Run 'oc login' first."
    fi
}

#######################################
# Add Helm repository
#######################################
add_helm_repo() {
    info "Adding Helm Repo ${HELM_CHARTS}"
    
    debug_cmd "$HELM_BIN" repo add --force-update "$HELM_REPO_NAME" "$HELM_CHARTS"
    "$HELM_BIN" repo add --force-update "$HELM_REPO_NAME" "$HELM_CHARTS"
    
    debug_cmd "$HELM_BIN" repo update
    "$HELM_BIN" repo update >/dev/null
    
    debug "Helm repositories configured:"
    if [[ "$DEBUG" == "true" ]]; then
        "$HELM_BIN" repo list
    fi
}

#######################################
# Check if GitOps operator subscription exists and is healthy
# Returns:
#   0 if healthy, 1 otherwise
#######################################
check_op_status() {
    local get_status
    
    debug "Checking subscription status in namespace: $GITOPS_OPERATOR_NAMESPACE"
    debug_cmd oc get subscription.operators.coreos.com/openshift-gitops-operator -n "$GITOPS_OPERATOR_NAMESPACE" -o jsonpath='{.status.conditions[0].reason}'
    
    get_status=$(oc get subscription.operators.coreos.com/openshift-gitops-operator \
        -n "$GITOPS_OPERATOR_NAMESPACE" \
        -o jsonpath='{.status.conditions[0].reason}' 2>/dev/null) || {
        debug "Subscription not found or error occurred"
        return 1
    }

    debug "Subscription status: $get_status"
    [[ "$get_status" == "AllCatalogSourcesHealthy" ]]
}

#######################################
# Wait for a Kubernetes resource to exist
# Arguments:
#   $1 - Resource (e.g., crd/argocds.argoproj.io)
#   $2 - Namespace (optional)
#######################################
wait_for_resource() {
    local resource=$1
    local namespace=${2:-}
    local ns_flag=()
    local attempt=0

    [[ -n "$namespace" ]] && ns_flag=(-n "$namespace")

    debug "Waiting for resource: $resource ${namespace:+in namespace: $namespace}"
    
    info "Waiting for ${resource}"
    until oc get "$resource" "${ns_flag[@]}" >/dev/null 2>&1; do
        ((attempt++))
        debug "Attempt $attempt: Resource $resource not ready, sleeping ${RECHECK_TIMER}s"
        printf "."
        sleep "$RECHECK_TIMER"
    done
    
    debug "Resource $resource is now available (after $attempt attempts)"
    success "${resource} is ready"
}

#######################################
# Wait for ArgoCD deployments to be ready
#######################################
wait_for_argocd_pods() {
    local -a deployments=(openshift-gitops-server)

    debug "Deployments to wait for: ${deployments[*]}"
    
    for deployment in "${deployments[@]}"; do
        info "Waiting for deployment ${deployment}"
        debug_cmd oc rollout status deployment "$deployment" -n "$GITOPS_NAMESPACE" --timeout=300s
        oc rollout status deployment "$deployment" -n "$GITOPS_NAMESPACE" --timeout=300s
    done
    
    if [[ "$DEBUG" == "true" ]]; then
        debug "Current pods in $GITOPS_NAMESPACE:"
        oc get pods -n "$GITOPS_NAMESPACE" -o wide
    fi
}

#######################################
# Configure the ArgoCD CRD
#######################################
configure_argocd() {
    local helm_cmd
    local patch_url="https://raw.githubusercontent.com/tjungbauer/helm-charts/main/charts/openshift-gitops/PATCH_openshift-gitops-crb.yaml"
    
    info "Configuring ArgoCD CRD"

    helm_cmd="$HELM_BIN template \
        --set 'gitopsinstances.openshift_gitops.enabled=true' \
        --set 'gitopsinstances.openshift_gitops.clusterAdmin=enabled' \
        --verify \
        -f values-openshift-gitops.yaml \
        ${HELM_REPO_NAME}/openshift-gitops"
    
    debug_cmd "$helm_cmd | oc replace -f -"
    "$HELM_BIN" template \
        --set 'gitopsinstances.openshift_gitops.enabled=true' \
        --set 'gitopsinstances.openshift_gitops.clusterAdmin=enabled' \
        --verify \
        -f values-openshift-gitops.yaml \
        "${HELM_REPO_NAME}/openshift-gitops" | oc replace -f -

    debug "Applying ClusterRoleBinding patch from: $patch_url"
    debug_cmd oc apply -f "$patch_url"
    oc apply -f "$patch_url"

    info "Restarting ArgoCD pods"
    debug "Deleting all pods in namespace: $GITOPS_NAMESPACE"
    debug_cmd oc delete pods --all -n "$GITOPS_NAMESPACE"
    
    if [[ "$DEBUG" == "true" ]]; then
        debug "Pods before deletion:"
        oc get pods -n "$GITOPS_NAMESPACE" --no-headers 2>/dev/null || debug "No pods found"
    fi
    
    oc delete pods --all -n "$GITOPS_NAMESPACE" >/dev/null 2>&1

    debug "Sleeping ${RECHECK_TIMER}s before checking pod status"
    sleep "$RECHECK_TIMER"
    wait_for_argocd_pods

    success "GitOps Operator ready"
}

#######################################
# Deploy the Application of Applications
#######################################
deploy_app_of_apps() {
    local helm_cmd
    
    info "Deploying App of Apps"
    
    debug "Switching to project: $GITOPS_NAMESPACE"
    debug_cmd oc project "$GITOPS_NAMESPACE"
    oc project "$GITOPS_NAMESPACE"
    
    helm_cmd="$HELM_BIN upgrade --install --dependency-update \
        --values ./base/init_app_of_apps/values.yaml \
        --set namespace=${GITOPS_NAMESPACE} \
        app-of-apps ./base/init_app_of_apps"
    
    debug_cmd "$helm_cmd"
    "$HELM_BIN" upgrade --install --dependency-update \
        --values ./base/init_app_of_apps/values.yaml \
        --set "namespace=${GITOPS_NAMESPACE}" \
        app-of-apps ./base/init_app_of_apps
        
    if [[ "$DEBUG" == "true" ]]; then
        debug "Helm releases in namespace $GITOPS_NAMESPACE:"
        "$HELM_BIN" list -n "$GITOPS_NAMESPACE"
    fi
}

#######################################
# Wait with progress indicator
# Arguments:
#   $1 - Seconds to wait
#   $2 - Message (optional)
#######################################
wait_with_progress() {
    local seconds=$1
    local message=${2:-"Waiting"}
    local i

    debug "Starting wait: ${seconds}s (${message})"
    
    printf "\n%s for %d seconds: " "$message" "$seconds"
    for ((i = 0; i < seconds; i++)); do
        printf "."
        sleep 1
    done
    printf " done\n"
    
    debug "Wait completed"
}

#######################################
# Print configuration (debug only)
#######################################
print_config() {
    if [[ "$DEBUG" == "true" ]]; then
        printf "\n%b[DEBUG] Current Configuration:%b\n" "${YELLOW}" "${NC}"
        printf "  TIMER:                    %s\n" "$TIMER"
        printf "  RECHECK_TIMER:            %s\n" "$RECHECK_TIMER"
        printf "  HELM_BIN:                 %s\n" "$HELM_BIN"
        printf "  HELM_CHARTS:              %s\n" "$HELM_CHARTS"
        printf "  HELM_REPO_NAME:           %s\n" "$HELM_REPO_NAME"
        printf "  GITOPS_NAMESPACE:         %s\n" "$GITOPS_NAMESPACE"
        printf "  GITOPS_OPERATOR_NAMESPACE:%s\n" "$GITOPS_OPERATOR_NAMESPACE"
        printf "\n"
    fi
}

#######################################
# Main deployment function
#######################################
deploy() {
    info "Checking if GitOps Operator is already deployed"

    if check_op_status; then
        printf "Operator is already installed. Verifying pods are running...\n"
        debug "Operator subscription found and healthy, skipping installation"
        wait_for_argocd_pods
        sleep "$RECHECK_TIMER"
        configure_argocd
    else
        info "Deploying OpenShift GitOps Operator"
        debug "Operator subscription not found, proceeding with fresh installation"

        add_helm_repo

        # Create namespace (ignore if exists)
        # oc adm new-project "$GITOPS_OPERATOR_NAMESPACE" >/dev/null 2>&1 || true

        local helm_cmd="$HELM_BIN template \
            --set 'helper-operator.enabled=true' \
            --set 'helper-status-checker.enabled=true' \
            --set 'gitopsinstances.openshift_gitops.clusterAdmin=disabled' \
            --verify \
            --force \
            -f values-openshift-gitops.yaml \
            ${HELM_REPO_NAME}/openshift-gitops"
        
        debug_cmd "$helm_cmd | oc create -f -"
        "$HELM_BIN" template \
            --set 'helper-operator.enabled=true' \
            --set 'helper-status-checker.enabled=true' \
            --set 'gitopsinstances.openshift_gitops.clusterAdmin=disabled' \
            --verify \
            --force \
            -f values-openshift-gitops.yaml \
            "${HELM_REPO_NAME}/openshift-gitops" | oc create -f -

        wait_with_progress "$TIMER" "Waiting for operator installation"

        wait_for_resource crd/argocds.argoproj.io
        wait_for_resource "ns/${GITOPS_NAMESPACE}"
        wait_for_resource deployment/cluster "$GITOPS_NAMESPACE"
        wait_for_argocd_pods
        sleep "$RECHECK_TIMER"
        configure_argocd
    fi

    deploy_app_of_apps

    success "Argo CD for cluster configuration has been deployed. You can now use it to synchronize required configurations."
}

#######################################
# Main entry point
#######################################
main() {
    if [[ "$DEBUG" == "true" ]]; then
        printf "%b[DEBUG] Debug mode enabled%b\n" "${YELLOW}" "${NC}"
    fi
    
    print_config
    check_dependencies
    deploy
}

main "$@"

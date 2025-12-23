#!/bin/bash
#
# Generate GitOps Application Catalog JSON from GitHub
# 
# This script fetches Chart.yaml and config.json files directly from GitHub
# without requiring the repository to be cloned locally.
#
# Data priority:
#   1. Chart.yaml (name, description, version, keywords)
#   2. config.json (namespace, environment, category, icon, blogPost, etc.)
#
# Usage:
#   ./scripts/generate-catalog-from-github.sh > /path/to/blog/data/gitops_applications.json
#   ./scripts/generate-catalog-from-github.sh --check  # List folders and their status
#
# Environment variables:
#   GITHUB_TOKEN - Optional: GitHub token for higher API rate limits
#   GITHUB_REPO  - Optional: Override repo (default: tjungbauer/openshift-clusterconfig-gitops)
#   GITHUB_BRANCH - Optional: Override branch (default: main)
#

set -e

# Configuration
GITHUB_REPO="${GITHUB_REPO:-tjungbauer/openshift-clusterconfig-gitops}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
GITHUB_API="https://api.github.com"
GITHUB_RAW="https://raw.githubusercontent.com"

# Set up authentication header if token is provided
AUTH_HEADER=""
if [[ -n "$GITHUB_TOKEN" ]]; then
    AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
fi

# Temporary directory for caching
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Helper function to make GitHub API calls
github_api() {
    local endpoint="$1"
    if [[ -n "$AUTH_HEADER" ]]; then
        curl -s -H "$AUTH_HEADER" -H "Accept: application/vnd.github.v3+json" "${GITHUB_API}${endpoint}"
    else
        curl -s -H "Accept: application/vnd.github.v3+json" "${GITHUB_API}${endpoint}"
    fi
}

# Helper function to fetch raw file content
github_raw() {
    local path="$1"
    local url="${GITHUB_RAW}/${GITHUB_REPO}/${GITHUB_BRANCH}/${path}"
    curl -s -f "$url" 2>/dev/null || echo ""
}

# Parse YAML value (simple parser for single-line values)
parse_yaml_value() {
    local content="$1"
    local key="$2"
    echo "$content" | grep "^${key}:" | sed "s/^${key}:[[:space:]]*//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/" | head -1
}

# Parse YAML list (for keywords)
parse_yaml_list() {
    local content="$1"
    local key="$2"
    echo "$content" | awk "/^${key}:/{found=1; next} found && /^[[:space:]]*-/{gsub(/^[[:space:]]*-[[:space:]]*/, \"\"); print} found && /^[^[:space:]]/{exit}"
}

# Parse Helm dependencies from Chart.yaml
# Returns comma-separated list of dependency names (excluding helper-* and tpl)
parse_helm_dependencies() {
    local content="$1"
    local deps=""
    
    # Extract dependency names from the YAML dependencies section
    # Look for "- name: xxx" patterns after "dependencies:"
    local in_deps=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^dependencies: ]]; then
            in_deps=true
            continue
        fi
        if [[ "$in_deps" == true ]]; then
            # Exit if we hit a non-indented line (end of dependencies block)
            if [[ "$line" =~ ^[^[:space:]] && ! "$line" =~ ^$ ]]; then
                break
            fi
            # Extract dependency name
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                local dep_name="${BASH_REMATCH[1]}"
                # Trim whitespace and quotes
                dep_name=$(echo "$dep_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^["'"'"']//;s/["'"'"']$//')
                # Skip helper charts and tpl (these are utilities, not meaningful dependencies)
                if [[ ! "$dep_name" =~ ^helper- && "$dep_name" != "tpl" ]]; then
                    if [[ -n "$deps" ]]; then
                        deps="${deps},${dep_name}"
                    else
                        deps="$dep_name"
                    fi
                fi
            fi
        fi
    done <<< "$content"
    
    echo "$deps"
}

# Parse JSON value using jq if available, fallback to grep/sed
parse_json_value() {
    local content="$1"
    local key="$2"
    if command -v jq &> /dev/null; then
        echo "$content" | jq -r ".${key} // empty" 2>/dev/null
    else
        echo "$content" | grep "\"${key}\"" | sed 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1
    fi
}

# Parse JSON array as comma-separated string
parse_json_array() {
    local content="$1"
    local key="$2"
    if command -v jq &> /dev/null; then
        echo "$content" | jq -r ".${key} // [] | join(\",\")" 2>/dev/null
    else
        echo "$content" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\[[^]]*\]" | \
            sed 's/.*\[\(.*\)\].*/\1/' | sed 's/"//g' | tr -d ' '
    fi
}

# Category detection based on keywords or folder name
get_category() {
    local keywords="$1"
    local folder_name="$2"
    
    if echo "$keywords" | grep -qi "security\|compliance\|acs\|vulnerability\|certificate\|keycloak\|sso"; then
        echo "security"
    elif echo "$keywords" | grep -qi "observability\|monitoring\|logging\|loki\|tempo\|tracing\|grafana\|otel\|opentelemetry"; then
        echo "observability"
    elif echo "$keywords" | grep -qi "storage\|database\|odf\|ceph\|postgres\|quay\|registry"; then
        echo "storage"
    elif echo "$keywords" | grep -qi "acm\|multicluster\|multi-cluster"; then
        echo "multicluster"
    elif echo "$keywords" | grep -qi "development\|dev\|ide\|devspaces"; then
        echo "development"
    elif echo "$folder_name" | grep -qi "acs\|security\|compliance\|cert\|idp\|keycloak\|integrity"; then
        echo "security"
    elif echo "$folder_name" | grep -qi "logging\|loki\|tempo\|otel\|grafana\|observ\|monitor"; then
        echo "observability"
    elif echo "$folder_name" | grep -qi "storage\|odf\|postgres\|quay\|registry"; then
        echo "storage"
    elif echo "$folder_name" | grep -qi "acm\|multicluster"; then
        echo "multicluster"
    elif echo "$folder_name" | grep -qi "dev-spaces\|devspaces"; then
        echo "development"
    else
        echo "platform"
    fi
}

# Icon detection based on name and category
get_icon() {
    local name="$1"
    local category="$2"
    
    case "$name" in
        *acs*|*security*) echo "shield-virus" ;;
        *compliance*) echo "clipboard-check" ;;
        *cert*) echo "certificate" ;;
        *logging*) echo "file-alt" ;;
        *loki*) echo "scroll" ;;
        *tempo*) echo "stopwatch" ;;
        *otel*|*opentelemetry*) echo "satellite-dish" ;;
        *grafana*) echo "chart-bar" ;;
        *network*) echo "network-wired" ;;
        *observability*) echo "binoculars" ;;
        *odf*|*storage*) echo "hdd" ;;
        *postgres*|*database*) echo "database" ;;
        *quay*|*registry*) echo "cube" ;;
        *acm*) echo "project-diagram" ;;
        *keycloak*) echo "key" ;;
        *dev*space*) echo "laptop-code" ;;
        *cyclonedx*|*sbom*) echo "list-check" ;;
        *signer*|*artifact*) echo "signature" ;;
        *branding*) echo "paint-brush" ;;
        *apiserver*|*etcd*) echo "server" ;;
        *backup*) echo "save" ;;
        *ingress*) echo "door-open" ;;
        *config*) echo "sliders-h" ;;
        *node*) echo "sitemap" ;;
        *version*|*update*) echo "sync-alt" ;;
        *gitops*) echo "code-branch" ;;
        *project*|*onboarding*) echo "folder-plus" ;;
        *operator*) echo "puzzle-piece" ;;
        *cost*) echo "dollar-sign" ;;
        *wave*|*policy*) echo "wave-square" ;;
        *)
            case "$category" in
                security) echo "shield-alt" ;;
                observability) echo "chart-line" ;;
                storage) echo "database" ;;
                multicluster) echo "globe" ;;
                development) echo "code" ;;
                *) echo "cogs" ;;
            esac
            ;;
    esac
}

# Get list of application directories from GitHub
get_app_directories() {
    local cluster_path="$1"
    
    # Get directory listing from GitHub API
    local response=$(github_api "/repos/${GITHUB_REPO}/contents/${cluster_path}?ref=${GITHUB_BRANCH}")
    
    # Extract directory names (filter out non-directories and skip templates/charts/etc)
    echo "$response" | jq -r '.[] | select(.type == "dir") | select(.name != "charts" and .name != "templates" and .name != "Archive" and .name != "waves") | .path'
}

# Check mode
if [[ "$1" == "--check" ]]; then
    echo "=== Fetching application list from GitHub ==="
    echo "Repository: ${GITHUB_REPO}"
    echo "Branch: ${GITHUB_BRANCH}"
    echo ""
    
    for cluster_type in "clusters/all" "clusters/management-cluster"; do
        echo "--- ${cluster_type} ---"
        dirs=$(get_app_directories "$cluster_type")
        
        for dir in $dirs; do
            folder_name=$(basename "$dir")
            chart_yaml=$(github_raw "${dir}/Chart.yaml")
            config_json=$(github_raw "${dir}/config.json")
            
            has_chart="❌"
            has_config="❌"
            [[ -n "$chart_yaml" ]] && has_chart="✅"
            [[ -n "$config_json" ]] && has_config="✅"
            
            echo "  $folder_name  Chart.yaml: $has_chart  config.json: $has_config"
        done
        echo ""
    done
    exit 0
fi

# Main JSON generation
echo "{"
echo "  \"lastUpdated\": \"$(date +%Y-%m-%d)\","
echo "  \"repository\": \"https://github.com/${GITHUB_REPO}\","
echo "  \"categories\": {"
echo "    \"security\": { \"name\": \"Security & Compliance\", \"icon\": \"shield-alt\", \"color\": \"#dc3545\" },"
echo "    \"observability\": { \"name\": \"Observability & Monitoring\", \"icon\": \"chart-line\", \"color\": \"#17a2b8\" },"
echo "    \"storage\": { \"name\": \"Storage & Data\", \"icon\": \"database\", \"color\": \"#28a745\" },"
echo "    \"platform\": { \"name\": \"Platform Configuration\", \"icon\": \"cogs\", \"color\": \"#6f42c1\" },"
echo "    \"development\": { \"name\": \"Development Tools\", \"icon\": \"code\", \"color\": \"#fd7e14\" },"
echo "    \"multicluster\": { \"name\": \"Multi-Cluster Management\", \"icon\": \"project-diagram\", \"color\": \"#20c997\" }"
echo "  },"
echo "  \"applications\": ["

first=true

# Process both cluster directories
for cluster_type in "clusters/all" "clusters/management-cluster"; do
    dirs=$(get_app_directories "$cluster_type")
    
    for dir in $dirs; do
        folder_name=$(basename "$dir")
        
        # Fetch files from GitHub
        chart_yaml=$(github_raw "${dir}/Chart.yaml")
        config_json=$(github_raw "${dir}/config.json")
        
        # Skip if neither file exists
        if [[ -z "$chart_yaml" && -z "$config_json" ]]; then
            continue
        fi
        
        # Initialize variables
        name=""
        description=""
        version="1.0.0"
        namespace="default"
        keywords=""
        category=""
        icon=""
        blog_post=""
        helm_dependencies=""
        app_dependencies=""
        
        # Parse Chart.yaml (priority)
        if [[ -n "$chart_yaml" ]]; then
            chart_name=$(parse_yaml_value "$chart_yaml" "name")
            chart_desc=$(parse_yaml_value "$chart_yaml" "description")
            chart_version=$(parse_yaml_value "$chart_yaml" "version")
            chart_keywords=$(parse_yaml_list "$chart_yaml" "keywords" | tr '\n' ',' | sed 's/,$//')
            
            # Auto-detect Helm chart dependencies (excluding helpers and tpl)
            chart_helm_deps=$(parse_helm_dependencies "$chart_yaml")
            
            [[ -n "$chart_name" ]] && name="$chart_name"
            [[ -n "$chart_desc" ]] && description="$chart_desc"
            [[ -n "$chart_version" ]] && version="$chart_version"
            [[ -n "$chart_keywords" ]] && keywords="$chart_keywords"
            [[ -n "$chart_helm_deps" ]] && helm_dependencies="$chart_helm_deps"
        fi
        
        # Parse config.json (fallback/supplement - config.json values take priority for dependencies)
        if [[ -n "$config_json" ]]; then
            config_name=$(parse_json_value "$config_json" "name")
            config_desc=$(parse_json_value "$config_json" "description")
            config_version=$(parse_json_value "$config_json" "version")
            config_namespace=$(parse_json_value "$config_json" "namespace")
            config_category=$(parse_json_value "$config_json" "category")
            config_icon=$(parse_json_value "$config_json" "icon")
            config_blog=$(parse_json_value "$config_json" "blogPost")
            config_keywords=$(parse_json_array "$config_json" "keywords")
            
            # Manual dependency overrides from config.json (these take priority)
            config_helm_deps=$(parse_json_array "$config_json" "helmDependencies")
            config_app_deps=$(parse_json_array "$config_json" "appDependencies")
            
            [[ -z "$name" && -n "$config_name" ]] && name="$config_name"
            [[ -z "$description" && -n "$config_desc" ]] && description="$config_desc"
            [[ -n "$config_version" ]] && version="$config_version"
            [[ -n "$config_namespace" ]] && namespace="$config_namespace"
            [[ -n "$config_category" ]] && category="$config_category"
            [[ -n "$config_icon" ]] && icon="$config_icon"
            [[ -n "$config_blog" ]] && blog_post="$config_blog"
            [[ -z "$keywords" && -n "$config_keywords" ]] && keywords="$config_keywords"
            
            # config.json helmDependencies override auto-detected ones
            [[ -n "$config_helm_deps" ]] && helm_dependencies="$config_helm_deps"
            # appDependencies are always from config.json (can't be auto-detected)
            [[ -n "$config_app_deps" ]] && app_dependencies="$config_app_deps"
        fi
        
        # Generate defaults if not found
        if [[ -z "$name" ]]; then
            name=$(echo "$folder_name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
        fi
        
        if [[ -z "$description" ]]; then
            description="Configuration for $name"
        fi
        
        if [[ -z "$category" ]]; then
            category=$(get_category "$keywords" "$folder_name")
        fi
        
        if [[ -z "$icon" ]]; then
            icon=$(get_icon "$folder_name" "$category")
        fi
        
        # Escape special characters
        description=$(echo "$description" | sed 's/"/\\"/g' | tr -d '\n')
        name=$(echo "$name" | sed 's/"/\\"/g')
        
        # Format keywords as JSON array
        if [[ -n "$keywords" ]]; then
            keywords_json=$(echo "$keywords" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/.*/\"&\"/' | tr '\n' ',' | sed 's/,$//')
            keywords_array="[$keywords_json]"
        else
            keywords_array="[]"
        fi
        
        # Format dependencies as JSON arrays
        if [[ -n "$helm_dependencies" ]]; then
            helm_deps_json=$(echo "$helm_dependencies" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/.*/\"&\"/' | tr '\n' ',' | sed 's/,$//')
            helm_deps_array="[$helm_deps_json]"
        else
            helm_deps_array="[]"
        fi
        
        if [[ -n "$app_dependencies" ]]; then
            app_deps_json=$(echo "$app_dependencies" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/.*/\"&\"/' | tr '\n' ',' | sed 's/,$//')
            app_deps_array="[$app_deps_json]"
        else
            app_deps_array="[]"
        fi
        
        # Output JSON
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        
        echo -n "    {"
        echo -n "\"id\": \"$folder_name\", "
        echo -n "\"name\": \"$name\", "
        echo -n "\"path\": \"$dir\", "
        echo -n "\"description\": \"$description\", "
        echo -n "\"namespace\": \"$namespace\", "
        echo -n "\"category\": \"$category\", "
        echo -n "\"icon\": \"$icon\", "
        echo -n "\"version\": \"$version\""
        
        if [[ -n "$blog_post" ]]; then
            echo -n ", \"blogPost\": \"$blog_post\""
        fi
        
        echo -n ", \"keywords\": $keywords_array"
        
        # Add dependencies if present
        if [[ "$helm_deps_array" != "[]" ]]; then
            echo -n ", \"helmDependencies\": $helm_deps_array"
        fi
        
        if [[ "$app_deps_array" != "[]" ]]; then
            echo -n ", \"appDependencies\": $app_deps_array"
        fi
        
        echo -n "}"
    done
done

echo ""
echo "  ]"
echo "}"


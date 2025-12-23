#!/bin/bash
#
# Generate GitOps Application Catalog JSON
# 
# This script scans the clusters/ directory and generates a JSON file
# containing metadata for all ArgoCD applications.
#
# Data priority:
#   1. Chart.yaml (name, description, version, keywords)
#   2. config.json (namespace, environment, category, icon, blogPost, etc.)
#
# Usage:
#   ./scripts/generate-catalog-json.sh > /path/to/blog/data/gitops_applications.json
#   ./scripts/generate-catalog-json.sh --check  # List folders missing required data
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLUSTERS_DIR="$REPO_ROOT/clusters"

# Category mapping based on keywords or folder name patterns
get_category() {
    local keywords="$1"
    local folder_name="$2"
    local description="$3"
    
    # Check keywords first
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
    # Check folder name patterns
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

# Get icon based on category and name
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

# Parse YAML value (simple parser for single-line values)
parse_yaml_value() {
    local file="$1"
    local key="$2"
    grep "^${key}:" "$file" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
}

# Parse YAML list (for keywords)
parse_yaml_list() {
    local file="$1"
    local key="$2"
    awk "/^${key}:/{found=1; next} found && /^[[:space:]]*-/{gsub(/^[[:space:]]*-[[:space:]]*/, \"\"); print} found && /^[^[:space:]]/{exit}" "$file" 2>/dev/null
}

# Parse Helm dependencies from Chart.yaml
# Returns comma-separated list of dependency names (excluding helper-* and tpl)
parse_helm_dependencies() {
    local file="$1"
    local deps=""
    
    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi
    
    # Extract dependency names from the YAML dependencies section
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
    done < "$file"
    
    echo "$deps"
}

# Parse JSON value (string)
parse_json_value() {
    local file="$1"
    local key="$2"
    if command -v jq &> /dev/null; then
        jq -r ".${key} // empty" "$file" 2>/dev/null
    else
        grep "\"${key}\"" "$file" 2>/dev/null | sed 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
    fi
}

# Parse JSON array as comma-separated string
parse_json_array() {
    local file="$1"
    local key="$2"
    if command -v jq &> /dev/null; then
        jq -r ".${key} // [] | join(\",\")" "$file" 2>/dev/null
    else
        # Fallback: extract array items manually
        grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\[[^]]*\]" "$file" 2>/dev/null | \
            sed 's/.*\[\(.*\)\].*/\1/' | \
            sed 's/"//g' | \
            tr -d ' '
    fi
}

# Check mode - list folders with missing data
if [[ "$1" == "--check" ]]; then
    echo "=== Folders WITHOUT Chart.yaml (need enhanced config.json) ==="
    echo ""
    
    find "$CLUSTERS_DIR" -mindepth 2 -maxdepth 3 -type d | while read -r dir; do
        # Skip subdirectories like charts/, templates/, Archive/
        basename_dir=$(basename "$dir")
        if [[ "$basename_dir" == "charts" || "$basename_dir" == "templates" || "$basename_dir" == "Archive" ]]; then
            continue
        fi
        
        # Check if it's an application folder (has config.json or Chart.yaml)
        if [[ ! -f "$dir/config.json" && ! -f "$dir/Chart.yaml" ]]; then
            continue
        fi
        
        if [[ ! -f "$dir/Chart.yaml" ]]; then
            rel_path="${dir#$REPO_ROOT/}"
            echo "📁 $rel_path"
            
            if [[ -f "$dir/config.json" ]]; then
                echo "   Current config.json:"
                cat "$dir/config.json" | sed 's/^/   /'
            fi
            
            echo "   Missing fields needed:"
            echo "   - name: \"<Application Name>\""
            echo "   - description: \"<What this application does>\""
            echo "   - version: \"1.0.0\""
            echo "   - category: \"platform|security|observability|storage|development|multicluster\""
            echo "   - keywords: [\"keyword1\", \"keyword2\"]"
            echo ""
        fi
    done
    
    echo ""
    echo "=== Recommended config.json format ==="
    cat << 'EOF'
{
  "name": "Application Display Name",
  "description": "What this application configures or deploys",
  "version": "1.0.0",
  "namespace": "target-namespace",
  "environment": "in-cluster",
  "category": "platform",
  "keywords": ["keyword1", "keyword2"],
  "icon": "cogs",
  "blogPost": "/gitopscollection/2024-xx-xx-article-slug/",
  "appDependencies": ["setup-acm", "setup-openshift-data-foundation"],
  "helmDependencies": ["openshift-logging", "helper-lokistack"]
}

Notes:
- helmDependencies: Overrides auto-detected Helm chart deps from Chart.yaml
  (helper-* and tpl are automatically excluded from auto-detection)
- appDependencies: Other GitOps applications that should be deployed first
  (these cannot be auto-detected, must be specified manually)
EOF
    exit 0
fi

# Main JSON generation
echo "{"
echo "  \"lastUpdated\": \"$(date +%Y-%m-%d)\","
echo "  \"repository\": \"https://github.com/tjungbauer/openshift-clusterconfig-gitops\","
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

find "$CLUSTERS_DIR" -mindepth 2 -maxdepth 3 -type d | sort | while read -r dir; do
    # Skip subdirectories like charts/, templates/, Archive/
    basename_dir=$(basename "$dir")
    if [[ "$basename_dir" == "charts" || "$basename_dir" == "templates" || "$basename_dir" == "Archive" || "$basename_dir" == "waves" ]]; then
        continue
    fi
    
    # Check if it's an application folder
    if [[ ! -f "$dir/config.json" && ! -f "$dir/Chart.yaml" ]]; then
        continue
    fi
    
    rel_path="${dir#$REPO_ROOT/}"
    folder_name=$(basename "$dir")
    
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
    
    # Try to get data from Chart.yaml first (priority)
    if [[ -f "$dir/Chart.yaml" ]]; then
        chart_name=$(parse_yaml_value "$dir/Chart.yaml" "name")
        chart_desc=$(parse_yaml_value "$dir/Chart.yaml" "description")
        chart_version=$(parse_yaml_value "$dir/Chart.yaml" "version")
        chart_keywords=$(parse_yaml_list "$dir/Chart.yaml" "keywords" | tr '\n' ',' | sed 's/,$//')
        
        # Auto-detect Helm chart dependencies (excluding helpers and tpl)
        chart_helm_deps=$(parse_helm_dependencies "$dir/Chart.yaml")
        
        [[ -n "$chart_name" ]] && name="$chart_name"
        [[ -n "$chart_desc" ]] && description="$chart_desc"
        [[ -n "$chart_version" ]] && version="$chart_version"
        [[ -n "$chart_keywords" ]] && keywords="$chart_keywords"
        [[ -n "$chart_helm_deps" ]] && helm_dependencies="$chart_helm_deps"
    fi
    
    # Get/override data from config.json (config.json values take priority for dependencies)
    if [[ -f "$dir/config.json" ]]; then
        config_name=$(parse_json_value "$dir/config.json" "name")
        config_desc=$(parse_json_value "$dir/config.json" "description")
        config_version=$(parse_json_value "$dir/config.json" "version")
        config_namespace=$(parse_json_value "$dir/config.json" "namespace")
        config_category=$(parse_json_value "$dir/config.json" "category")
        config_icon=$(parse_json_value "$dir/config.json" "icon")
        config_blog=$(parse_json_value "$dir/config.json" "blogPost")
        config_keywords=$(parse_json_array "$dir/config.json" "keywords")
        
        # Manual dependency overrides from config.json (these take priority)
        config_helm_deps=$(parse_json_array "$dir/config.json" "helmDependencies")
        config_app_deps=$(parse_json_array "$dir/config.json" "appDependencies")
        
        # Only use config.json values if Chart.yaml didn't provide them
        [[ -z "$name" && -n "$config_name" ]] && name="$config_name"
        [[ -z "$description" && -n "$config_desc" ]] && description="$config_desc"
        [[ -n "$config_version" ]] && version="$config_version"  # config.json can override version
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
    
    # Generate name from folder if not found
    if [[ -z "$name" ]]; then
        # Convert folder-name to Title Case
        name=$(echo "$folder_name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    fi
    
    # Generate description if not found
    if [[ -z "$description" ]]; then
        description="Configuration for $name"
    fi
    
    # Auto-detect category if not set
    if [[ -z "$category" ]]; then
        category=$(get_category "$keywords" "$folder_name" "$description")
    fi
    
    # Auto-detect icon if not set
    if [[ -z "$icon" ]]; then
        icon=$(get_icon "$folder_name" "$category")
    fi
    
    # Escape special characters for JSON
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
    
    # Output JSON (handle first item without comma)
    if [[ "$first" == "true" ]]; then
        first=false
    else
        echo ","
    fi
    
    echo -n "    {"
    echo -n "\"id\": \"$folder_name\", "
    echo -n "\"name\": \"$name\", "
    echo -n "\"path\": \"$rel_path\", "
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

echo ""
echo "  ]"
echo "}"


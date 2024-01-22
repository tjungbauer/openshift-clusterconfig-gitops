cat users.htpasswd | oc create secret generic htpasswd-secret  --dry-run=client --from-file=htpasswd=/dev/stdin -o yaml -n openshift-config \
| kubeseal --controller-namespace=sealed-secrets --controller-name=sealed-secrets --format yaml > ../../clusters/all/clusterconfig/templates/htpasswd-sealed-secret.yaml

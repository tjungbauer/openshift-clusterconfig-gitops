cat providers.html | oc create secret generic matrix-provider-template  --dry-run=client --from-file=providers.html=/dev/stdin -o yaml -n openshift-config \
| kubeseal --controller-namespace=sealed-secrets --controller-name=sealed-secrets --format yaml > ../../clusters/all/clusterbranding/templates/idp-provider-page-sealed-secret.yaml

cat login.html | oc create secret generic matrix-login-template  --dry-run=client --from-file=login.html=/dev/stdin -o yaml -n openshift-config \
| kubeseal --controller-namespace=sealed-secrets --controller-name=sealed-secrets --format yaml > ../../clusters/all/clusterbranding/templates/login-page-sealed-secret.yaml

echo -n 'LDAPbindPassword-HERE' | oc create secret generic ldap-secret --dry-run=client --from-file=bindPassword=/dev/stdin -o yaml -n openshift-config \
| kubeseal --controller-namespace=sealed-secrets --controller-name=sealed-secrets --format yaml > ../../clusters/all/clusterconfig/templates/sealed-ldap-bindpassword-secret.yaml

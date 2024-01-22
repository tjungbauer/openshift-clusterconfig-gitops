#!/bin/bash
echo -n 'PASSWORD-HERE' | oc create secret generic credentials --dry-run=client --from-file=adminpass=/dev/stdin -o yaml -n sonarqube \
| kubeseal --controller-namespace=sealed-secrets --controller-name=sealed-secrets --format yaml > ../../clusters/management-cluster/sonarqube/templates/sealed-sonarqube-password.yaml

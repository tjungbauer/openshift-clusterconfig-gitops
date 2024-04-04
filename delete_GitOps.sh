#!/bin/bash
#set -euf -o pipefail
oc delete Application.argoproj.io -n openshift-gitops --all
oc delete Applicationset.argoproj.io -n openshift-gitops --all 
oc delete Application.argoproj.io -n openshift-gitops --all
sleep 5
oc delete Appproject -A --all
oc delete subscription openshift-gitops-operator -n openshift-gitops-operator
oc delete operatorgroup openshift-gitops-operator -n openshift-gitops-operator
for i in `oc get crd | grep argoproj.io | awk -F" " '{print $1}'`; do oc delete crd $i; done

oc delete project openshift-gitops 
oc delete project openshift-gitops-operator

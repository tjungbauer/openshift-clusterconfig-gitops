
![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

# Overview

This "wrapper" Helm Chart is used to deploy Advanced Cluster Security (ACS) using a GitOps approach. 
It calls the Chart [rhacs-setup](https://artifacthub.io/packages/helm/openshift-bootstraps/rhacs-setup) which mainly takes care to

- Deploy the Operator and verify if the Operators installation was successful
- Deploy Central if required
- Deploy Secured Cluster
- Add a console link in the action menu of OpenShift

The values.yaml provides an example of possible settings.

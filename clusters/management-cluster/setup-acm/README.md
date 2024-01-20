
![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

# Overview

This "wrapper" Helm Chart is used to deploy Advanced Cluster Management (ACM) using a GitOps approach. 
It calls the Chart [rhacm-setup](https://artifacthub.io/packages/helm/openshift-bootstraps/rhacm-setup) which mainly takes care to

- Deploy the Operator and verify if the Operator installation was successful
- Deploy ACM

The values.yaml provides an example of possible settings.

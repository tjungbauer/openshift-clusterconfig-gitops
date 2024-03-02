# argocd-resources-manager

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Linting](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml/badge.svg)](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml)
[![Release Charts](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml)

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)

## Description

The Argo CD resources manager is used as App-of-Apps for cluster configuration following the GitOps approach. In this folder a single values-file is stored only, while the actual Helm chart that is used is https://github.com/tjungbauer/helm-charts/tree/main/charts/helper-argocd 
**helper-argocd** is used to render Applications, ApplicationSets and AppProjects. 

Verify the local values.yaml or the README.md at https://github.com/tjungbauer/helm-charts/tree/main/charts/helper-argocd for further information.

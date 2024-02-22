

# init_app_of_apps

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Linting](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml/badge.svg)](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml)
[![Release Charts](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml)

  ![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)

 

  ## Description

  Installs a single application into Argo CD, which automatically syncs all other applications and ApplicationSets.

`init_app_of_apps` is a Helm chart for initializing applications in an OpenShift cluster using GitOps principles.
It serves as the first Argo CD Application to be installed, acting as an **App-of-Apps** by verifying the
configured **path** which defines all further Applications and ApplicationSets for **cluster configuration**.
In other words, this App-of-Apps creates an Applicaton called **argocd-resources-manager** and this resources-manager renders all further Applications and ApplicationSets.

If you use the shell script of this repository, it will be installed as the final step of that script, so you can immediately start with your cluster configuration.

## Prerequisites
Ensure the following prerequisites are met before deploying this Helm chart:

* OpenShift cluster is up and running.
* Git repository with application configurations.

## Installation
Either run the shell script **./init_GitOps.sh** that will install the OpenShift GitOps Operator and automatically installs this init_app_of_apps, or manually use Helm.

```bash
helm upgrade --install --values ./base/init_app_of_apps/values.yaml --namespace=openshift-gitops app-of-apps ./base/init_app_of_apps
```

## Parameters
The following table lists the configurable parameters of the init_app_of_apps chart and their default values.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| argocd_project | string | `"default"` | The argocd_project parameter specifies the ArgoCD project to use. This indicates that the applications will be managed within the 'default' ArgoCD project. |
| chart_name | string | `"helper-argocd"` | Specifies the name of the Helm chart. This chart will be used by the argocd-resources-manager to render all objects. |
| chart_version | string | `"2.0.x"` | Specifies the version of the Helm chart to be deployed. This chart will be used by the argocd-resources-manager to render all objects. |
| path_configurations | list | `["base/argocd-resources-manager/values.yaml"]` | The path_configurations parameter specifies the path within the Git repository where the configuration files are located. Here the values-file is stored only. This values-files is used by the App-of-Apps to define all Applications and ApplicationSets. |
| repoURL_chart | string | `"https://charts.stderr.at/"` | he repoURL_chart parameter specifies the Helm chart repository URL. |
| repourl_configuration | string | `"https://github.com/tjungbauer/openshift-clusterconfig-gitops"` | The repourl_configuration parameter specifies the URL of the Git repository containing cluster configurations. |
| revision_configuration | string | `"main"` | The revision_configuration parameter specifies the revision or branch of the Git repository to use. |
| server | string | `"https://kubernetes.default.svc"` | The server parameter specifies the Kubernetes server URL to be used. The server parameter specifies the Kubernetes server URL to be used. |

## Example
Above configuration will create the following Application object:

```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-resources-manager
  labels:
    gitops.ownedBy: cluster-config
    app.kubernetes.io/instance: app-of-apps
    app.kubernetes.io/managed-by: Helm
spec:
  destination:
    namespace: openshift-gitops
    server: https://kubernetes.default.svc
  project: default
  sources:
    - repoURL: https://github.com/tjungbauer/openshift-clusterconfig-gitops
      targetRevision: main
      ref: values
    - repoURL: https://charts.stderr.at/
      chart: helper-argocd
      targetRevision: 2.0.x
      helm:
        valueFiles:
          - $values/base/argocd-resources-manager/values.yaml
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  info:
    - name: Description
      value: 'This is the starting point which will initialize all applicationsets or argocd applications'
```

This Application will observe https://github.com/tjungbauer/openshift-clusterconfig-gitops for any changes.

**NOTE**: In this example multiple **Sources** are defined. A feature that is currently TechPreview ([22nd February 2024](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)).
This feature help to define the values-file of a Helm chart outside the actual Helm Chart (and thus you can put your values-file into a separate repository).
If you do not want to use TechPreview feature create a "wrapper helm chart", put the values-file into it and add a dependency
the **helper-argocd** Subchart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tjungbauer | <tjungbau@redhat.com> | <https://blog.stderr.at/> |

## Sources
Source:
* <https://github.com/tjungbauer/openshift-clusterconfig-gitops>

Source code: https://github.com/tjungbauer/openshift-clusterconfig-gitops/tree/main/base/init_app_of_apps

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)

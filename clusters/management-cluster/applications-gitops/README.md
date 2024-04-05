

# GitOps instance for Application workload

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Linting](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml/badge.svg)](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml)
 

  ## Description

The default instance of Argo CD (openshift gitops operator) has more permissions than you usually want to have. Too many privileges than you want to give developers for workload onboarding. 
Therefore, a 2nd  (or even more) Argo CD instance can be deployed. This Helm chart will help you configure this instance.

## Dependencies

This chart has the following dependencies:

| Repository | Name | Version |
|------------|------|---------|
| https://charts.stderr.at/ | openshift-gitops | ~1.0.5 |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tjungbauer | <tjungbau@redhat.com> | <https://blog.stderr.at/> |

## Sources
Source:
* <https://github.com/tjungbauer/helm-charts>
* <https://charts.stderr.at/>
* <https://github.com/tjungbauer/openshift-clusterconfig-gitops>

Source code: https://github.com/tjungbauer/helm-charts/tree/main/charts/openshift-gitops

## Parameters

Verify the sub-charts for a documentation of the possible settings:

* [openshift-gitops](https://github.com/tjungbauer/helm-charts/tree/main/charts/openshift-gitops)

## Example

```yaml
---
hostname: &hostname gitops.apps.prod.ocp.cluster

openshift-gitops:
  gitopsinstances:
    gitops_application:
      enabled: true
      namespace: gitops-application
      clusterAdmin: disabled

      server:
        # host: *hostname
        route:
          enabled: true

      generic_config:
        disableAdmin: true
        resourceTrackingMethod: annotation
        kustomizeBuildOptions: "--enable-helm"

      controller: {}
      ha: {}
      redis: {}
      repo: {}
      appset: {}
      sso:
        dex:
          openShiftOAuth: true

      rbac:
        defaultRole: 'role:none'

        policy: |-
            # Access Control
            g, system:cluster-admins, role:admin
            g, cluster-admin, role:admin
            p, role:none, applications, get, */*, deny
            p, role:none, certificates, get, *, deny
            p, role:none, clusters, get, *, deny
            p, role:none, repositories, get, *, deny
            p, role:none, projects, get, *, deny
            p, role:none, accounts, get, *, deny
            p, role:none, gpgkeys, get, *, deny
        scopes: '[groups]'

      resourceExclusions: |-
        # resources to be excluded
        - apiGroups:
          - tekton.dev
          clusters:
          - '*'
          kinds:
          - TaskRun
          - PipelineRun

      # This will create some default health checks I usually add.
      # * ClusterLogging, * Application (Argo CD), * Lokistack, * Subcription, * Central (ACS), InstallPlan
      # @default -- false
      default_resourceHealthChecks: true
```

This will create a 2nd Argo CD instance in the namespace "gitops-application" 


# sonarqube

  [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/openshift-bootstraps)](https://artifacthub.io/packages/search?repo=openshift-bootstraps)
  [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
  [![Lint and Test Charts](https://github.com/tjungbauer/helm-charts/actions/workflows/lint_and_test_charts.yml/badge.svg)](https://github.com/tjungbauer/helm-charts/actions/workflows/lint_and_test_charts.yml)
  [![Release Charts](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml)

  ![Version: 1.0.9](https://img.shields.io/badge/Version-1.0.9-informational?style=flat-square)

 

  ## Description

  A Helm chart to deploy sonarqube community edition -d epends on Sonarcube's helm chart

SonarQube is a solution that allows (source) code analysis and quality checks. The community version installed here is part of the Secure Supply Chain example.

When Sonarqube is installed the initial password for the admin user will be "admin".

This wrapper Helm chart is able to start a Job that can set (change) the initial password.
The job will connect to the Sonarqube endpoint and will use the credentials that are defined in a Secret. The Secret must have the key "adminpass" that will be used as a password.
In this repository a SealedSecret object has been used for that.

To do so a sealed secret is used that was created like this:

```bash
echo -n 'PASSWORD-HERE' | oc create secret generic credentials --dry-run=client --from-file=adminpass=/dev/stdin -o yaml -n sonarqube \
| kubeseal --controller-namespace=sealed-secrets --controller-name=sealed-secrets --format yaml
```

For detailed information check: [SonarQube](https://www.sonarsource.com/products/sonarqube/)

For an example on how to use it during a pipeline run check: [Analyse Source Code](https://blog.stderr.at/securesupplychain/2023-06-18-securesupplychain-step3/)

## Dependencies

This chart has the following dependencies:

| Repository | Name | Version |
|------------|------|---------|
| https://SonarSource.github.io/helm-chart-sonarqube | sonarqube | ~10.1.0 |

It is best used with a full GitOps approach such as Argo CD does. For example, https://github.com/tjungbauer/openshift-clusterconfig-gitops

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tjungbauer | <tjungbau@redhat.com> | <https://blog.stderr.at/> |

## Sources
Source:
* <https://github.com/tjungbauer/helm-charts>
* <https://charts.stderr.at/>
* <https://github.com/tjungbauer/openshift-clusterconfig-gitops>

Source code: https://github.com/tjungbauer/helm-charts/tree/main/charts/sonarqube

## Parameters

Verify the subcharts for additional settings:

* [helper-operator](https://github.com/tjungbauer/helm-charts/tree/main/charts/helper-operator)
* [helper-status-checker](https://github.com/tjungbauer/helm-charts/tree/main/charts/helper-operator)

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| endpoint | string | `"sonarqube.apps.ocp.aws.ispworld.at"` | Endpoint so that the Job that is configuring the initial password can connect. |
| ep | string | `"sonarqube.apps.ocp.aws.ispworld.at"` |  |
| namespace.create | bool | false | Shall the namespace be created? |
| namespace.name | string | `"sonarqube"` | Namespace where Sonarqube shall be deployed |
| set_admin_password | bool | false | Start a Job to set an initial password |
| sonarqube | object | `{"OpenShift":{"createSCC":true,"enabled":true},"ingress":{"enabled":true,"hosts":[{"name":"sonarqube.apps.ocp.aws.ispworld.at","path":"/"}]},"networkPolicy":{"enabled":false},"persistence":{"enabled":true},"plugins":{"install":["https://github.com/checkstyle/sonar-checkstyle/releases/download/10.9.3/checkstyle-sonar-plugin-10.9.3.jar","https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/3.1.0/sonar-dependency-check-plugin-3.1.0.jar","https://github.com/sbaudoin/sonar-yaml/releases/download/v1.7.0/sonar-yaml-plugin-1.7.0.jar","https://github.com/sbaudoin/sonar-shellcheck/releases/download/v2.5.0/sonar-shellcheck-plugin-2.5.0.jar"]}}` | Sonarqube Settings These settings are defined by Sonarqube Helm chart. |
| sonarqube.OpenShift.createSCC | bool | `true` | The SCC should be created for OpenShift deployment. |
| sonarqube.OpenShift.enabled | bool | `true` | OpenShift should be enabled |
| sonarqube.ingress | object | `{"enabled":true,"hosts":[{"name":"sonarqube.apps.ocp.aws.ispworld.at","path":"/"}]}` | Enable ingress, using the defind endpoint. |
| sonarqube.networkPolicy | object | `{"enabled":false}` | Enable Network Polocies ... maybe I should set this to true |
| sonarqube.persistence | object | `{"enabled":true}` | Keep the data persistent |
| sonarqube.plugins | object | `{"install":["https://github.com/checkstyle/sonar-checkstyle/releases/download/10.9.3/checkstyle-sonar-plugin-10.9.3.jar","https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/3.1.0/sonar-dependency-check-plugin-3.1.0.jar","https://github.com/sbaudoin/sonar-yaml/releases/download/v1.7.0/sonar-yaml-plugin-1.7.0.jar","https://github.com/sbaudoin/sonar-shellcheck/releases/download/v2.5.0/sonar-shellcheck-plugin-2.5.0.jar"]}` | additional plugins to install |

## Example #1 - MultiCloudGateway only

```yaml
---
ep: &endpoint sonarqube.apps.ocp.aws.ispworld.at

namespace:
  name: sonarqube
  create: true

set_admin_password: true
endpoint: *endpoint

# Sonarqube Settings
# These settings are defined by Sonarqube Helm chart.
sonarqube:
  OpenShift:
    enabled: true
    createSCC: true
  persistence:
    enabled: true
  networkPolicy:
    enabled: false

  ingress:
    enabled: true
    hosts:
      - name: *endpoint
        path: /
  plugins:
    install:
      - https://github.com/checkstyle/sonar-checkstyle/releases/download/10.9.3/checkstyle-sonar-plugin-10.9.3.jar
      - https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/3.1.0/sonar-dependency-check-plugin-3.1.0.jar
      - https://github.com/sbaudoin/sonar-yaml/releases/download/v1.7.0/sonar-yaml-plugin-1.7.0.jar
      - https://github.com/sbaudoin/sonar-shellcheck/releases/download/v2.5.0/sonar-shellcheck-plugin-2.5.0.jar
```

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release tjungbauer/<chart-name>>
```

The command deploys the chart on the Kubernetes cluster in the default configuration.

## Uninstalling the Chart

To uninstall/delete the my-release deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)

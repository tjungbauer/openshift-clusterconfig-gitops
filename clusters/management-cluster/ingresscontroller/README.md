# ingresscontroller

  ## Description

  Configures the IngressController object.

This Helm Chart is configuring the IngressController and can set a replica, nodeSelector and tolerations.

## Dependencies

This chart has the following dependencies:

| Repository | Name | Version |
|------------|------|---------|

It is best used with a full GitOps approach such as Argo CD does. For example, https://github.com/tjungbauer/openshift-clusterconfig-gitops (see folder cluster/management-cluster/ingresscontroller)

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tjungbauer | <tjungbau@redhat.com> | <https://blog.stderr.at/> |

## Sources
Source:
* <https://github.com/tjungbauer/helm-charts>
* <https://charts.stderr.at/>
* <https://github.com/tjungbauer/openshift-clusterconfig-gitops>

Source code: https://github.com/tjungbauer/helm-charts/tree/main/charts/generic-cluster-config

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingresscontrollers | list | `[{"enabled":true,"name":"default","nodePlacement":{"nodeSelector":{"key":"node-role.kubernetes.io/infra","value":""},"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/infra","operator":"Equal","value":"reserved"},{"effect":"NoExecute","key":"node-role.kubernetes.io/infra","operator":"Equal","value":"reserved"}]},"replicas":3}]` | Define ingressControllers Multiple might be defined. |
| ingresscontrollers[0] | object | `{"enabled":true,"name":"default","nodePlacement":{"nodeSelector":{"key":"node-role.kubernetes.io/infra","value":""},"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/infra","operator":"Equal","value":"reserved"},{"effect":"NoExecute","key":"node-role.kubernetes.io/infra","operator":"Equal","value":"reserved"}]},"replicas":3}` | Name of the IngressController. OpenShift initial IngressController is called 'default'. |
| ingresscontrollers[0].enabled | bool | false | Enable the configuration |
| ingresscontrollers[0].nodePlacement | object | empty | Bind IngressController to specific nodes Here as example for Infrastructure nodes. |
| ingresscontrollers[0].nodePlacement.tolerations | list | `[{"effect":"NoSchedule","key":"node-role.kubernetes.io/infra","operator":"Equal","value":"reserved"},{"effect":"NoExecute","key":"node-role.kubernetes.io/infra","operator":"Equal","value":"reserved"}]` | Tolerations, required if the nodes are tainted.   |
| ingresscontrollers[0].replicas | int | 2 | Number of replicas for this IngressController |

## Example values

```yaml
---
---
# -- Define ingressControllers
# Multiple might be defined.
ingresscontrollers:
    # -- Name of the IngressController. OpenShift initial IngressController is called 'default'.
  - name: default

    # -- Enable the configuration
    # @default -- false
    enabled: true

    # -- Number of replicas for this IngressController
    # @default -- 2
    replicas: 3

    # -- Bind IngressController to specific nodes
    # Here as example for Infrastructure nodes.
    # @default -- empty
    nodePlacement:

      # NodeSelector that shall be used.
      nodeSelector:
        key: node-role.kubernetes.io/infra
        value: ''

      # -- Tolerations, required if the nodes are tainted. 
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/infra
          operator: Equal
          value: reserved
        - effect: NoExecute
          key: node-role.kubernetes.io/infra
          operator: Equal
          value: reserved
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

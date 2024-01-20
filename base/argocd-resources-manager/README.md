
![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

# Helper Chart for Argo CD

This chart is a *helper* chart, that is typically used as a Subchart.
For example, it is used by: https://github.com/tjungbauer/openshift-clusterconfig-gitops/tree/main/clusters/argocd-object-manager 

The chart creates all required objects for Argo CD, namely: 

* Applications
* ApplicationSets
* Application Projects

It is done generically so that it can be used by any other Chart to create Argo CD objects. 

## TL;DR 

```console
helm repo add --force-update tjungbauer https://charts.stderr.at
helm repo update
```

## Prerequisites

* Kubernetes 1.12+
* Helm 3

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release tjungbauer/helper-argocd
```

The command deploys the chart on the Kubernetes cluster in the default configuration.

## Uninstalling the Chart

To uninstall/delete the my-release deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters
The following table lists the configurable parameters of the chart and their default values. 

| Parameter                                 | Description                                   | Default                                                 |
|-------------------------------------------|-----------------------------------------------|---------------------------------------------------------|
||||
|**General**|||
|List of anchors: <br><li>`mgmt-cluster`</li><li>`mgmt-cluster-name`</li>| Helm anchors, used to define the API URL and the name of a Kubernetes cluster. Put here a list of your clusters, that are later used for ApplicationSets or Applications as target cluster. | <li>`mgmt-cluster: &mgmtcluster https://kubernetes.default.svc`</li><li>`mgmt-cluster-name: &mgmtclustername in-cluster`</li>|
|`repourl`| Default URL to the repository |`https://github.com/tjungbauer/openshift-clusterconfig-gitops`|
|`repobranch`| Default branch to use|`main`|
||||
|**ApplicationSets**|||
|`applicationsets.UNIQUE-IDENTIFIER`| This is the unique identifier. *Must not contain '-'*. This name is used for the name of the Application that is created though this ApplicationSet using the clustername as prefix (For example: `in-cluster-generic-cluster-config`) | `` |
|`applicationsets.UNIQUE-IDENTIFIER.enabled`|Enabled yes/no| 'false' |
|`applicationsets.UNIQUE-IDENTIFIER.description`| A description of this ApplicationSet | `No description` |
|`applicationsets.UNIQUE-IDENTIFIER.labels`| A list of labels that shall be added to the object. You are free to define your own set of labels. For example: `category: security` | `` |
|`applicationsets.UNIQUE-IDENTIFIER.path`| The path to the Git repository. Use if no `chart` is defined | `` |
|`applicationsets.UNIQUE-IDENTIFIER.chartname`| The chart of a Helm repository. Use if no `path` is defined | `` |
|`applicationsets.UNIQUE-IDENTIFIER.helm`| Defines Helm parameter| `` |
|`applicationsets.UNIQUE-IDENTIFIER.per_cluster_helm_values`| Shall Helm use indifivual values files per cluster |`false`|
|`applicationsets.UNIQUE-IDENTIFIER.releasename`| Releasename of a Helm chart |``|
|`applicationsets.UNIQUE-IDENTIFIER.helmvalues`| Individual values to be set and to be overwritten |``|
|`applicationsets.UNIQUE-IDENTIFIER.generatorclusters`|Using ApplicationSet generator *cluster*|Define cluster using the anchors defined at the beginning. Use [] to deploy on *ALL* clusters|
|`applicationsets.UNIQUE-IDENTIFIER.generatorlist`|Using ApplicationSet generator *list*|Define a list of cluster to which the application shall be deployed.||
|`applicationsets.UNIQUE-IDENTIFIER.generatorlis.clusternamet`| Name of the cluster |``|
|`applicationsets.UNIQUE-IDENTIFIER.generatorlis.clusternamet`| URL of the cluster |``|
|`applicationsets.UNIQUE-IDENTIFIER.repourl`|Default URL to the repository| value of anchor `repourl`|
|`applicationsets.UNIQUE-IDENTIFIER.targetrevision`|Default branch to use| value of anchor `repobranch`|
|`applicationsets.UNIQUE-IDENTIFIER.syncPolicy`|Sync options||
|`applicationsets.UNIQUE-IDENTIFIER.syncPolicy.autosync_enabled`|Enable automatic synchronization of the Application|'false'|
|`applicationsets.UNIQUE-IDENTIFIER.syncPolicy.syncOptions`|List of sync options to be bypassed to the Application<. It takes the Argo CD sync option name as key (name) and the value as setting for that option (value)<br>For example: `-name: CreateNamespace<br><value: true`|``|
|`applicationsets.UNIQUE-IDENTIFIER.syncPolicy.syncpolicy_prune`|Enable pruning|'false'|
|`applicationsets.UNIQUE-IDENTIFIER.syncPolicy.syncpolicy_selfheal`|Enable self healing|'false'|
||||
|**Applications**|||
|`applications.UNIQUE-IDENTIFIER`| This is the unique identifier. *Must not contain '-'*. This name is used for the name of the Application | `` |
|`applications.UNIQUE-IDENTIFIER.enabled`|Enabled yes/no| 'false' |
|`applications.UNIQUE-IDENTIFIER.server`|Target Cluster| '' |
|`applications.UNIQUE-IDENTIFIER.server`|Project inside Argo CD| '' |
|`applications.UNIQUE-IDENTIFIER.description`| A description of this ApplicationSet | `No description` |
|`applications.UNIQUE-IDENTIFIER.labels`| A list of labels that shall be added to the object. You are free to define your own set of labels. For example: `category: security` | `` |
|`applications.UNIQUE-IDENTIFIER.syncOptions`| List of Argo CD sync options (name/value). | `` |
|`applications.UNIQUE-IDENTIFIER.source.path`| The path to the Git repository.| `` |
|`applications.UNIQUE-IDENTIFIER.source.chartname`| If Helm shall be used: Name of the Helm Chart | `` |
|`applications.UNIQUE-IDENTIFIER.source.helm.releasename`| If Helm shall be used: Relasename of the Chart | `` |
|`applications.UNIQUE-IDENTIFIER.source.helm.helmvalues`| If Helm shall be used: list (name/value) of specific Helm values | `` |
|`applications.UNIQUE-IDENTIFIER.source.helm.helmvalues`| If Helm shall be used: list of additional Helm values files. | `` |
|`applications.UNIQUE-IDENTIFIER.source.repourl`|Default URL to the repository| value of anchor `repourl`|
|`applications.UNIQUE-IDENTIFIER.source.targetrevision`|Default branch to use| value of anchor `repobranch`|

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

## Examples

### ApplicationSet 
Currently 2 generators are supported:

* List
* Clusters

#### ApplicationSet - Generator List

Install an Application to a list of clusters. The identifier **install-mgmt-operator-collection** is used as Application name in Argo CD. To make it unique a prefix out of the clustername is created, for example *in-cluster-install-mgmt-operator-collection"*. 

```yaml
    # A collection of MANAGEMENT operators,
    # installed usually on the management cluster only.
    install-mgmt-operator-collection:
      enabled: true
      description: "Deploy a collection of Operators which are usually installed on a management cluster only"
      labels:
        category: operators
      path: charts/collection-management-operators
      generatorlist:
        - clustername: *mgmtclustername
          clusterurl: *mgmtcluster
      syncPolicy:
        autosync_enabled: false  # should be disabled for operators
      repourl: "https://github.com/tjungbauer/helm-charts"
      targetrevision: "main"
```

#### ApplicationSet - Generator Clusters

Create an Argo CD application to encrypt ETCD for **ALL** clusters. The identifier **install-mgmt-operator-collection** is used as Application name in Argo CD. To make it unique a prefix out of the clustername is created, for example *in-cluster-install-mgmt-operator-collection"*

```yaml
    etcd-encryption:
      enabled: true
      description: "Enable Cluster ETCD Encryption"
      labels:
        category: security
      path: clusters/all/etcd-encryption/
      helm:
        per_cluster_helm_values: false
      generatorclusters: []
```

### Applications

Applications are bound to a specific cluster, so whenever a certain software needs to be rolled out on one cluster only, such object should be enough. One example would be Advanced Cluster Security, which is typically deployed on a central management cluster and monitors other clusters from there. 

```yaml
    in-cluster-init-rhacs:
      enabled: true
      server: *mgmtcluster
      project: default
      description: "Initialize Red Hat Advanced Cluster Security and deploy Central and SecuredCluster"
      labels:
        category: security
        solution: rhacs
      source:
        path: charts/rhacs-full-stack
        repourl: "https://github.com/tjungbauer/helm-charts"
        targetrevision: "main"
```

### Application using Helm

```yaml
    hashicorp-vault:
      enabled: true
      description: "Deploy HashoCorp Vault"
      labels:
        category: security
      namespace:
        name: vault
        create: true
      server: *mgmtcluster
      project: default
      source:
        chartname: vaultss
        helm:
          releasename: vault
          helmvalues:
            - name: global.openshift
              value: 'true'
            - name: server.ha.raft.enabled
              value: 'true'
            - name: server.ha.enabled
              value: 'true'
            - name: server.ha.replicas
              value: '1'
        repourl: "https://helm.releases.hashicorp.com"
        targetrevision: 0.21.0
```


# setup-openshift-data-foundation

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Release Charts](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml)

  ![Version: 1.0.2](https://img.shields.io/badge/Version-1.0.2-informational?style=flat-square)

 

  ## Description

This "wrapper" Helm Chart is used to deploy and configure OpenShift Data Foundation using a GitOps approach.
It mainly uses the Chart [openshift-data-foundation](https://github.com/tjungbauer/helm-charts/tree/main/charts/openshift-data-foundation) which takes care to

- Setup the ODF
- Create a Storagesystem, by either configuring a full storage or a MultiCloudGateway only

The example below demonstrates the deployment and configuration of ODF MultiCloudGateWay. It is just a small part of the possibilities the Chart provides, but it is an easy and quick way to provide object storage (s3) inside OpenShift. With that further services such as Logging or Quay can be deployed.
The [values-file](https://github.com/tjungbauer/helm-charts/tree/main/charts/openshift-data-foundation) of the main chart provides further examples of possible settings.

Three additional Charts are required as a dependency and are responsible for installing and verifying the Operator itself as well as providing a template library.
Verify the README and/or the values files for further information.

## Dependencies

This chart has the following dependencies:

| Repository | Name | Version |
|------------|------|---------|
| https://charts.stderr.at/ | helper-operator | ~1.0.14 |
| https://charts.stderr.at/ | helper-status-checker | ~4.0.0 |
| https://charts.stderr.at/ | openshift-data-foundation | ~1.0.10 |
| https://charts.stderr.at/ | tpl | ~1.0.0 |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tjungbauer |  |  |

## Sources
Source:

Source code:

## Example values files

```yaml
---
###########################
# Enable and configura ODF
###########################
openshift-data-foundation:
  storagecluster:
    enabled: true
    syncwave: 3

    # There are two options:
    # Either install the multigateway only. This is useful if you just need S3 for Quay registry for example.
    multigateway_only:
      enabled: true

      # Name of the stroageclass
      # The class must exist upfront and is currently not created by this chart.
      storageclass: gp3-csi

    # Second option is a full deployment, which will provide Block, File and Object Storage
    full_deployment:
      enabled: false

      # Enable NFS or not
      nfs: enabled

      # The label the nodes should have to allow hosting of ODF services
      # Default: cluster.ocs.openshift.io/openshift-storage
      # default_node_label: cluster.ocs.openshift.io/openshift-storage

      # Define the DeviceSets
      storageDeviceSets:
          # Name of the DeviceSet
        - name: ocs-deviceset
          # Resources for the DeviceSets Pods.
          # Limits and Requests can be defined
          # Default:
          #   Limit: cpu: 1, memory: 5Gi
          #   Requests: cpu: 1, memory: 5Gi
          resources:
            requests:
              cpu: '1'
              memory: 5Gi

          # Definitions of the PVC Template
          dataPVCTemplate:
            spec:
              # Default AccessModes
              # Default: ReadWriteOnce
              # accessModes:
              #   - ReadWriteOnce

              # Size of the Storage. Might be 512Gi, 2Ti, 4Ti
              # Default: 512Gi
              resources:
                requests:
                  storage: 512Gi

              # Name of the stroageclass
              # The class must exist upfront and is currently not created by this chart.
              storageClassName: gp3-csi

        # Replicas: Default 3
        # replica: 3

      # Resource settings for the different components.
      # ONLY set this if you know what you are doing.
      # For every component Limits and Requests can be set.

      # For testing request settings might be reduced.
      # compontent_resources:
        # MDS Defaults
        #   Limits: cpu 3, memory: 8Gi
        #   Requests: cpu: 1, memory: 8Gi
        # mds:
        #   requests:
        #     cpu: '1'
        #     memory: 8Gi

        # RGW Defaults
        #   Limits: cpu 2, memory: 4Gi
        #   Requests: cpu: 1, memory: 4Gi
        # rgw: ...
        # rgw:
        #   requests:
        #     cpu: '1'
        #     memory: 4Gi

        # MON Defaults
        #   Limits: cpu 2, memory: 4Gi
        #   Requests: cpu: 1, memory: 4Gi
        # mon: ...

        # MGR Defaults
        #   Limits: cpu 2, memory: 4Gi
        #   Requests: cpu: 1, memory: 4Gi
        # mgr: ...

        # NOOBAA-CORE Defaults
        #   Limits: cpu 2, memory: 4Gi
        #   Requests: cpu: 1, memory: 4Gi
        # moobaa-core: ...

       # NOOBAA-DB Defaults
        #   Limits: cpu 2, memory: 4Gi
        #   Requests: cpu: 1, memory: 4Gi
        # moobaa-DB: ...

# Install Operator Compliance Operator
# Deploys Operator --> Subscription and Operatorgroup
# Syncwave: 0
helper-operator:

  console_plugins:
    enabled: true
    plugins:
      - odf-console
    job_namespace: kube-system

  operators:
    odf-operator:
      enabled: true
      syncwave: '0'
      namespace:
        name: openshift-storage
        create: true
      subscription:
        channel: stable-4.15
        approval: Automatic
        operatorName: odf-operator
        source: redhat-operators
        sourceNamespace: openshift-marketplace
      operatorgroup:
        create: true

helper-status-checker:
  enabled: true

  checks:
    - operatorName: odf-operator
      namespace:
        name: openshift-storage
      serviceAccount:
        name: "status-checker-odf"
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)

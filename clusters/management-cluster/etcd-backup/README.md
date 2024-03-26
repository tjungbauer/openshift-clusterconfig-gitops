

# clusterconfig-etcd-encryption

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Linting](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml/badge.svg)](https://github.com/tjungbauer/openshift-clusterconfig-gitops/actions/workflows/linting.yml)
[![Release Charts](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml/badge.svg)](https://github.com/tjungbauer/helm-charts/actions/workflows/release.yml)

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square)

## Description

This chart uses <https://github.com/tjungbauer/helm-charts> as a source. Please verify the README there as well.

Create a CronJob that performs ETCD Backup and stores the backup to a PV.

This Helm Chart can be used to create a backup of ETCD.
It will execute a CronJob on one of the control planes in order to dump ETCD and store it in a PV.

**WARNING**: In order to be able to create such a backup, this CronJob must be able to start a *PRIVILEGED* pod.

**CAUTION**: The backup contains two files: the etcd DB and a tar.gz. If etcd is encrypted, then the tar.gz will contain the keys to decrypt the DB. It is up to the storage team to be sure that the access to the share is secure.
(Maybe in the future I can extend the Chart ... or just create a pull request :) )

## CronJob Workflow

The CronJob will perform the following:

1. It will start a debug pod **on one of the Control Planes** (The CronJob is scheduled on one of the Control Planes).
2. Via the Debug pod, on the Control Plane it will execute the script **/usr/local/bin/cluster-backup.sh** and store it into **/home/core/backup** (on the Control Plane).
3. Then a target folder might be created, if it does not exist yet using configured mountpath and the name of the cluster.
4. The backup files are moved from /host/home/core/backup/* (This is the backup location from the CronJob point of view) to the target folder.
5. To save some space, the files will be zipped.
6. Finally, backup files that are older than the **retention** time (default 30 days) will be removed from the target folder and from the Control Plane.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tjungbauer | <tjungbau@redhat.com> | <https://blog.stderr.at/> |

## Sources
Source:
* <https://github.com/tjungbauer/helm-charts>
* <https://charts.stderr.at/>
* <https://github.com/tjungbauer/openshift-clusterconfig-gitops>

Source code: https://github.com/tjungbauer/helm-charts/tree/main/charts/etcd-backup

## Example values

**NOTE**: Please verify the full Readme at: https://github.com/tjungbauer/helm-charts/charts/etcd-backup

```yaml
---
name: &bu_name etcd-backup
backup_storage_size: &backup_storage_size "100Gi"

etcd-backup:
  enabled: true
  clusterrolebinding_name: *bu_name
  
  # Variables for the Namespace where ETCD backup shall be executed.
  namespace:
    create: true
    name: *bu_name
    displayname: "Backup ETCD Automation"
    description: "Openshift Backup Automation Tool"
  
  serviceAccount: *bu_name
  
  # Settings for the CronJob
  cronjob:
    name: *bu_name
    schedule: "0 */4 * * *"
    retention: 30
    mountpath: /etcd-backup
  
  # Settings for the PVC
  pvc:
    name: *bu_name
    size: *backup_storage_size
    storageClass: "gp3-csi"
    volumeName: *bu_name
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

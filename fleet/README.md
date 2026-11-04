# fleet: entry point of clusters-ng

An app-of-apps that creates the ApplicationSets, the same way as `base/`:

```text
init_app_of_apps            installed once with Helm, creates the Application fleet-applicationsets
  applicationsets           values for helper-argocd, one ApplicationSet per cluster
    Applications            one per component and cluster, see clusters-ng/
```

Nothing syncs automatically, on no level. `helper-argocd` 2.0.48 or newer is required.

## Install

```bash
helm upgrade --install --dependency-update --namespace openshift-gitops \
  --values fleet/init_app_of_apps/values.yaml \
  fleet-app-of-apps fleet/init_app_of_apps
argocd app sync fleet-applicationsets
```

## Add a cluster

Copy one entry below `applicationsets:` in `applicationsets/values.yaml`, change its name and the
path of its `cluster.yaml`, and sync `fleet-applicationsets`.

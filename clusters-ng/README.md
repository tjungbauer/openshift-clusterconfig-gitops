# clusters-ng: fleet configuration (blueprint)

`clusters/` is the old layout: one chart folder per component and cluster. `clusters-ng/` is the
new one: a chart exists once, a cluster only selects components and adds its values. The old
folders stay unchanged, so both can be compared.

Target: 50+ clusters, managed by one central Argo CD. Later Argo CD Agent.

| Path | Purpose |
|---|---|
| `catalog.yaml` | All components and their namespace |
| `../components/<component>/` | One Helm chart per component (top level of the repository) |
| `<cluster>/cluster.yaml` | Argo CD cluster name, group and components of a cluster |
| `<cluster>/values/<component>.yaml` | Values of one cluster |
| `groups/<group>/<component>.yaml` | Values of a group of clusters |
| `waves/` | ACM policies, used by `wave-acm-policy-management` |

Values are merged in this order, the last one wins: chart `values.yaml`, group `global.yaml`,
group component file, cluster `global.yaml`, cluster component file.

## Demo clusters

| Directory | Cluster in Argo CD | State |
|---|---|---|
| `management-cluster` | `in-cluster` | active, all components of `clusters/management-cluster` |
| `sno` | `sno` | `active: false`, set to true once the cluster is registered |
| `bm` | `bm` | `active: false`, set to true once the cluster is registered |

`sno` and `bm` show the effect: 5 folders per cluster become 2 small value files, the charts are shared.

## Add a cluster

1. Register the cluster in Argo CD.
2. Create an AppProject named like the cluster in Argo CD.
3. Create `clusters-ng/<cluster>/cluster.yaml` with `clusterName:`, `group:` and `components:`.
   Add an entry to `../fleet/applicationsets/values.yaml` and sync `fleet-applicationsets`.
4. Add only the values that differ in `clusters-ng/<cluster>/values/`.
5. Seal the secrets for this cluster, see below.

## ApplicationSets

Every cluster has its own ApplicationSet `cluster-config-<cluster>`. They are created by the
app-of-apps in `../fleet/`, rendered by `helper-argocd`. See `../fleet/README.md`.

A typo in one `cluster.yaml` only stops that cluster. `catalog.yaml` is still shared by all.

## Add a component

1. Create the chart in `../components/<component>/` (top level of the repository).
2. Add it to `catalog.yaml`.
3. Select it in the `cluster.yaml` of the clusters that need it.

## Sync

Nothing syncs automatically: no Application has an `automated` block, this includes the
Applications created by `wave-acm-policy-management`. Sync components in the order of `needs`
in `catalog.yaml`.

To test a chart on one cluster: pin all clusters to a Git tag with `revision` in `catalog.yaml`,
tag the new chart (for example `branding/2.0.0`), set that `revision` in the `cluster.yaml` of the
test cluster, sync it and verify. Then move the catalog to the new tag and remove the override.
Values always come from `main`, only the chart is pinned.

The label `group` on all Applications prepares staged rollouts with Progressive Syncs
(`RollingSync`). It is not enabled: the ApplicationSet controller would trigger syncs itself.

## Sealed secrets

A SealedSecret can only be decrypted with the key of the cluster it was sealed for. The chart
`helper-sealed-secrets` renders the objects, so components only add it as a dependency. The encrypted
values are in `<cluster>/values/<component>.yaml` below `helper-sealed-secrets.secrets`, with the name
of the Secret as key. A cluster without these values renders no SealedSecret.

| Component | Secrets |
|---|---|
| `cert-manager` | `prod-route53-credentials-secret` |
| `idp`, `generic-clusterconfig` | `htpasswd-secret` |
| `trusted-profile-analyzer` | `postgresql-admin-credentials`, `postgresql-credentials` |

The values in `management-cluster` work only on the management cluster. Every other cluster needs
its own, sealed with kubeseal against its own controller.

## Argo CD Agent

`clusterName` must equal the agent name. Required changes in managed mode: set `metadata.namespace`
in the template (see the comment there), enable Applications in any namespace and check how the
destination has to be written. AppProjects need `sourceNamespaces` and destinations that match
the agent name.

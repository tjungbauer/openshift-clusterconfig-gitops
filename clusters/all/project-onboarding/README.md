# Project Onboarding Operator (OLM)

Install the **Project Onboarding** operator from the published catalog (see [project-onboarding-operator](https://github.com/tjungbauer/project-onboarding-operator) docs).

## Tenant onboarding

Tenant onboarding in this repository still uses the legacy **`helper-proj-onboarding` Helm chart** under `tenants/`. That path is **deprecated** and will be replaced by cluster-scoped `ProjectOnboarding` and `TShirtSize` CRs.

Reference migration manifests:

- `https://github.com/tjungbauer/project-onboarding-operator/tree/main/config/samples/migration/`
- Cluster GitOps defaults: `config/samples/onboarding_defaults_configmap.yaml`

## Install

Follow [openshift-install.md](https://github.com/tjungbauer/project-onboarding-operator/blob/main/docs/openshift-install.md) or OperatorHub once the catalog is published to Red Hat.

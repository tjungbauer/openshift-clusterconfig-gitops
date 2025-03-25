# setup-network-observability

![Version: 1.0.1](https://img.shields.io/badge/Version-1.0.1-informational?style=flat-square)

Installs and configures OpenShift Network Observability.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| tjungbauer |  |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../../../../helm-charts/charts/network-observability | network-observability | ~2.0.0 |
| https://charts.stderr.at/ | helper-loki-bucket-secret | ~1.0.0 |
| https://charts.stderr.at/ | helper-lokistack | ~1.0.0 |
| https://charts.stderr.at/ | helper-objectstore | ~1.0.0 |
| https://charts.stderr.at/ | helper-operator | ~1.0.0 |
| https://charts.stderr.at/ | tpl | ~1.0.0 |

## Values

### namespace

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| network-observability.netobserv.additionalAnnotations | object | {} | Additional labels to add to the Keycloak instance as key: value pairs. |
| network-observability.netobserv.additionalLabels | object | {} | Additional labels to add to the Keycloak instance as key: value pairs. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bucketname | string | `"netobserv-bucket"` |  |
| helper-loki-bucket-secret.bucket.name | string | `"netobserv-bucket"` |  |
| helper-loki-bucket-secret.enabled | bool | `true` |  |
| helper-loki-bucket-secret.namespace | string | `"netobserv"` |  |
| helper-loki-bucket-secret.secretname | string | `"netobserv-loki-s3"` |  |
| helper-loki-bucket-secret.syncwave | int | `2` |  |
| helper-lokistack.enabled | bool | false | Enable or disable LokiStack configuration |
| helper-lokistack.mode | string | static | Mode defines the mode in which lokistack-gateway component will be configured. Can be either: static (default), dynamic, openshift-logging, openshift-network |
| helper-lokistack.name | string | `"netobserv-loki"` | Name of the LokiStack object |
| helper-lokistack.namespace | string | `"netobserv"` | Namespace of the LokiStack object |
| helper-lokistack.podPlacements | object | `{}` | Control pod placement for LokiStack components. You can define a list of tolerations for the following components: compactor, distributer, gateway, indexGateway, ingester, querier, queryFrontend, ruler |
| helper-lokistack.storage.secret.name | string | `"netobserv-loki-s3"` | Name of a secret in the namespace configured for object storage secrets. |
| helper-lokistack.storage.size | string | 1x.extra-small | Size defines one of the supported Loki deployment scale out sizes. Can be either:   - 1x.extra-small (Default)   - 1x.small   - 1x.medium |
| helper-lokistack.storageclassname | string | gp3-csi | Storage class name defines the storage class for ingester/querier PVCs. |
| helper-lokistack.syncwave | int | 3 | Syncwave for the LokiStack object. |
| helper-objectstore.backingstore_name | string | `"netobserv-backingstore"` |  |
| helper-objectstore.backingstore_size | string | `"100Gi"` |  |
| helper-objectstore.baseStorageClass | string | `"gp3-csi"` |  |
| helper-objectstore.bucket.enabled | bool | `true` |  |
| helper-objectstore.bucket.name | string | `"netobserv-bucket"` |  |
| helper-objectstore.bucket.namespace | string | `"netobserv"` |  |
| helper-objectstore.bucket.storageclass | string | `"netobserv-bucket-storage-class"` |  |
| helper-objectstore.bucket.syncwave | int | `2` |  |
| helper-objectstore.enabled | bool | `true` |  |
| helper-objectstore.storageclass_name | string | `"netobserv-bucket-storage-class"` |  |
| helper-operator.console_plugins.enabled | bool | `true` |  |
| helper-operator.console_plugins.job_namespace | string | `"kube-system"` |  |
| helper-operator.console_plugins.plugins[0] | string | `"netobserv-plugin"` |  |
| helper-operator.operators.netobserv-operator.enabled | bool | `true` |  |
| helper-operator.operators.netobserv-operator.namespace.create | bool | `true` |  |
| helper-operator.operators.netobserv-operator.namespace.name | string | `"openshift-netobserv-operator"` |  |
| helper-operator.operators.netobserv-operator.operatorgroup.create | bool | `true` |  |
| helper-operator.operators.netobserv-operator.operatorgroup.notownnamespace | bool | `true` |  |
| helper-operator.operators.netobserv-operator.subscription.approval | string | `"Automatic"` |  |
| helper-operator.operators.netobserv-operator.subscription.channel | string | `"stable"` |  |
| helper-operator.operators.netobserv-operator.subscription.operatorName | string | `"netobserv-operator"` |  |
| helper-operator.operators.netobserv-operator.subscription.source | string | `"redhat-operators"` |  |
| helper-operator.operators.netobserv-operator.subscription.sourceNamespace | string | `"openshift-marketplace"` |  |
| helper-operator.operators.netobserv-operator.syncwave | string | `"0"` |  |
| helper-status-checker.approver | bool | `false` |  |
| helper-status-checker.checks[0].namespace.name | string | `"openshift-netobserv-operator"` |  |
| helper-status-checker.checks[0].operatorName | string | `"netobserv-operator"` |  |
| helper-status-checker.checks[0].serviceAccount.name | string | `"sa-file-netobserv-checker"` |  |
| helper-status-checker.enabled | bool | `true` |  |
| lokisecret | string | `"netobserv-loki-s3"` |  |
| lokistack_name | string | `"netobserv-loki"` |  |
| namespace | string | `"netobserv"` |  |
| namespace-operator | string | `"openshift-netobserv-operator"` |  |
| network-observability.netobserv.agent | object | `{"ebpf":{"excludeInterfaces":["lo"],"features":["PacketDrop","DNSTracking","NetworkEvents"],"privileged":true},"type":"eBPF"}` | Agent configuration for flows extraction |
| network-observability.netobserv.agent.ebpf | object | `{"excludeInterfaces":["lo"],"features":["PacketDrop","DNSTracking","NetworkEvents"],"privileged":true}` | Settings related to the eBPF-based flow reporter. |
| network-observability.netobserv.agent.ebpf.excludeInterfaces | list | ['lo'] | Interfaces to exclude from the eBPF agent. |
| network-observability.netobserv.agent.ebpf.features | list | [] | Features to enable for the eBPF agent.<br /> Possible values: <br /> <ul> <li>PacketDrop: Enable the packets drop flows logging feature. This feature requires mounting the kernel debug filesystem, so the eBPF agent pods must run as privileged. If the spec.agent.ebpf.privileged parameter is not set, an error is reported.</li> <li>DNSTracking: Enable the DNS tracking feature.</li> <li>FlowRTT: Enable flow latency (sRTT) extraction in the eBPF agent from TCP traffic.</li> <li>NetworkEvents: Enable the network events monitoring feature, such as correlating flows and network policies. This feature requires mounting the kernel debug filesystem, so the eBPF agent pods must run as privileged. It requires using the OVN-Kubernetes network plugin with the Observability feature. IMPORTANT: This feature is available as a Technology Preview.</li> <li>PacketTranslation: Enable enriching flows with packet translation information, such as Service NAT.</li> <li>EbpfManager: [Unsupported (*)]. Use eBPF Manager to manage network observability eBPF programs. Pre-requisite: the eBPF Manager operator (or upstream bpfman operator) must be installed.</li> <li>UDNMapping: [Unsupported (*)]. Enable interfaces mapping to User Defined Networks (UDN). This feature requires mounting the kernel debug filesystem, so the eBPF agent pods must run as privileged. It requires using the OVN-Kubernetes network plugin with the Observability feature.</li> </ul> |
| network-observability.netobserv.agent.ebpf.privileged | bool | false | Enable privileged mode for the eBPF agent. |
| network-observability.netobserv.agent.type | string | eBPF | Type of the agent. |
| network-observability.netobserv.consolePlugin | object | `{"advanced":{"scheduling":null},"enable":true,"quickFilters":[{"default":true,"filter":{"flow_layer":"\"app\""},"name":"Applications"},{"filter":{"flow_layer":"\"infra\""},"name":"Infrastructure"},{"default":true,"filter":{"dst_kind":"\"Pod\"","src_kind":"\"Pod\""},"name":"Pods network"},{"filter":{"dst_kind":"\"Service\""},"name":"Services network"}]}` | Console Plugin configuration related to the OpenShift Console integration. |
| network-observability.netobserv.consolePlugin.advanced | object | `{"scheduling":null}` | Advanced Parameters for the Console Plugin |
| network-observability.netobserv.consolePlugin.advanced.scheduling | string | `nil` | Set placement and tolerations for the consolePlugin |
| network-observability.netobserv.consolePlugin.enable | bool | true | Enable the console plugin. |
| network-observability.netobserv.consolePlugin.quickFilters | list | [] | Quick filters configures quick filters presents for the console plugin. You can define any filter you like, but the following filters are available by default: <ul> <li>Applications: filter flows by the application layer</li> <li>Infrastructure: filter flows by the infrastructure layer</li> <li>Pods network: filter flows by the source and destination kind of Pod</li> <li>Services network: filter flows by the destination kind of Service</li> </ul> It is not recommended to remove the default filters. |
| network-observability.netobserv.deploymentModel | string | Direct | Ddefines the desired type of deployment for flow processing. Possible values: <br /> <ul> <li>Direct</li> <li>Kafka</li> </ul> |
| network-observability.netobserv.enabled | bool | false | Enable Network Observability configuration? This will also create the reader/writer rolebanding for multi-tenancy |
| network-observability.netobserv.exporters | list | `[]` | additional optional exporters for custom consumption or storage. |
| network-observability.netobserv.loki | object | `{"enable":true,"lokiStack":{"name":"netobserv-loki"},"mode":"LokiStack"}` | Loki client settings |
| network-observability.netobserv.loki.enable | bool | true | Enable storing flows in Loki. Loki and/or Prometheus can be used. However, mot everything is transposable from Loki to Prometheus. Therefor some features of the plugin are disabled as well, if Loki is disabled. If Prometheus and Loki are enabled, then Prometheus will take precedence and Loki is used as a fallback. |
| network-observability.netobserv.loki.lokiStack | object | `{"name":"netobserv-loki"}` | Configuration for LOKI STACK MODE |
| network-observability.netobserv.loki.lokiStack.name | string | loki | Name of an existing LokiStack resource to use. |
| network-observability.netobserv.loki.mode | string | Monolithic | Mode must be set according to the deployment mode of Loki. Possible values: <br /> <ul> <li>LokiStack: when Loki is managed using the Loki Operator</li> <li>Microservices: when Loki is installed as a microservice, but without the Loki Operator</li> <li>Monolithic: when Loki is installed as a monolithic workload</li> <li>Manual: if none of the options above match</li> </ul> |
| network-observability.netobserv.namespace | object | 'netobserv' | Namespace where Network Observability FlowCollector shall be installed. |
| network-observability.netobserv.processor.logTypes | string | Flows | Log types defines the desired record types to generate. Possible values are:<br> <ul> <li>Flows to export regular network flows. This is the default.</li> <li>Conversations to generate events for started conversations, ended conversations as well as periodic "tick" updates.</li> <li>EndedConversations to generate only ended conversations events.</li> <li>All to generate both network flows and all conversations events. It is not recommended due to the impact on resources footprint.</li> </ul> |
| network-observability.netobserv.syncwave | int | 10 | Syncwave for the FlowCollector resource. |
| storageclassname | string | `"netobserv-bucket-storage-class"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)

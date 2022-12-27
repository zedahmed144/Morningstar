# THE EFK stack


A sample environment running an [EFK stack][efk] on any environment.

This project uses the following tools:

- [Elasticsearch][elasticsearch]
- [Fluentd][fluentd]
- [Kibana][kibana]

## Contents

- [Introduction](#Introduction)
  - [Elasticsearch](#Elasticsearch)
  - [FluentD](#FluentD)
  - [Kibana](#Kibana)
- [Launching the stack](#Launching-the-stack)
  - [Overview](#Overview)
  - [Comparing Logstash and Fluentd](#Comparing-Logstash-and-Fluentd)
    - [Event routing](#Event-routing)
    - [Plugins](#Plugins)
    - [Transport](#Transport)
    - [Log parsing](#Log-parsing)
    - [Docker support](#Docker-support)
    - [Which one to use?](#Which-one-to-use?)
  - [Requirements](#Requirements)
  - [FluentD image](#FluentD-image)
  - [Run](#Run)
- [Configuration](#Configuration)
  - [Step 1: Creating the Elasticsearch StatefulSet and Service](#Step-1-Creating_the-Elasticsearch-StatefulSet-and-Service)
  - [Step 2: Creating the Kibana Deployment and Service](#Step-2-Creating-the-Kibana-Deployment-and-Service)
  - [Step 3: Creating the Fluentd DaemonSet and Service](#Step-3-Creating-the-Fluentd-DaemonSet-and-Service)
    - [Source Configuration](#Source-Configuration)
    - [Routing Configuration](#Routing-Configuration)
- [Reference](#Reference)
- [Considerations](#Considerations)



## Introduction


As applications grow and become more and more decoupled, log aggregation is a key aspect to take care of to assure an eagle-eye overview of what is happening inside your environment. Having all your logs in one place provides a powerful opportunity for running queries, data analysis and also creating monitoring dashboards.

<p align="center">
  <img width="500" height="300" src="https://github.com/312-bc/devops-tools-22b-centos/blob/ahmed/Kubernetes/EFKStack/image.png?raw=true">
</p>



### Elasticsearch

Elasticsearch is a real-time, distributed, and scalable search engine which allows for full-text and structured search, as well as analytics. It is commonly used to index and search through large volumes of log data, but can also be used to search many different kinds of documents.




### FluentD

Fluentd is a popular open-source data collector that we’ll set up on our Kubernetes nodes to tail container log files, filter and transform the log data, and deliver it to the Elasticsearch cluster, where it will be indexed and stored.




### Kibana

Elasticsearch is commonly deployed alongside Kibana, a powerful data visualization frontend and dashboard for Elasticsearch. Kibana allows you to explore your Elasticsearch log data through a web interface, and build dashboards and queries to quickly answer questions and gain insight into your Kubernetes applications.




## Launching the stack

### Overview


The issues to tackle down with logging are:

- Having a centralized overview of all log events
- Normalizing different log types
- Automated processing of log messages
- Supporting several and very different event sources

While [Elasticsearch][elasticsearch] and [Kibana][kibana] are the reference products *de facto* for log searching and visualization in the open source community, there's no such agreement for log collectors.


The two most-popular data collectors are:

- [Logstash][logstash], most known for being part of the [ELK Stack][elk]
- [Fluentd][fluentd], used by communities of users of software such as [Docker][docker-fluentd] and [GCP][gcp-fluentd] .. FluentD is known for its wide range of plugins library, it can output data to hundreds of destinations.

Logging systems using Fluentd as a collector are usually referenced as [EFK stack][efk].

### Comparing Logstash and Fluentd

ELK vs EFK stacks has been at the center of observability community chats. more of the new guard vs the old gard. Below, we will do a high level breakdown of the major diffrences in both log aggregators.

#### Event routing

Logstash uses the if-else condition approach; this way we can define certain criteria with If..Then..Else statements – for performing actions on our data.

With Fluentd, the events are routed on tags. Fluentd uses tag-based routing and every input (source) needs to be tagged. Fluentd then matches a tag against different outputs and then sends the event to the corresponding output.tagging events is much easier than using if-then-else for each event type, so Fluentd has an advantage here


<p align="center">
  <img width="500" height="300" src="https://github.com/312-bc/devops-tools-22b-centos/blob/ahmed/Kubernetes/EFKStack/fda.png?raw=true">
</p>

#### Plugins

The Logstash plugin ecosystem is centralized under a single GitHub repository. Fluentd has an official repository, but most of the plugins are hosted elsewhere. It depends on the user’s preference for how they want to manage and collect the plugins, from a centralized place (Logstash) or from several places (Fluentd). Efficiency wise, a centralized place is usually preferable.

#### Transport

Inputs – like files, syslog and data stores – are used to get data into Logstash. Logstash is limited to an in-memory queue that holds 20 events and, therefore, it acts as a "broker" and relies on an external queue to ingest data from remote Logstash “shippers”.
This means that with Logstash you need an additional tool to be installed and configured in order to get data into Logstash. This dependency on an additional tool adds another dependency and complexity to the system, and can increase the risk of failure. This is not the case with Fluentd, which is independent in getting its data and has a configurable in-memory or on-disk buffering system. Fluentd, therefore, is ‘safer’ than Logstash regarding data transport.


#### Log parsing

he components for log parsing are different per logging tool. Fluentd uses standard built-in parsers (JSON, regex, csv etc.) and Logstash uses plugins for this. This makes Fluentd favorable over Logstash, because it does not need extra plugins installed, making the architecture more complex and more prone to errors.



#### Docker support

ocker has a built-in logging driver for Fluentd, but doesn’t have one for Logstash. With Fluentd, no extra agent is required on the container in order to push logs to Fluentd. Logs are directly shipped to Fluentd service from STDOUT without requiring an extra log file.

Logstash requires a plugin (filebeat) in order to read the application logs from STDOUT before they can be sent to Logstash.

Thus, when using Docker containers, Fluentd is the preferred candidate, as it makes the architecture less complex and this makes it less risky for logging mistakes.



#### Which one to use?

For Kubernetes environments, Fluentd seems the ideal candidate due to its built-in Docker logging driver and parser – which doesn’t require an extra agent to be present on the container to push logs to Fluentd. In comparison with Logstash, this makes the architecture less complex and also makes it less risky for logging mistakes. The fact that Fluentd, like Kubernetes, is another CNCF project is also an added bonus!

### Requirements

Make sure you do have the following pre-requisites setup:

- Install [Docker][docker] on your machine.
- A Kubernetes 1.10+ cluster with role-based access control (RBAC) enabled.
- The kubectl command-line tool installed on your local machine, configured to connect to your cluster.
- make sure the names used for these services, are available (everything will be deployed in a new namespace)
- If you are deploying this in the cloud, make sure that you are properly configured (ex: CLI for AWSs). 


### FluentD image
In this cluster, we wanted to collect our logs and ship them, not only to Elasticsearch, but also to AWS S3 as a redundant backup for Elasticsearch. 

Other benefits of storing logs in S3 are querying logs using [Athena][Athena], efficiently querying and retrieving structured and semi-structured data using Redshift Spectrum, load the data into Amazon [Redshift][Redshift] tables for database usage.

As there is no over-the-shelf image for FluentD to output to several destinations, we had to create our own image. The [FluentD_image][FluentD_image] folder contains the appropriate files needed for the build, including Dockerfile, Ruby Gems, plugins, and dependencies list along with the config files. 
Please refer to the [Configuration][Configuration] section below for further instructions.
 



### Run

```bash
make all
```

Please note: The Makefile has been configured with the appropriate targets to deploy specific services. If you choose to do so, please make sure you know the dependencies. <code>make all</code> will run all the targets in the appropriate order.





## Configuration

There are two ways to implement this stack: 

```bash
    - Using the Makefile's "make all", or separate targets. If you choose to use this way, please make  sure to change the appropriate variables in the makefile. That includes: repo, AWS_PROFILE name and cluster-name. 
```

```bash
    - Manually deploying the kubernetes manifest. This is further explained below along with the fonctionality of the cluster.
```






### Step 1: Creating the Elasticsearch StatefulSet and Service


To start, we’ll create a namespace called <code>kube-logging</code> in which we will deploy all of our components. Then, we create a headless Kubernetes service called elasticsearch that will define a DNS domain for our clutser's pods. We also open and name ports <code>9200</code> and <code>9300</code> for REST API and inter-node communication, respectively. In our StatefulSet manifest, we create 3 replicas and we specify a <code>volumeMount</code> called data that will mount the <code>PersistentVolume</code> named data to the container at the path <code>/usr/share/elasticsearch/data</code>. Please note that we will be using <code>AWS EBS</code> for storage. For that, the manifest file also defines a <code>PersistentVolumeClaim</code> that requests 10G from AWS <code>StorageClass</code>.


<b><code>But why 3 pods ?</b></code>
A more accurate question here is why an odd number ? it doesn't hve to be 3 pods, we can adopt a strategy of 1,3,5,7 ...  this even number is to avoid the <code>split-brain</code> issue that occurs in highly-available, multi-node clusters. At a high-level, “split-brain” is what arises when one or more nodes can’t communicate with the others, and several “split” masters get elected. With 3 nodes, if one gets disconnected from the cluster temporarily, the other two nodes can elect a new master and the cluster can continue functioning while the last node attempts to rejoin.
This can be initially configured during the bootstraping step as follows <code>cluster.intial.master_nodes</code>:

<p align="center">
  <img width="700" height="300" src="https://github.com/312-bc/devops-tools-22b-centos/blob/ahmed/Kubernetes/EFKStack/elect.png?raw=true">
</p>

Furthermore, if - for any reason - opting for an even-number of pods, make sure that <code>cluster.auto_shrink_voting_configuration</code> is set to true. If there is an even number, Elasticsearch leaves one of them out of the voting configuration to ensure that it has an odd size. This omission does not decrease the failure-tolerance of the cluster. In fact, improves it slightly: if the cluster suffers from a network partition that divides it into two equally-sized halves then one of the halves will contain a majority of the voting configuration and will be able to keep operating. Check <b>Euler's Totient function</b> to know how to always return odd numbers from any set.


```bash
kubectl apply -f namespace.yaml 
kubectl apply -f elasticsearch.yaml
kubectl apply -f headless_service.yaml
```






### Step 2: Creating the Kibana Deployment and Service

To launch Kibana on Kubernetes, we’ll create a Service called kibana, and a Deployment consisting of one Pod replica. You can scale the number of replicas depending on your production needs. We specify <code>containerPort: 5601</code> then we use the <code>ELASTICSEARCH_URL</code> environment variable to set the endpoint and port for the Elasticsearch cluster. Using Kubernetes DNS, this endpoint corresponds to its Service name <code>elasticsearch</code>. This domain will resolve to a list of IP addresses for the 3 Elasticsearch Pods.

The Kibana manifest file defines a service called kibana in the kube-logging namespace, and make it listen on <code>port 80</code> while matching the target port with Kibana <code>containerPort: 5601</code>. Optionally specify a <code>LoadBalancer</code> type for the Service to load balance requests across the Deployment pods.


```bash
kubectl apply -f kibana_deploy.yaml
```
Optional:

Setting up an Ingress rule will help establish seamless access to the Kibana UI. The ingress rule Manifest forwards traffic coming through the DNS record (kibana.22bcentos.exchangeweb.net) to the Kibana service through port <code>5601</code>. Please make sure to set up the appropriate DNS record and appropriate forwarding settings for this to work.

```bash
kubectl apply -f ingress_rule.yaml
```





### Step 3: Creating the Fluentd DaemonSet and Service

In this guide, we’ll set up Fluentd as a DaemonSet, which is a Kubernetes workload type that runs a copy of a given Pod on each Node in the Kubernetes cluster. Using this DaemonSet controller, we’ll roll out a Fluentd logging agent Pod on every node in our cluster. The Fluentd Pod will tail the <code>stdout</code> log files, filter log events, transform the log data, and ship it off to the Elasticsearch logging backend we deployed in Step 2. Additionally to container logs, the Fluentd agent will tail Kubernetes system component logs like <code>kubelet</code>, <code>kube-proxy</code>, and <code>Docker</code> logs. To see a full list of sources tailed by the Fluentd logging agent, and configure them, consult the <code>kubernetes.conf</code> under [FluentD_image][FluentD_image] directory.
We create a Service Account called <code>fluentd</code> that the Fluentd Pods will use to access the Kubernetes API. using RBAC <code>Roles</code> and <code>ClusterRoles</code>, We grant the <code>get</code>, <code>list</code>, and <code>watch</code> permissions on the pods and namespaces objects.

The <code>FLUENT_ELASTICSEARCH_HOST</code> and <code>FLUENT_ELASTICSEARCH_PORT</code> should point to <code>Elasticsearch headless Service</code> and port <code>9200</code> respectively.
Lastly, we mount the <code>/var/log</code> and <code>/var/lib/docker/containers</code> host paths into the container. These volumes are defined at the end of the same manifest file.

```bash
kubectl apply -f FluentD_Deploy.yaml
kubectl apply -f FluentD_SA.yaml
```



#### Source Configuration

For the purpose of our project, to capture all container logs on a Kubernetes node, the following source configuration is required:

```bash
<source>

@id fluentd-containers.log

@type tail

path /var/log/containers/*.log

pos_file /var/log/fluentd-containers.log.pos

time_format %Y-%m-%dT%H:%M:%S.%NZ

tag raw.kubernetes.*

format json

read_from_head true

</source>
```

1. <code><b>id:</b></code> A unique identifier to reference this source. This can be used for further filtering and routing of structured log data
2. <code><b>type:</b></code> Inbuilt directive understood by fluentd. In this case, “tail” instructs fluentd to gather data by tailing logs from a given location. Another example is “http” which instructs fluentd to collect data by using GET on http endpoint.
3. <code><b>path:</b></code> Specific to type “tail”. Instructs fluentd to collect all logs under /var/log/containers directory. This is the location used by docker daemon on a Kubernetes node to store stdout from running containers.
4. <code><b>pos_file:</b></code> Used as a checkpoint. In case the fluentd process restarts, it uses the position from this file to resume log data collection
5. <code><b>tag</b></code> A custom string for matching source to destination/filters. fluentd matches source/destination tags to route log data



#### Routing Configuration
An exemple config config instructing fluentd to send logs to Elasticsearch. Many destinations can be configured at once in the same file <code>fluent.conf</code>
```bash
<match **>

@id elasticsearch

@type elasticsearch

@log_level info

include_tag_key true

type_name fluentd

host "#{ENV['OUTPUT_HOST']}"

port "#{ENV['OUTPUT_PORT']}"

logstash_format true

<buffer>

@type file

path /var/log/fluentd-buffers/kubernetes.system.buffer

flush_mode interval

retry_type exponential_backoff

flush_thread_count 2

flush_interval 5s

retry_forever

retry_max_interval 30

chunk_limit_size "#{ENV['OUTPUT_BUFFER_CHUNK_LIMIT']}"

queue_limit_length "#{ENV['OUTPUT_BUFFER_QUEUE_LIMIT']}"

overflow_action block

</buffer>
```

1. <code><b>“match”</b></code> tag indicates a destination. It is followed by a regular expression for matching the source. In this case, we want to capture all logs and send them to Elasticsearch, so simply use **.
2. <code><b>id:</b></code> Unique identifier of the destination.
3. <code><b>type:</b></code> Supported output plugin identifier. In this case, we are using ElasticSearch which is a built-in plugin of fluentd.
4. <code><b>log_level:</b></code> Indicates which logs to capture. In this case, any log with level “info” and above – INFO, WARNING, ERROR – will be routed to Elasticsearch.
5. <code><b>host/port:</b></code> ElasticSearch host/port. Credentials can be configured as well, but not shown here.
6.  <code><b>logstash_format:</b></code> The Elasticsearch service builds reverse indices on log data forward by fluentd for searching. Hence, it needs to interpret the data. By setting logstash_format to “true”, fluentd forwards the structured log data in logstash format, which Elasticsearch understands.
7. <code><b>Buffer:</b></code> fluentd allows a buffer configuration in the event the destination becomes unavailable. e.g. If the network goes down or ElasticSearch is unavailable. Buffer configuration also helps reduce disk activity by batching writes.



## Considerations


With he current plugins, the maximum capacity that sits at <code>18000 messages/second</code>. Which is the absolute maximun capacity of FluentD with all optimizations. Since FluentD is written in C and the Ruby code acts as a wrapper that provides flexibility to the overall solution but comes fo a cost of performance. 
In case of having higher processing needs, we could horizontally scale or apply solutions that combine FluentD with Fluent Bit to forward the data from the edge to FluentD aggregators.

## Reference

- [Quora - What is the ELK stack](https://www.quora.com/What-is-the-ELK-stack)
- [Fluentd vs. LogStash: A Feature Comparison](https://www.loomsystems.com/blog/single-post/2017/01/30/a-comparison-of-fluentd-vs-logstash-log-collector)
- [Log Aggregation with Fluentd, Elasticsearch and Kibana - Haufe-Lexware.github.io](http://work.haufegroup.io/log-aggregation/)
- [Fluentd vs Logstash, An unbiased comparison](https://techstricks.com/fluentd-vs-logstash/)

[FluentD_image]: https://github.com/312-bc/devops-tools-22b-centos/tree/ahmed/Kubernetes/EFKStack/FluenD_image
[elasticsearch]: https://www.elastic.co/products/elasticsearch
[fluentd]: https://www.fluentd.org/
[Redshift]: https://aws.amazon.com/redshift/?nc=sn&loc=0
[kibana]: https://www.elastic.co/products/kibana
[logstash]: https://www.elastic.co/products/logstash
[elk]: https://www.elastic.co/videos/introduction-to-the-elk-stack
[docker-fluentd]: https://docs.docker.com/reference/logging/fluentd/
[gcp-fluentd]: https://github.com/GoogleCloudPlatform/google-fluentd
[efk]: https://docs.openshift.com/enterprise/3.1/install_config/aggregate_logging.html#overview
[docker]: https://www.docker.com/
[docker-compose]: https://docs.docker.com/compose/
[Athena]: https://aws.amazon.com/athena/?nc=sn&loc=0
[rested]: https://itunes.apple.com/au/app/rested-simple-http-requests/id421879749?mt=12
[FluentD_image]: https://github.com/312-bc/devops-tools-22b-centos/tree/ahmed/Kubernetes/EFKStack/FluenD_image

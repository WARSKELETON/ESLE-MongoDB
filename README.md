# MongoDB Scalability and Performance Evaluation - ESLE

## Structure

| Module               |      Description      |
| :------------------- | :-------------------: |
| [gcp](gcp)     |  Google Cloud infrastructure module  |
| [gcp/k8s](gcp/k8s)     |  MongoDB replica set kubernetes deployment module  |
| [gcp/terraform](gcp/terraform)     |  Terraform GKE cluster module  |
| [results-usl](results-usl)     |      Final scalability results with the factor write concern       |
| [results-usl/experimentUSL1](results-usl/experimentUSL1)      |      Scalability results with the factor write concern w = majority      |
| [results-usl/experimentUSL2](results-usl/experimentUSL2)      |      Scalability results with the factor write concern w = 1      |
| [results-usl/workload1](results-usl/workload1.pdf)      |      Scalability results with the factor experiment 1 and 2      |
| [results-v4](results-v4)     |      Final experiment results with 7 factors and 2 levels (5 repetitions)       |
| [results-v3](results-v3)     |      Third experimental results attempt with 7 factors and 2 levels (5 repetitions)       |
| [results-v2](results-v2)     |      Second experimental results attempt with 7 factors and 2 levels (5 repetitions)       |
| [results-v1](results-v1)     |      First experimental results attempt with 7 factors and 2 levels (5 repetitions)       |
| [workloads](workloads)     |  Workload definition files  |
| [logs](logs)     |  Logs modules  |
| [runner](runner.sh)     | Workload runner script |
| [Dockerfile](Dockerfile)     | Runner with ycsb dockerfile |
| [Docker Compose File](docker-compose.yml)     | Docker Swarm cluster definition |
| [concierge](concierge.sh) |   Workload module cleaner  |
| [janitor](janitor.py)|    Database cleaner   |
| [moca](moca.py)     |      Our own benchmark tool attempt       |
| [populate](populate.py)     |      Populate database script       |
| [results-aggregator](results-aggregator.py)     |      Tool for experiment's results aggregation       |
| [get_results](get_results.sh)     |      Copies experiment from the cloud environment and aggregates results       |
| [rebuild_pods](rebuild_pods.sh)     |      Rebuild MongoDB Kubernetes Service       |

## 7 Factors with 2 Levels

| Factor               |      Level -1         |      Level 1         |
| :------------------- | :-------------------: | :-------------------: |
| [Write Concern (A)](#write-concern-read-concern-read-preference)     |  Majority  | 1 Ack  |
| [Replica Writer Thread Range (B)](#replica-writer-thread-range-replica-batch-limit)     | [0:16] Threads | [0:128] Threads |
| [Read Concern (C)](#write-concern-read-concern-read-preference)     |  1 Ack  | Majority |
| [Read Preference (D)](#write-concern-read-concern-read-preference)     |  Primary Preferred  | Secondary Preferred |
| [Replica Batch Limit (E)](#replica-writer-thread-range-replica-batch-limit)     | 50MB | 100MB |
| [Replica Node Configuration (F)](#replica-node-configuration)     |  Primary-Secondary-Secondary  | Primary-Secondary-Arbiter  | 
| [Chaining (G)](#chaining)     |  Disabled  | Enabled |

## Experiment Iteration Struture (Example)

| Module               |      Description      |
| :------------------- | :-------------------: |
| [outputs](results-v4/experiment1/iteration1/outputs)     |  YCSB folder output  |
| [results-throughput.dat](results-v4/experiment1/iteration1/results-throughput.dat)     | Insert operation latency results |
| [results-latency-insert.dat](results-v4/experiment1/iteration1/results-latency-insert.dat)     | Insert operation latency results |
| [results-latency-read.dat](results-v4/experiment1/iteration1/results-latency-read.dat)     | Read operation latency results |
| [results-latency-scan.dat](results-v4/experiment1/iteration1/results-latency-scan.dat)     | Scan operation latency results |
| [results-latency-update.dat](results-v4/experiment1/iteration1/results-latency-update.dat)     | Update operation latency results |

----
## How to switch the different factors?

### Write Concern, Read Concern, Read Preference

All of these 3 factors are given directly to our runner script, as they are part of the MongoDB connection string per client request:

```shell script
./runner.sh <other-flags> -W <write-concern> -R <read-concern> -P <read-preference>
```

#### Write Concern _Majority_ (Level -1)

```shell script
-W majority
```

#### Write Concern _1 Ack_ (Level 1)

```shell script
-W 1
```

#### Read Concern _1 Ack_ (Level -1)

```shell script
-R local
```

#### Read Concern _Majority_ (Level 1)

```shell script
-R majority
```

#### Read Preference _Primary Preferred_ (Level -1)

```shell script
-P primaryPreferred
```

#### Read Preference _Secondary Preferred_ (Level 1)

```shell script
-P secondaryPreferred
```

### Replica Writer Thread Range, Replica Batch Limit

All of these 2 factors are setup in the MongoDB kubernetes deployment yaml file, as server parameters.

#### Replica Writer Thread Range _[0:16] Threads_ (Level -1)

```yaml
        - "--setParameter"
        - "replWriterMinThreadCount=0"
        - "--setParameter"
        - "replWriterThreadCount=16"
```

#### Replica Writer Thread Range _[0:128] Threads_ (Level 1)

```yaml
        - "--setParameter"
        - "replWriterMinThreadCount=0"
        - "--setParameter"
        - "replWriterThreadCount=128"
```

#### Replica Batch Limit _50MB_ (Level -1)

```yaml
        - "--setParameter"
        - "replBatchLimitBytes=52428800"
```

#### Replica Batch Limit _100MB_ (Level 1)

```yaml
        - "--setParameter"
        - "replBatchLimitBytes=104857600"
```

### Replica Node Configuration

#### Primary-Secondary-Secondary (Level -1)

Create the replica set, for example replica set named "_rs0_" with mongo-0 as primary, mongo-1 and mongo-2 as secondaries:

```
kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [{_id: 0, host: "mongo-0.mongo:27017"}, {_id: 1, host: "mongo-1.mongo:27017"}, {_id: 2, host: "mongo-2.mongo:27017"}]});'
```

#### Primary-Secondary-Arbiter (Level 1)

Create the replica set, for example replica set named "_rs0_" with mongo-0 as primary, mongo-1 as secondary and mongo-2 as arbiter:

```
kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [{_id: 0, host: "mongo-0.mongo:27017"}, {_id: 1, host: "mongo-1.mongo:27017"}, {_id: 2, host: "mongo-2.mongo:27017", arbiterOnly: true}]});'
```

### Chaining

#### Chaining Disabled (Level -1)

Simply create the replica set with the setting _chainingAllowed_ set to false _(members array is redacted for legibility reasons)_:

```shell script
kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [...], settings: {chainingAllowed: false}});'
```

#### Chaining Allowed (Level 1)

Create the replica set with the setting _chainingAllowed_ set to true _(members array is redacted for legibility reasons)_:

```shell script
kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [...], settings: {chainingAllowed: true}});'
```

And force one of the secondaries to utilize the other secondary as its sync source, in this example we are forcing mongo-2 to sync from mongo-1 and mongo-0 is the primary:

```shell script
kubectl exec mongo-2 -- mongo --eval 'db.adminCommand( { replSetSyncFrom: "mongo-1.mongo:27017" });'
```

----
## How to run using GCP?

Provision the infrastructure:

```shell script
cd gcp/terraform
terraform apply
```

Connect to the cluster by getting the command line access from GCP console, like:

```shell script
gcloud container clusters get-credentials <gcloud_credentials> --region <region> --project <project_id>
```

To watch the creation of the pods (optional):

```shell script
watch -x kubectl get pods
```

Clean existing environment (if already existing) and create StatefulSet, Service. Also initiates replica set with different system parameters like chaining and architecture (PSS or PSA) as booleans:

```shell script
cd ..
./rebuild_pods.sh -c <chaining_enabled> -a <arbiter_exists>
```

----
## How to run the experiments?

```
Run pod with our ycsb image hosted @ dockerhub:

```shell script
kubectl run ycsb --rm -it --image aaugusto11/ycsb -- /bin/bash
```

Or build a local image of ycsb and run the pod:

```shell script
cd ../../

docker build -t ycsb:latest .

kubectl run ycsb --rm -it --image ycsb:latest --image-pull-policy=Never -- /bin/bash
```

Run the script to perform benchmark experiment:

```shell script
./runner.sh -w workload1 -e experiment1 -i 5 -c 1 -x throughput -m 16 -n 16 -s 1 -r 5 -W 1 -R majority -P primary
```
This will run workload1, as the experiment with id 1, perform 5 iterations, on the cloud (-c 1), from 16 to 16 client threads in increments of 1, repeating each run of the workload 5 times. Each request is being done using writeConcern w = 1 and readConcern = majority, reading from the primary.

Run the script to perform scalability experiment:

```shell script
./runner.sh -w workload1 -e experiment2 -i 1 -c 1 -x throughput -m 1 -n 100 -s 5 -r 5 -W 1 -R local -P primary
```

This will run workload1, as the experiment with id 2, perform 1 iteration, on the cloud (-c 1), from 1 to 100 client threads in increments of 5, repeating each run of the workload 5 times. Each request is being done using writeConcern w = 1 and readConcern = local, reading from the primary.

If running on the cloud, copy experiments folder from the pod to the local environment:

```shell script
kubectl cp default/ycsb:/experiments/experiment1 ./results/experiment1 -c ycsb
```

----
## Authors

**Group 01**

### Team members

| Number | Name              | User                                 | Email                                       |
| -------|-------------------|--------------------------------------|---------------------------------------------|
| 90704  | Andre Augusto     | <https://github.com/AndreAugusto11>  | <mailto:andre.augusto@tecnico.ulisboa.pt>   |
| 90744  | Lucas Vicente     | <https://github.com/WARSKELETON>     | <mailto:lucasvicente@tecnico.ulisboa.pt>    |
| 90751  | Manuel Mascarenhas    | <https://github.com/Mascarenhas12>    | <mailto:manuel.d.mascarenhas@tecnico.ulisboa.pt> |

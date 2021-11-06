# MongoDB Scalability and Performance Evaluation - ESLE

## Structure

| Module               |      Description      |
| :------------------- | :-------------------: |
| [gcp](gcp)     |  Google Cloud infrastructure module  |
| [gcp/k8s](gcp/k8s)     |  MongoDB replica set kubernetes deployment module  |
| [gcp/terraform](gcp/terraform)     |  Terraform GKE cluster module  |
| [workloads](workloads)     |  Workload modules  |
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

## 7 Factors with 2 Levels

| Factor               |      Level -1         |      Level 1         |
| :------------------- | :-------------------: | :-------------------: |
| [Replica Node Configuration (A)](#replica-node-configuration)     |  Primary-Secondary-Secondary  | Primary-Secondary-Arbiter  | 
| [Write Concern (B)](#write-concern-read-concern-read-preference)     |  Majority  | 1 Ack  |
| [Read Concern (C)](#write-concern-read-concern-read-preference)     |  1 Ack  | Majority |
| [Read Preference (D)](#write-concern-read-concern-read-preference)     |  Primary Preferred  | Secondary Preferred |
| [Chaining (E)](#chaining)     |  Disabled  | Enabled |
| [Replica Writer Thread Range (F)](#replica-writer-thread-range-replica-batch-limit)     | [0:16] Threads | [0:128] Threads |
| [Replica Batch Limit (G)](#replica-writer-thread-range-replica-batch-limit)     | 50MB | 100MB |

## Workload Struture (Example)

| Module               |      Description      |
| :------------------- | :-------------------: |
| [outputs](workloads/workload1/outputs)     |  YCSB folder output  |
| [workload](workloads/workload1/workload1) |   Workload Definition   |
| [workload.gp](workloads/workload1/workload1.gp)|    Workload GNUPLOT file   |
| [workload.pdf](workloads/workload1/workload1.pdf)     |      PDF file with plots       |
| [results-throughput.dat](workloads/workload1/results-throughput.dat)     | Insert operation latency results |
| [results-latency-insert.dat](workloads/workload1/results-latency-insert.dat)     | Insert operation latency results |
| [results-latency-read.dat](workloads/workload1/results-latency-read.dat)     | Read operation latency results |
| [results-latency-scan.dat](workloads/workload1/results-latency-scan.dat)     | Scan operation latency results |
| [results-latency-update.dat](workloads/workload1/results-latency-update.dat)     | Update operation latency results |

## How to setup a local MongoDB cluster, using Docker Swarm? _(PSS Architecture)_
In the project root folder, deploy with:

```shell script
docker-compose up -d
```

Add the servers to the /etc/hosts file using *nano*:
(in /etc/hosts)
```
(...)
127.0.0.1 mongo1
127.0.0.1 mongo2
127.0.0.1 mongo3
```

## How to switch the different factors?

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

## How to setup YCSB? _(through source)_

Install YCSB tool to the project root:

```shell script
curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz
tar xfvz ycsb-0.17.0.tar.gz
```

## How to create and run a workload? _(workload1 example)_

Setup the workload and outputs folder:

```shell script
mkdir workloads/workload1 | mkdir workloads/workload1/outputs
```

Create the workload in the folder generated previously, workloads/workload1.

Install *pymongo* python module through pip:

```shell script
pip3 install pymongo
```

Enable execute permissions to *runner-sh* and *ycsb*:

```shell script
sudo chmod +x ./runner.sh
sudo chmod +x ycsb-0.17.0/bin/ycsb
```

Then, just run our runner script with the specific workload, in the root project folder:

```shell script
./runner.sh -w workload1 -c 0 -x threads -n 100 -s 5 -r 3
```

This will run workload1, locally (-c 0), from 0 to 100 client threads in increments of 5, and will be repeating each run of the workload 3 times.

----
## How to run using GCP? _(workload1 example)_


Provision the infrastructure:

```shell script
cd gcp/terraform
terraform apply
```

Connect to the cluster by getting the command line access from GCP console, like:

```shell script
gcloud container clusters get-credentials test-kubernetes-327118-gke --region europe-west1 --project test-kubernetes-327118
```

To watch the creation of the pods (optional):

```shell script
watch -x kubectl get pods
```

Create StatefulSet and Service, and create the replica set:

```shell script
cd ../k8s

kubectl apply -f mongo.yaml

kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [ {_id: 0, host: "mongo-0.mongo:27017"}, {_id: 1, host: "mongo-1.mongo:27017"}, {_id: 2, host: "mongo-2.mongo:27017"}], settings: {chainingAllowed: false}});'

kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [ {_id: 0, host: "mongo-0.mongo:27017"}, {_id: 1, host: "mongo-1.mongo:27017"}, {_id: 2, host: "mongo-2.mongo:27017", arbiterOnly: true}], settings: {chainingAllowed: false}});'

kubectl exec mongo-0 -- mongo --eval 'rs.status();'

kubectl exec mongo-2 -- mongo --eval 'db.adminCommand( { replSetSyncFrom: "mongo-1.mongo:27017" });'

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

Run the script:

```shell script
./runner.sh -w workload1 -e experiment1 -i 5 -c 1 -x throughput -m 16 -n 16 -s 1 -r 3 -W 1 -R majority -P primaryPreferred
```

Copy Workloads folder from the pod to the local environment:

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

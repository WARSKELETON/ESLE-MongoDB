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

## How to setup a local MongoDB cluster? _(PSS Architecture)_
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

## How to setup YCSB? 

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

kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [ {_id: 0, host: "mongo-0.mongo:27017"}, {_id: 1, host: "mongo-1.mongo:27017"}, {_id: 2, host: "mongo-2.mongo:27017"}]});'
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
./runner.sh -w workload1 -c 1 -x throughput -n 12 -s 2 -r 1
```

Copy Workloads folder from the pod to the local environment:

```shell script
kubectl cp default/runner:/workloads ./results-pod -c runner
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

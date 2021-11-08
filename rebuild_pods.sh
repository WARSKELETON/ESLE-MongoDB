#!/bin/bash

while getopts a:c: flag
do
    case "${flag}" in
        a) arbiter=${OPTARG};;
        c) chaining=${OPTARG};;
    esac
done

kubectl delete -f gcp/k8s/mongo.yaml

kubectl delete pvc mongo-volume-mongo-0
kubectl delete pvc mongo-volume-mongo-1
kubectl delete pvc mongo-volume-mongo-2

kubectl apply -f gcp/k8s/mongo.yaml

pod_status0=""
pod_status1=""
pod_status2=""

echo "creating pods..."
sleep 50

while [[ "$pod_status0" == "" || "$pod_status1" == "" || "$pod_status2" == "" ]]
do
  pod_status0=$(kubectl get pods | grep "mongo-0   1/1     Running" | awk -F' ' '{print $1}')
  pod_status1=$(kubectl get pods | grep "mongo-1   1/1     Running" | awk -F' ' '{print $1}')
  pod_status2=$(kubectl get pods | grep "mongo-2   1/1     Running" | awk -F' ' '{print $1}')
done

kubectl exec mongo-0 -- mongo --eval 'rs.initiate({_id: "rs0", version: 1, members: [ {_id: 0, host: "mongo-0.mongo:27017"}, {_id: 1, host: "mongo-1.mongo:27017"}, {_id: 2, host: "mongo-2.mongo:27017", arbiterOnly: '"$arbiter"'}], settings: {chainingAllowed: '"$chaining"'}});'

echo "initiating replica set..."

if [[ "$chaining" == "true" && "$arbiter" == "false" ]];
then
  sleep 10
  kubectl exec mongo-2 -- mongo --eval 'db.adminCommand( { replSetSyncFrom: "mongo-1.mongo:27017" });'
  sleep 10
fi

kubectl exec mongo-0 -- mongo --eval 'rs.status();'

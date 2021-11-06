kubectl delete -f gcp/k8s/mongo.yaml

kubectl delete pvc mongo-volume-mongo-0
kubectl delete pvc mongo-volume-mongo-1
kubectl delete pvc mongo-volume-mongo-2

kubectl apply -f gcp/k8s/mongo.yaml


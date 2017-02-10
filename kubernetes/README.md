# Bench lab - Kubernetes POC

## Installation

### Minikube
To test the lab locally, install [minikube](https://github.com/kubernetes/minikube)

IMPORTANT: To run plf, you have to allocate more memory than the default 2Go allocated to the minikube vm
```
minikube start --memory=4096
```

## Administration components

Start the [Administration components](admin/README.md)

## Start PLF

From the ``kubernetes`` directory
```
bin/createConfigMapFromProperties plf-config pods/plf/plf-env.properties
kubectl apply -f pods/database/mysql-deployment.yml
kubectl apply -f pods/chat/chat-db-deployment.yml
kubectl apply -f pods/plf/plf-deployment.yml
```

## Stop plf

```
kubectl stop -f pods/database/mysql-deployment.yml
kubectl stop -f pods/chat/chat-db-deployment.yml
kubectl stop -f pods/plf/plf-deployment.yml
```

# TODO

- [ ] Use external ElasticSearch
- [ ] Persistent volumes
- [ ] Scripting for admin actions (start stop clean)
- [ ] Configuration options

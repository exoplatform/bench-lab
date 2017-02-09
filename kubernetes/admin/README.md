# Administration components

## Docker registry

The docker registry will be use to store the images and make them available to
the kubernetes nodes.


### Start
```
kubectl apply -f registry-volumes.yml
kubectl apply -f registry.yml
```

### Stop

```
kubectl delete -f registry.yml
```

If you want to clean the persistent volume to recover space, execute also

```
kubectl delete -f registry-volumes.yml
```

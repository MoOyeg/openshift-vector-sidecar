Simple Vector sidecar to assist applications that cannot log to stdout on their own.

While OpenShift comes with it's own logging stack based on vector, it does not support editing the default Logging stack to read application specific log files. This is a simple sidecar to help with that use case.


## Deploy on OCP
- To deploy on OCP build the sidecar image from included dockerfile
```bash
DOCKERFILE=$(cat Dockerfile)
oc new-build --name=vector-sidecar --dockerfile="${DOCKERFILE}"
```
- Patch your deployment. The sidecar requires a data directory and config file to run. See Test Example below for full example.
```bash
kubectl patch deployment my-app -n default \
  --patch '{
    "spec": {
      "template": {
        "spec": {
          "containers": [
            {
              "name": "sidecar-container",
              "image": "busybox",
              "command": ["sleep", "3600"]
            }
          ]
        }
      }
    }
  }'

```

## Test on OCP
```bash
DOCKERFILE=$(cat Dockerfile)
oc new-build --name=vector-sidecar --dockerfile="${DOCKERFILE}"
oc set image-lookup vector-sidecar
DOCKERFILE=$(cat ./Test/Dockerfile)
oc create configmap logify.sh --from-file=logify.sh=./Test/logify.sh
oc new-build --name=log-gen --build-config-map=logify.sh --dockerfile="${DOCKERFILE}"
oc create configmap vector.yaml --from-file=vector.yaml=./Test/vector.yaml
oc new-app --image-stream=log-gen

oc set image-lookup deploy/log-gen
kubectl patch deployment log-gen \
  --patch '{
    "spec": {
      "template": {
        "spec": {
          "containers": [
            {
              "name": "vector-sidecar",
              "image": "vector-sidecar:latest",
              "imagePullPolicy": "Always"
            }
          ]
        }
      }
    }
  }'

oc set volume deploy/log-gen --add --name=logs -t emptydir --claim-size=100Mi --mount-path=/vector-logs
oc set volume deploy/log-gen --add --name=data-dir -t emptydir --claim-size=100Mi --mount-path=/vector-data-dir
oc set volume deploy/log-gen --add --name=vector-yaml  --configmap-name=vector.yaml -t configmap --mount-path=/vector-config
```

If it's working what you get from
```bash
oc exec deploy/log-gen -- cat /vector-logs/logify.log
```
should be equal to
```bash
oc logs deploy/log-gen
```

## Test Locally with Podman

```bash
podman build . -t vector-sidecar:latest
podman build -f ./Test/Dockerfile -t logify_test:latest
test_log_dir=$(mktemp -d)
test_data_dir=$(mktemp -d)
vector_config="$(pwd)/Test/vector.yaml"

podman pod create --name vector-test \
--volume=${test_log_dir}:/vector-logs:z \
--volume=${vector_config}:/vector-config/vector.yaml:z \
--volume=${test_data_dir}:/vector-data-dir:z

podman run -d --replace --name log_gen \
--pod vector-test localhost/logify_test:latest
podman run -d --replace --name vector-sidecar --pod vector-test localhost/vector-sidecar:latest
```

If it's working what you get from 
```bash
podman exec -w /vector-logs log_gen cat logify.log
```
should be equal to
```bash
podman logs vector-sidecar
```

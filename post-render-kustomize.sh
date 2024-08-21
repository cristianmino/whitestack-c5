#!/bin/bash

# Verificar que la variable NODE_NAME esté definida
if [ -z "$NODE_NAME" ]; then
  echo "Error: La variable de entorno NODE_NAME no está definida." >&2
  exit 1
fi

# Leer la entrada del manifiesto
input=$(cat)

# Convertir el input en un archivo temporal para su manipulación
echo "$input" > tmp/manifests.yaml

yq e '. | select(.kind == "Deployment") ' tmp/manifests.yaml > tmp/deployment.yaml
yq e -i '
.spec.template.spec.affinity = {
  "nodeAffinity": {
    "preferredDuringSchedulingIgnoredDuringExecution": [
      {
        "weight": 1,
        "preference": {
          "matchExpressions": [
            {
              "key": "kubernetes.io/hostname",
              "operator": "In",
              "values": ["'"$NODE_NAME"'"]
            }
          ]
        }
      }
    ]
  }
}' tmp/deployment.yaml


kustomize build . > tmp/all.yaml
cat tmp/all.yaml
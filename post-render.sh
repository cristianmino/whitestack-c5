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

# Se agrega a todos los manifiestos (deployment, services, etc) pero no importa ya que solo se aplica a los deployments
# Otra opcion es usar kustomize para aplicar el parche solo a los deployments
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
}' tmp/manifests.yaml

cat tmp/manifests.yaml
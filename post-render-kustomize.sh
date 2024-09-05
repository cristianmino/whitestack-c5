#!/bin/bash

# Verificar que la variable NODE_NAME esté definida
if [ -z "$NODE_NAME" ]; then
  echo "Error: La variable de entorno NODE_NAME no está definida." >&2
  exit 1
fi

# TMP_DIR=tmp

# Leer la entrada del manifiesto
input=$(cat)

# Convertir el input en un archivo temporal para su manipulación
echo "$input" > $TMP_DIR/rendered.yaml

yq e '. | select(.kind == "Deployment") ' $TMP_DIR/rendered.yaml > $TMP_DIR/template.yaml
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
}' $TMP_DIR/template.yaml

kustomization_content=$(cat <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- rendered.yaml
patches:
- path: template.yaml
EOF
)
echo "$kustomization_content" > $TMP_DIR/kustomization.yaml

kustomize build $TMP_DIR/ > $TMP_DIR/all.yaml

cat $TMP_DIR/all.yaml
rm -rf $TMP_DIR/template.yaml $TMP_DIR/all.yaml $TMP_DIR/kustomization.yaml
#!/bin/bash

show_help() {
    echo "Uso: helm install-with-validation <nombre-del-release> <nombre-del-chart> <nombre-namespace> [opciones-de-helm]"
    echo ""
    echo "Este plugin valida los valores sensibles en el archivo values.yaml antes de proceder"
    echo "con la instalación o actualización del chart. Los valores sensibles son aquellos cuyas"
    echo "llaves contienen '*password', '*pwd', '*pass' o '*credentials'."
    echo ""
    echo "Validaciones de los valores sensibles:"
    echo "  a. Longitud mínima del password: 8 caracteres."
    echo "  b. Al menos una letra en mayúscula."
    echo "  c. Al menos una letra en minúscula."
    echo "  d. Al menos un dígito."
    echo "  e. Al menos un caracter especial."
    echo ""
    echo "Si alguna de estas validaciones no es exitosa, el plugin termina su ejecución y el chart"
    echo "no se instala ni se actualiza. Se muestra el resultado de la validación."
    echo ""
    echo "Migración de valores sensibles a Kubernetes Secrets:"
    echo "  En lugar de mapear directamente el valor del password en los templates de statefulset,"
    echo "  deployment o daemonset, se crea un secret y se llama al valor del secret como variable"
    echo "  de entorno. La información sensible se elimina de los manifests de los pods y solo se"
    echo "  usan los valores alojados en el secret creado previamente."
    echo ""
    echo "Opciones:"
    echo "  --help        Muestra esta ayuda."
    echo ""
    echo "Ejemplos:"
    echo "  helm install-with-validation onim-release onim-chart/onim challenger-008 -f values.yaml"
}

if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Verificar si se proporcionó el nombre del release y el chart
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Debes proporcionar el nombre del release, nombre del chart"
  echo "Uso: helm install-with-validation <nombre-del-release> <nombre-del-chart> <nombre-namespace> [opciones-de-helm]"
  exit 1
fi


# TMP_DIR=tmp

RELEASE_NAME=$1
CHART_PATH=$2
NAMESPACE=${3:-default}
shift 3


# Verificar si el chart existe
helm show chart "$CHART_PATH" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: El chart '$CHART_PATH' no existe. Por favor, verifica el nombre del chart."
  echo "Uso: helm install-with-validation <release-name> <chart-path> [opciones-de-helm]"
  exit 1
fi

# Generar un manifiesto renderizado que combine los values con los --set y -f adicionales
RENDERED_VALUES=$(helm template "$RELEASE_NAME" "$CHART_PATH" "$@")
echo "$RENDERED_VALUES" > $TMP_DIR/rendered.yaml

sensitive_keys=$(yq e '.. | select(. == "*assword*" or . == "*pwd" or . == "*credential*" or . == "*pass") | path | join(".")' $TMP_DIR/rendered.yaml)

# Validar cada valor sensible
for key in $sensitive_keys; do
  name=$(yq e "select(.kind == \"Deployment\" or .kind == \"StatefulSets\" or .kind == \"DaemonSet\") | .${key}" $TMP_DIR/rendered.yaml)
  key=$(echo "$key" | sed 's/name/value/')
  value=$(yq e "select(.kind == \"Deployment\" or .kind == \"StatefulSets\" or .kind == \"DaemonSet\") | .${key}" $TMP_DIR/rendered.yaml)
  if [[ ${#value} -lt 8 || ! "$value" =~ [A-Z] || ! "$value" =~ [a-z] || ! "$value" =~ [0-9] || ! "$value" =~ [@#$%^_+~\&\*\!\=\.-] ]]; then
    # echo "key: "$key "value: "$value "name: "$name
    echo "Error: El valor de $name no cumple con las reglas de seguridad."
    echo "Debe tener al menos 8 caracteres, incluir una letra mayúscula, una minúscula, un dígito y un carácter especial."
    exit 1
  fi
done

echo "Validación completada. Todos los valores sensibles cumplen con las reglas de seguridad."

# Continuar con la creación de Secrets
echo "Migrando los valores sensibles a Kubernetes Secrets..."

# Crear un Secret en un archivo separado
cat <<SECRET_EOF > $TMP_DIR/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: sensitive-values-secret
type: Opaque
data:
SECRET_EOF

for key in $sensitive_keys; do
  name=$(yq e "select(.kind == \"Deployment\" or .kind == \"StatefulSets\" or .kind == \"DaemonSet\") | .${key}" $TMP_DIR/rendered.yaml)
  key=$(echo "$key" | sed 's/name/value/')
  value=$(yq e "select(.kind == \"Deployment\" or .kind == \"StatefulSets\" or .kind == \"DaemonSet\") | .${key}" $TMP_DIR/rendered.yaml)
  encoded_value=$(echo -n "$value" | base64)
  echo "  $name: $encoded_value" >> $TMP_DIR/secret.yaml
  key_path=$(echo "$key" | sed 's/.value//')
  echo "name: $name value: $value key: $key key_path: $key_path"
  # yq e -i "select(.kind == \"Deployment\" or .kind == \"StatefulSets\" or .kind == \"DaemonSet\") |
  yq e -i "
  .${key_path} = 
    {
      \"name\": \"${name}\",
      \"valueFrom\": {
        \"secretKeyRef\": {
          \"name\": \"sensitive-values-secret\",
          \"key\": \"${name}\"
        }
      }
    }
  
" $TMP_DIR/rendered.yaml
done

echo "Manifiestos actualizados para usar Kubernetes Secrets."

cat $TMP_DIR/rendered.yaml <(echo -e "\n---\n") $TMP_DIR/secret.yaml > $TMP_DIR/combined.yaml


cat <<EOF > $TMP_DIR/post-renderer.sh
#!/bin/bash
cat $TMP_DIR/combined.yaml
EOF
chmod +x $TMP_DIR/post-renderer.sh

helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" -n "$NAMESPACE" --post-renderer $TMP_DIR/post-renderer.sh


rm -rf $TMP_DIR/rendered.yaml $TMP_DIR/secret.yaml $TMP_DIR/combined.yaml $TMP_DIR/post-renderer.sh
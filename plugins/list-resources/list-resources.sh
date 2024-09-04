#!/bin/bash

show_help() {
    echo "Uso: helm list-resources <nombre-del-release> <nombre-del-chart> [opciones-de-helm]"
    echo ""
    echo "Este plugin revisa los resources requests de CPU y Memoria que van a ser"
    echo "utilizados por los pods de tu aplicación. Es útil para asegurarse de que"
    echo "los recursos solicitados sean adecuados y no excedan los límites."
    echo ""
    echo "Opciones:"
    echo "  --help        Muestra esta ayuda."
    echo ""
    echo "Ejemplos:"
    echo "  helm list-resources onim-release onim-chart/onim -f values.yaml"
}

if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi



# Verificar si se proporcionó un nombre de chart
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Debes proporcionar el nombre del release y el nombre de un chart."
  echo "Uso: helm list-resources <nombre-del-release> <nombre-del-chart> [opciones-de-helm]"
  exit 1
fi

RELEASE_NAME=$1
CHART_PATH=$2
shift 2

# Verificar si el chart existe
helm show chart "$CHART_PATH" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: El chart '$CHART_PATH' no existe. Por favor, verifica el nombre del chart."
  echo "Uso: helm list-resources <nombre-del-release> <nombre-del-chart>"
  exit 1
fi

cpu_requests=$(helm template "$RELEASE_NAME" "$CHART_PATH" "$@" | yq e '.. | select(has("resources")) | .resources.requests.cpu')
memory_requests=$(helm template "$RELEASE_NAME" "$CHART_PATH" "$@" | yq e '.. | select(has("resources")) | .resources.requests.memory')

replicas=$(helm template "$RELEASE_NAME" "$CHART_PATH" "$@" | yq e '. | select(.kind == "Deployment") | .spec.replicas')

total_cpu=0
total_memory=0

for cpu in $cpu_requests; do
  if [[ "$cpu" == *m ]]; then
    cpu=${cpu%m}
    total_cpu=$((total_cpu + cpu))
  else
    total_cpu=$((total_cpu + (cpu * 1000)))
  fi
done

for memory in $memory_requests; do
  if [[ "$memory" == *Mi ]]; then
    memory=${memory%Mi}
    total_memory=$((total_memory + memory))
  else
    total_memory=$((total_memory + (memory / 1024)))
  fi
done

if [[ -n "$replicas" ]]; then
  total_cpu=$((total_cpu * replicas))
  total_memory=$((total_memory * replicas))
fi


total_cpu_cores=$(bc <<< "scale=3; $total_cpu / 1000")
total_memory_mi=$(bc <<< "scale=0; $total_memory")

echo "Total de CPU requests: ${total_cpu_cores} cores"
echo "Total de Memory requests: ${total_memory_mi} Mi"
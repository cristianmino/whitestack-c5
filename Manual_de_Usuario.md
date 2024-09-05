
# Manual de Usuario

Este manual proporciona instrucciones para ejecutar los desafíos utilizando Helm con el repositorio de charts Onim.

## Agregar el Repositorio de Charts Onim

Antes de comenzar con los desafíos, agrega el repositorio de charts Onim ejecutando el siguiente comando:

```bash
helm repo add onim-chart https://cristianmino.github.io/helm-chart-basic/
```
## Instalar Herramientas

- yq -> https://github.com/mikefarah/yq/#install
- kustomize -> https://github.com/kubernetes-sigs/kustomize

## Instalar plugins

```bash
export HELM_PLUGIN_DIR=$(helm home)/plugins
mkdir -p $HELM_PLUGIN_DIR
export TMP_DIR=$(mktemp -d)
cd plugins/list-resources
helm plugin install .
cd plugins/install-with-validation 
helm plugin install .
```
## Desafío 1

Para desplegar el chart en un nodo específico con Post Rendering, utiliza el siguiente comando:

```bash
export NODE_NAME=<nombre-del-nodo>
helm install onim-release -n challenger-008 onim-chart/onim --post-renderer ./post-render-kustomize.sh
```

## Desafío 2

Para listar las solicitudes de recursos de CPU y Memoria de un chart de Helm, usa el siguiente comando:

```bash
helm list-resources onim-release onim-chart/onim -f values.yaml
```

## Desafío 3

Para instalar el chart con validación de información sensible, usa el siguiente comando:

```bash
helm install-with-validation onim-release onim-chart/onim challenger-008 -f values.yaml
```

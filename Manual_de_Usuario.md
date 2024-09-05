
# Manual de Usuario

Este manual proporciona instrucciones para ejecutar los desafíos utilizando Helm con el repositorio de charts Onim.

## Agregar el Repositorio de Charts Onim

Antes de comenzar con los desafíos, agrega el repositorio de charts Onim ejecutando el siguiente comando:

```bash
helm repo add onim-chart https://cristianmino.github.io/helm-chart-basic/
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

# Whitestack Challenge #5

Este repositorio contiene la solución al Whitestack Challenge #5, donde se implementan diversas funcionalidades utilizando Helm, `yq`, y Kuztomize.

## Contenidos

- [Whitestack Challenge #5](#whitestack-challenge-5)
  - [Contenidos](#contenidos)
  - [Requisitos Previos](#requisitos-previos)
  - [Desafíos](#desafíos)
    - [1. Despliegue en un nodo específico con Post Rendering](#1-despliegue-en-un-nodo-específico-con-post-rendering)
      - [Uso:](#uso)
      - [Decisiones de diseño:](#decisiones-de-diseño)
    - [2. Crear un Helm Plugin para listar resources requests de CPU y Memoria](#2-crear-un-helm-plugin-para-listar-resources-requests-de-cpu-y-memoria)
      - [Uso:](#uso-1)
    - [3. Crear Helm Plugin para validación y configuración de información sensible](#3-crear-helm-plugin-para-validación-y-configuración-de-información-sensible)
  - [Problemas Encontrados](#problemas-encontrados)

## Requisitos Previos

Antes de comenzar, asegúrate de tener las siguientes herramientas instaladas en tu entorno:

- Kubernetes (con acceso al clúster provisto por Whitestack o un entorno propio)
- Helm (v3.x o superior)
- Bash
- `yq` (v4.x o superior)
- Kustomize (opcional, si no está integrado en `kubectl`)

## Desafíos

### 1. Despliegue en un nodo específico con Post Rendering

Este desafío consistió en utilizar la funcionalidad de Post Rendering en Helm para garantizar que todos los pods se desplegaran en un nodo específico del clúster utilizando Node Affinity, sin usar `nodeSelector` ni `nodeName`.

El script [`post-render-kustomize.sh`](scripts/post-render-kustomize.sh) realiza lo siguiente:

- Verifica que la variable de entorno `NODE_NAME` esté definida (cabe indicar que NODE_NAME corresponde solo al nombre del nodo donde queremos desplegar).
- Modifica el manifiesto YAML para agregar `nodeAffinity` utilizando `yq`.
- Aplica los cambios a través de Kustomize para realizar el despliegue.

#### Uso:

```bash
export NODE_NAME=<nombre-del-nodo>
helm install onim-release -n challenger-008 onim-chart/onim --post-renderer ./post-render-kustomize.sh
```
#### Decisiones de diseño:
La forma mas eficiente de completar el desafio fue utilizando las herramientas yq y kustomize, ya que con yq se puede modificar el archivo de despliegue de forma sencilla y con kustomize se puede aplicar el cambio sin perder información del archivo original.

### 2. Crear un Helm Plugin para listar resources requests de CPU y Memoria

Este desafío consistió en crear un plugin de Helm que permita listar los recursos solicitados de CPU y Memoria de un chart de Helm.

De igual forma, se creó el plugin con bash utilizando `yq` para extraer la información de los recursos solicitados de CPU y Memoria de un chart de Helm.

Cabe indicar que el plugin solo valida los recursos solicitados de CPU y Memoria, no realizar ninguna instalación o despliegue.

El script list-resources.sh realiza lo siguiente:
- Renderiza el chart utilizando helm template.
- Utiliza yq para extraer las solicitudes de recursos de CPU y memoria.
- Calcula el total de recursos solicitados y lo muestra.

#### Uso:
    
```bash
helm list-resources onim-release onim-chart/onim -f values.yaml
```

### 3. Crear Helm Plugin para validación y configuración de información sensible

Este desafío consistió en crear un plugin de Helm que permita validar y configurar información sensible en un chart de Helm.

Consta de dos partes:
1. Validación: Verificar que los valores de un archivo `values.yaml` no contengan información sensible. El plugin valida que los passwords cumplan con las siguientes reglas:
   - Longitud mínima de 8 caracteres.
   - Al menos una letra en mayúscula.
   - Al menos una letra en minúscula.
   - Al menos un dígito.
   - Al menos un carácter especial.

    Si alguna validación falla, el chart no se instala ni se actualiza

    Para realizar la validación primero se buscó en todas las keys del template de helm los valores que contienen una palabra sencible y luego se valido que cumplan con las reglas mencionadas anteriormente por medio de expresiones regulares.
    ```bash
    yq e '.. | select(. == "*assword*" or . == "*pwd" or . == "*credential*" or . == "*pass") | path | join(".")'
    ```
    Un punto importante es que se utilizo la herramienta yq para buscar los valores sensibles en el archivo values.yaml, ya que esta herramienta permite buscar valores en un archivo yaml de forma sencilla.
2. Configuración: Si la validación es exitosa, el plugin migra los valores sensibles a Kubernetes Secrets y los inserta en el template dentro de la sección env. Para actualizar las variables de entorno (env) y que estas apunten a los Secrets, se utilizó la herramienta yq, modificando los paths correspondientes en el manifiesto. Esto se realizó tomando en cuenta que los valores sensibles ya habían sido creados como Secrets previamente.

   En base al ejemplo que nos compartieron, se decidió que la forma de manejar los secretos y variables de entorno fue la siguiente:
   ```yaml
   llave: valor
   ```
   Donde la llave es el nombre de la variable de entorno y el value es la llave del secret (sensitive-values-secret) que contiene el valor de la variable de entorno.
   ```yaml
    env:
      - name: KEY
        valueFrom:
          secretKeyRef:
            name: sensitive-values-secret
            key: KEY
    ```
   

#### Uso:
    
```bash
helm install-with-validation <nombre-del-release> <nombre-del-chart> <nombre-namespace> [opciones-de-helm]

#Ejemplo:
helm install-with-validation onim-release onim-chart/onim challenger-008 -f values.yaml
```
## Problemas Encontrados
  - Compatibilidad con yq: La versión 4 de yq tiene diferencias significativas con versiones anteriores, por lo que fue necesario ajustar los comandos para asegurar compatibilidad con la sintaxis más reciente.
  - Configuración de Secrets: Migrar los valores de las credenciales a Secrets de Kubernetes requirió modificar dinámicamente los templates para referenciar los Secrets de forma segura.
  - Validación de Contraseñas: La validación de contraseñas requirió el uso de expresiones regulares para garantizar que los valores cumplieran con los requisitos de seguridad.
  - Instalación del chart posterior a la modificaciones: Se tuvo que modificar el script para que se instalara el chart una vez que se hubieran realizado las modificaciones necesarias. Esto con ayuda de post-renderer de helm.

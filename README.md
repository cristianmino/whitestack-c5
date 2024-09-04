echo "# whitestack-c5" >> README.md


--- 02
export NODE_NAME=node001
helm repo add onim-chart https://cristianmino.github.io/helm-chart-basic/
helm install onim-release -n challenger-008 onim-chart/onim --post-renderer ./post-render-kustomize.sh

mkdir 
export HELM_PLUGINS=~/.helm/plugins

helm plugin install .
helm list-resources onim-chart/onim
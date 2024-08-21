echo "# whitestack-c5" >> README.md

helm repo add onim-chart https://cristianmino.github.io/helm-chart-basic/

helm install onim-release -n challenger-008 onim-chart/onim --post-renderer ./post-render-kustomize.sh
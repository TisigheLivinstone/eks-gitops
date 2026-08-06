#!/bin/bash
set -e

echo "Installing Argo CD Image Updater..."
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

echo "Waiting for Image Updater to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-image-updater \
  -n argocd --timeout=120s

echo "Image Updater installed:"
kubectl get pods -n argocd | grep image-updater

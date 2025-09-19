# Agent install

This directory contains Kubernetes and OLM resources to deploy the IBM ACE Dashboard and agent.  
It includes manifests for the operator, dashboard, services, and related configuration.

## Directory layout

agent-install/
olm/                        # OLM resources for ACE operator and dashboard
catalogsource.yaml
operatorgroup.yaml
subscription.yaml
ace-dash-deployment-patch.yaml
ace-dashboard.yaml
ace-dashboard-debug-patch.yaml
ace-dashboard-ingress.yaml
ace-dashboard-pvc.yaml
ace-dashboard-svc.yaml
ace-operator-values.yaml
clusterissuer.yaml
dashboard-pod-cert.yaml
debug-log.yaml
ingress.yaml
ir01-ingress.yaml
patch-owner-ref.json
readme.md                   # this file

## Requirements

- Kubernetes cluster with OLM installed
- kubectl and (optionally) helm for managing resources
- Access to IBM ACE agent and dashboard images
- Acceptance of the IBM license terms

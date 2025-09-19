# Runtime optimize

This folder contains examples for optimizing the startup of IBM ACE containers.  
It includes three different approaches:

- **base**: ACE base image with a script to manually deploy, optimize, and start the server
- **prebaked**: image where deploy, optimize, and first start happen during build
- **init-container**: Kubernetes setup with an init container that prepares the runtime before the main container starts

## Structure

```
runtime-optimize/
    base/                 
        bars/             # BAR files to deploy
        config/           # ACE server configuration files
        licenses/         # License acceptance files
        scripts/          # Helper scripts (e.g. start.sh)
        sources/          # ACE source artifacts to be supplied by you
        Dockerfile
    init/
        bars/             # BAR files to deploy
        config/           # ACE server configuration files
        licenses/         # License acceptance files
        scripts/          # Helper scripts (e.g. warmup.sh)
        sources/          # ACE source artifacts to be supplied by you
        deployment-init.yaml   # Kubernetes Deployment and Service definition
        Dockerfile    
    prebaked/             
        bars/             # BAR files to bake into the image
        config/           # ACE server configuration files
        licenses/         # License acceptance files
        scripts/          # Helper scripts (e.g. warmup.sh)
        sources/          # ACE source artifacts to be supplied by you
        deployment-prebaked.yaml  # Kubernetes Deployment and Service definition
        Dockerfile    
```

## Requirements

This repo does not include the IBM ACE image or source.  
You need to supply these yourself:

- **ACE source**: either the IBM ACE 13 image from the IBM registry, or the free developer edition from IBM
- **source directory**: your own BAR files, applications, libraries, or schemas if you want to test with custom content  

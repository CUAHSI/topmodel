# Building and Running a Docker Image for a Specific TOPMODEL Use Case in R

### Clone the repo, checkout this branch
```console
git clone https://github.com/CUAHSI/topmodel.git
cd topmodel
git checkout docker
```

### Build the Docker Image
```console
docker build -f docker/Dockerfile -t topmodel-r .
```

### Run the Docker Container
```console
docker run --rm topmodel-r

```

### Docker shell commands
```console
docker run -it topmodel-r /bin/bash

```
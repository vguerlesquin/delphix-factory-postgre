# delphix-factory-postgre
A docker container to manage PostgreSQL Database on a Delphix Engine

## Purpose
In this container you have everything to create a PostgreSQL Virtual Database using a Delphix Engine.
This container embed Alan Bitterman scripts to manipulate Delphix Engine.

### Prerequisite
- Delphix Engine up and running
- At least ONE Environment with PostgreSQL 10, connected to Delphix Engine
- A source database configured in Delphix

## Usage
The purpose of this docker container is to be used into a build pipeline (e.g. in Jenkins) but it can also be run on its own.
When starting the container, you should provide `DELPHIX_IP`, `DELPHIX_USERNAME` and `DELPHIX_PASSWORD` as environment variables for the container.

Avaiblable commands are:
- `provision_postgres131.sh` : Delphix API for Provisioning a Postgres DB (Specific for PostgreSQL)
- `vdb_init.sh` : Delphix API calls to change the state of VDB's (generic)
- `vdb_operations.sh` : API calls to perform basic operations on a VDB (generic)
Description of these commands are available in README_APIS.txt file and specific scripts comments as provided by Alan Bitterman. All these command are in the PATH.

Here is an example of using the container into a Jenkinsfile:

```
...

stage("Get Delphix Factory") {
  steps {
    sh "docker pull ventury/delphix-factory-postgre:latest"
  }
}

...

stage("Create virtual database using Delphix") {
  steps {
    script {
      docker.image('ventury/delphix-factory-postgre:latest').inside("-u root -e DELPHIX_IP=${config.DELPHIX_IP} -e DELPHIX_USERNAME=${config.DELPHIX_USERNAME} -e DELPHIX_PASSWORD=${config.DELPHIX_PASSWORD}") {
        sh "provision_postgres131.sh [source_db] [vdb_name] [vdb_group] [target_host] [repository] [vdb_mount_path] [vdb_port]
      }
    }
  }
}

...

// Later in your pipeline, you may need to delete the database

docker.image('ventury/delphix-factory').inside("-u root -e DELPHIX_IP=${config.DELPHIX_IP} -e DELPHIX_USERNAME=${config.DELPHIX_USERNAME} -e DELPHIX_PASSWORD=${config.DELPHIX_PASSWORD}") {
  sh "vdb_init.sh delete [vdb_name]"
}

...

```

#!/bin/bash

# Copyright (C) 2022 Georgia Tech Center for Experimental Research in Computer
# Systems

# This script runs microbenchmarks of BuzzBlog microservice functions.

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Process command-line arguments.
client_node=""
set -u
while [[ $# > 1 ]]; do
  case $1 in
    --microservice )
      microservice=$2
      ;;
    --username )
      username=$2
      ;;
    --server_node )
      server_node=$2
      ;;
    --client_node )
      client_node=$2
      ;;
    * )
      echo "Invalid argument: $1"
      exit 1
  esac
  shift
  shift
done

# Set `server_port` and `db_port` variables.
if [ "$microservice" = "account" ]; then
  server_port=9090
  db_port=5433
elif [ "$microservice" = "follow" ]; then
  server_port=9091
  db_port=""
elif [ "$microservice" = "like" ]; then
  server_port=9092
  db_port=""
elif [ "$microservice" = "post" ]; then
  server_port=9093
  db_port=5434
elif [ "$microservice" = "uniquepair" ]; then
  server_port=9094
  db_port=5435
fi

# Set `microbenchmark_type` and `server_options` variables.
if [[ "$client_node" != "" ]]; then
  microbenchmark_type="client"
  server_options="--detach"
else
  microbenchmark_type="server"
  server_options=""
fi

# Set `server_host` variable.
if [[ "$client_node" != "$server_node" ]]; then
  server_host=${server_node}
else
  server_host=172.17.0.1
fi

ssh -o StrictHostKeyChecking=no ${username}@${server_node} "
  # Synchronize package index files from their sources.
  sudo apt-get update

  # Install Docker.
  sudo apt-get update
  sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent \
      software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\"
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # Install Thrift compiler.
  sudo apt-get -y install thrift-compiler

  # Install psql.
  sudo apt-get -y install postgresql-client-common postgresql-client-12

  # Clone BuzzBlogMicrobenchmark repository (version 1.0).
  rm -rf BuzzBlogMicrobenchmark
  git clone --branch v1.0 https://github.com/rodrigoalveslima/BuzzBlogMicrobenchmark.git

  # Clone BuzzBlog repository (version 1.1).
  rm -rf BuzzBlog
  git clone --branch v1.1 https://github.com/rodrigoalveslima/BuzzBlog.git

  # Apply patches to microbenchmark functions.
  patch BuzzBlog/app/common/include/utils.h BuzzBlogMicrobenchmark/patches/common/utils.h.diff
  patch BuzzBlog/app/${microservice}/service/server/src/${microservice}_server.cpp BuzzBlogMicrobenchmark/patches/${microservice}/${microservice}_server.cpp.diff
  patch BuzzBlog/app/${microservice}/service/server/Dockerfile BuzzBlogMicrobenchmark/patches/${microservice}/Dockerfile.diff

  # Change to the BuzzBlog directory.
  cd BuzzBlog

  # Clean Docker artifacts.
  sudo utils/clean_docker.sh

  # Generate Thrift code and copy service client libraries.
  utils/generate_and_copy_code.sh

  # Deploy database.
  if echo \"account post uniquepair\" | grep -w -q ${microservice}; then
    sudo docker volume create pg_${microservice}
    sudo docker run \
        --name ${microservice}_database \
        --publish ${db_port}:5432 \
        --volume pg_${microservice}:/var/lib/postgresql/data \
        --env POSTGRES_USER=postgres \
        --env POSTGRES_PASSWORD=postgres \
        --env POSTGRES_DB=${microservice} \
        --env POSTGRES_HOST_AUTH_METHOD=trust \
        --detach \
        postgres:13.1 \
        -c max_connections=16
    sleep 4
    psql -U postgres -d ${microservice} -h localhost -p ${db_port} -f app/${microservice}/database/${microservice}_schema.sql
  fi

  # Deploy microservice.
  if echo \"uniquepair\" | grep -w -q ${microservice}; then
    cd app/${microservice}/service/server
    sudo docker build -t ${microservice}:latest .
    cd ../../../..
    sudo docker run \
        --name ${microservice}_service \
        --publish ${server_port}:${server_port} \
        --env port=${server_port} \
        --env threads=1 \
        --env accept_backlog=1 \
        --env backend_filepath=/etc/opt/BuzzBlog/backend.yml \
        --env postgres_connection_pool_min_size=1 \
        --env postgres_connection_pool_max_size=1 \
        --env postgres_connection_pool_allow_ephemeral=0 \
        --env postgres_user=postgres \
        --env postgres_password=postgres \
        --env logging=0 \
        --env microbenchmark_type=${microbenchmark_type} \
        --volume \$(pwd)/conf/backend.yml:/etc/opt/BuzzBlog/backend.yml \
        ${server_options} ${microservice}:latest
  fi
  if echo \"account post\" | grep -w -q ${microservice}; then
    cd app/${microservice}/service/server
    sudo docker build -t ${microservice}:latest .
    cd ../../../..
    sudo docker run \
        --name ${microservice}_service \
        --publish ${server_port}:${server_port} \
        --env port=${server_port} \
        --env threads=1 \
        --env accept_backlog=1 \
        --env backend_filepath=/etc/opt/BuzzBlog/backend.yml \
        --env microservice_connection_pool_min_size=1 \
        --env microservice_connection_pool_max_size=1 \
        --env microservice_connection_pool_allow_ephemeral=0 \
        --env postgres_connection_pool_min_size=1 \
        --env postgres_connection_pool_max_size=1 \
        --env postgres_connection_pool_allow_ephemeral=0 \
        --env postgres_user=postgres \
        --env postgres_password=postgres \
        --env logging=0 \
        --env microbenchmark_type=${microbenchmark_type} \
        --volume \$(pwd)/conf/backend.yml:/etc/opt/BuzzBlog/backend.yml \
        ${server_options} ${microservice}:latest
  fi
  if echo \"follow like\" | grep -w -q ${microservice}; then
    cd app/${microservice}/service/server
    sudo docker build -t ${microservice}:latest .
    cd ../../../..
    sudo docker run \
        --name ${microservice}_service \
        --publish ${server_port}:${server_port} \
        --env port=${server_port} \
        --env threads=1 \
        --env accept_backlog=1 \
        --env backend_filepath=/etc/opt/BuzzBlog/backend.yml \
        --env microservice_connection_pool_min_size=1 \
        --env microservice_connection_pool_max_size=1 \
        --env microservice_connection_pool_allow_ephemeral=0 \
        --env logging=0 \
        --env microbenchmark_type=${microbenchmark_type} \
        --volume \$(pwd)/conf/backend.yml:/etc/opt/BuzzBlog/backend.yml \
        ${server_options} ${microservice}:latest
  fi

  # Change to the parent directory.
  cd ..

  if [[ \"$client_node\" == \"\" ]]; then
    # Copy execution logs.
    mkdir -p results/${microservice}
    sudo docker cp ${microservice}_service:/opt/BuzzBlog/app/${microservice}/service/server/logs/. results/${microservice}
  fi
"

if [[ "$client_node" != "" ]]; then
  ssh -o StrictHostKeyChecking=no ${username}@${server_node} "
    if [[ "$client_node" != "$server_node" ]]; then
      # Synchronize package index files from their sources.
      sudo apt-get update

      # Install Docker.
      sudo apt-get update
      sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent \
          software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\"
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io

      # Install Thrift compiler.
      sudo apt-get -y install thrift-compiler

      # Clone BuzzBlogMicrobenchmark repository (version 1.0).
      rm -rf BuzzBlogMicrobenchmark
      git clone --branch v1.0 https://github.com/rodrigoalveslima/BuzzBlogMicrobenchmark.git

      # Clone BuzzBlog repository (version 1.1).
      rm -rf BuzzBlog
      git clone --branch v1.1 https://github.com/rodrigoalveslima/BuzzBlog.git
    fi

    # Apply patches to microbenchmark functions.
    patch BuzzBlog/app/common/include/microservice_connected_server.h BuzzBlogMicrobenchmark/patches/common/microservice_connected_server.h.diff

    # Change to the BuzzBlog directory.
    cd BuzzBlog

    if [[ "$client_node" != "$server_node" ]]; then
      # Clean Docker artifacts.
      utils/clean_docker.sh
    fi

    # Generate Thrift code and copy service client libraries.
    utils/generate_and_copy_code.sh

    # Copy dependencies to client directory.
    cp -R app/${microservice}/service/server/include ../BuzzBlogMicrobenchmark/client/${microservice}/

    # Change to the BuzzBlogMicrobenchmark directory.
    cd ../BuzzBlogMicrobenchmark

    # Deploy client.
    cd client/${microservice}
    sudo docker build -t ${microservice}_client:latest .
    sudo docker run \
        --name ${microservice}_client \
        --env host=${server_host} \
        --env port=${server_port} \
        ${microservice}_client:latest
    cd ../..

    # Change to the parent directory.
    cd ..

    # Copy execution logs.
    mkdir -p results/${microservice}
    sudo docker cp ${microservice}_client:/opt/BuzzBlog/${microservice}/logs/. results/${microservice}
  "
fi

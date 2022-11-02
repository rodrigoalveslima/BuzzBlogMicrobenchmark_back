#!/bin/bash

# Copyright (C) 2022 Georgia Tech Center for Experimental Research in Computer
# Systems

# This script runs all microbenchmarks of BuzzBlog microservice functions.

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Process command-line arguments.
set -u
while [[ $# > 1 ]]; do
  case $1 in
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

# Run server microbenchmarks.
for microservice in account follow like post uniquepair; do
  ./utils/run_microbenchmarks.sh --microservice ${microservice} --username ${username} --server_node ${server_node}
done

# Run local client microbenchmarks.
for microservice in account follow like post uniquepair; do
  ./utils/run_microbenchmarks.sh --microservice ${microservice} --username ${username} --server_node ${server_node} --client_node ${server_node}
done

# Run remote client microbenchmarks.
for microservice in account follow like post uniquepair; do
  ./utils/run_microbenchmarks.sh --microservice ${microservice} --username ${username} --server_node ${server_node} --client_node ${client_node}
done

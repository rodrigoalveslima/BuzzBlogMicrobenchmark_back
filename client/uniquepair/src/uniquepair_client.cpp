// Copyright (C) 2022 Georgia Tech Center for Experimental Research in Computer
// Systems

#include <buzzblog/microservice_connected_server.h>

#include <cxxopts.hpp>
#include <cppbench.h>
#include <fstream>
#include <iostream>

int main(int argc, char** argv) {
  // Define command-line parameters.
  cxxopts::Options options("client", "Client");
  options.add_options()
      ("host", "", cxxopts::value<std::string>()->default_value("172.17.0.1"))
      ("port", "", cxxopts::value<int>());

  // Parse command-line arguments.
  auto result = options.parse(argc, argv);
  std::string host = result["host"].as<std::string>();
  int port = result["port"].as<int>();

  // Build backend.yml file.
  std::ofstream backend_file;
  backend_file.open("/etc/opt/BuzzBlog/backend.yml");
  backend_file << "uniquepair:\n";
  backend_file << "  service:\n";
  backend_file << "    - " << host << ":" << port << "\n";
  backend_file.close();

  // Create MicroserviceConnectedServer.
  auto microservice_connected_server = MicroserviceConnectedServer(
      "microbenchmark", "/etc/opt/BuzzBlog/backend.yml", 1, 1, 0, 0);

  // Run `rpc_count` microbenchmark.
  {
    TRequestMetadata request_metadata;
    TUniquepairQuery query;
    run_benchmark<void>(
        std::bind(&MicroserviceConnectedServer::rpc_count,
                  microservice_connected_server, std::ref(request_metadata),
                  std::ref(query)),
        nullptr, nullptr, 1000000, 180,
        "logs/rpc_count.csv");
  }

  // Run `rpc_find` microbenchmark.
  {
    TRequestMetadata request_metadata;
    std::string domain;
    int32_t first_elem, second_elem;

    run_benchmark<void>(
        std::bind(&MicroserviceConnectedServer::rpc_find,
                  microservice_connected_server, std::ref(request_metadata),
                  std::ref(domain), std::ref(first_elem),
                  std::ref(second_elem)),
        nullptr, nullptr, 1000000, 180,
        "logs/rpc_find.csv");
  }

  return 0;
}

# DevOps Playground

[![CI](https://github.com/jhandguy/devops-playground/workflows/CI/badge.svg)](https://github.com/jhandguy/devops-playground/actions?query=workflow%3ACI)

A Playground to experiment with various DevOps tools and technologies.

## Tools

- Minikube
- LocalStack
- Prometheus
- Grafana
- Loki
- AlertManager
- PushGateway
- Consul
- Vault
- CSI
- K6

## Technologies

- Terraform
- Kubernetes
- Helm

## Languages

- Golang
- YAML
- HCL

## Architecture

```text
 -----------------------------------
|         [CONSUL + VAULT]          |
|                                   |
|     -----------   -----------     |
|    | Dynamo DB | | S3 Bucket |    |
|     -----------   -----------     |
|          |             |          |
|         SDK           SDK         |
|          |             |          |
|      ----------   ----------      |   
|     |  dynamo  | |    s3    |     |
|      ----------   ----------      |
|            |         |            |
|           gRPC      gRPC          |
|            |         |            |
|         -----------------         |
|        |     gateway     |        |
|        | _______ _______ |        |
|        |  prod  | canary |        |
|         -----------------         |
|            ||       ||            |
|           50%       50%           |
|            ||       ||            |
 -----------------------------------
         -------------------
        |  Ingress Gateway  |
         -------------------
                  |
                 REST
                  |
               -------
              |  cli  |
               -------
```

### Install Prerequisites

```shell
brew install protobuf protoc-gen-go protoc-gen-go-grpc minikube terraform k6
```

### Create Infrastructure

```shell
make setup
```

### Run Tests

```shell
make test
```

### Destroy Infrastructure

```shell
make teardown
```

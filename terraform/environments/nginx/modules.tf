module "minikube" {
  source = "../../modules/minikube"

  node_ports = [
    "localstack",
    "dynamo",
    "s3",
    "gateway_canary",
    "gateway_prod",
    "prometheus",
    "alertmanager",
    "grafana",
    "loki",
    "pushgateway",
    "nginx"
  ]
}

module "localstack" {
  depends_on = [module.prometheus]
  source     = "../../modules/localstack"

  aws_dynamo_tables = ["dynamo"]
  aws_s3_buckets    = ["s3"]
  node_ip           = var.node_ip
  node_port         = module.minikube.node_ports["localstack"]
}

module "dynamo" {
  depends_on = [module.prometheus, module.localstack]
  source     = "../../modules/dynamo"

  node_ip            = var.node_ip
  node_port          = module.minikube.node_ports["dynamo"]
  prometheus_enabled = true
  secrets = {
    "aws_region"            = var.aws_region
    "aws_access_key_id"     = var.aws_access_key_id
    "aws_secret_access_key" = var.aws_secret_access_key
    "aws_dynamo_endpoint"   = module.localstack.aws_dynamo_cluster_endpoint
    "aws_dynamo_table"      = module.localstack.aws_dynamo_tables["dynamo"]
    "dynamo_token"          = random_password.dynamo_token.result
  }
}

module "s3" {
  depends_on = [module.prometheus, module.localstack]
  source     = "../../modules/s3"

  node_ip            = var.node_ip
  node_port          = module.minikube.node_ports["s3"]
  prometheus_enabled = true
  secrets = {
    "aws_region"            = var.aws_region
    "aws_access_key_id"     = var.aws_access_key_id
    "aws_secret_access_key" = var.aws_secret_access_key
    "aws_s3_endpoint"       = module.localstack.aws_s3_cluster_endpoint
    "aws_s3_bucket"         = module.localstack.aws_s3_buckets["s3"]
    "s3_token"              = random_password.s3_token.result
  }
}

module "gateway" {
  depends_on = [module.prometheus, module.dynamo, module.s3]
  source     = "../../modules/gateway"

  ingress_host = random_pet.gateway_host.id
  node_ip      = var.node_ip
  node_ports = {
    "canary" : module.minikube.node_ports["gateway_canary"],
    "prod" : module.minikube.node_ports["gateway_prod"]
  }
  prometheus_enabled = true
  secrets = {
    "gateway_token" = random_password.gateway_token.result
    "dynamo_url"    = module.dynamo.cluster_url
    "dynamo_token"  = random_password.dynamo_token.result
    "s3_url"        = module.s3.cluster_url
    "s3_token"      = random_password.s3_token.result
  }
}

module "cli" {
  depends_on = [module.dynamo, module.s3, module.gateway]
  source     = "../../modules/cli"

  secrets = {
    "gateway_url"     = module.nginx.url
    "gateway_host"    = module.gateway.host
    "pushgateway_url" = module.pushgateway.url
    "gateway_token"   = random_password.gateway_token.result
  }
}

module "prometheus" {
  depends_on = [module.metrics]
  source     = "../../modules/prometheus"

  alertmanager_node_port = module.minikube.node_ports["alertmanager"]
  grafana_dashboards     = ["dynamo", "s3", "gateway", "cli"]
  grafana_node_port      = module.minikube.node_ports["grafana"]
  loki_node_port         = module.minikube.node_ports["loki"]
  node_ip                = var.node_ip
  prometheus_node_port   = module.minikube.node_ports["prometheus"]
}

module "pushgateway" {
  depends_on = [module.prometheus]
  source     = "../../modules/pushgateway"

  node_ip   = var.node_ip
  node_port = module.minikube.node_ports["pushgateway"]
}

module "loki" {
  depends_on = [module.prometheus]
  source     = "../../modules/loki"

  alerting_rules         = ["dynamo", "s3", "gateway", "cli"]
  alertmanager_node_port = module.minikube.node_ports["alertmanager"]
  node_ip                = var.node_ip
  node_port              = module.minikube.node_ports["loki"]
}

module "metrics" {
  source = "../../modules/metrics"
}

module "nginx" {
  source = "../../modules/nginx"

  node_ip            = var.node_ip
  node_port          = module.minikube.node_ports["nginx"]
  prometheus_enabled = true
}

module "certmanager" {
  source = "../../modules/certmanager"
}
resource "helm_release" "cli" {
  name             = "cli"
  namespace        = "cli"
  chart            = "../cli/helm"
  create_namespace = true
  wait             = true

  values = [<<-EOF
    test:
      rounds: ${var.test_rounds}
    EOF
  ]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=complete --timeout=60s job/cli -n cli"
  }
}
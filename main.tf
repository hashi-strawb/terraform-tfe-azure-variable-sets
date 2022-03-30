terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.30.0"
    }
  }
}


resource "tfe_variable_set" "azure-creds" {
  name          = "Azure Credentials"
  description   = <<EOF
Azure Credentials for subscription ${var.arm_subscription_id}

Using Service Principal: ${var.arm_display_name}
EOF
  organization  = var.organization
  workspace_ids = var.workspace_ids
}

resource "null_resource" "push-creds" {
  depends_on = [
    tfe_variable_set.azure-creds
  ]

  provisioner "local-exec" {
    command     = "${path.module}/get-creds.sh | ${path.module}/push-creds.sh"
    interpreter = ["bash", "-c"]
    environment = {
      ARM_SUBSCRIPTION_ID = var.arm_subscription_id
      ARM_DISPLAY_NAME    = var.arm_display_name
      TFC_ORG             = var.organization
      TFC_VARSET_ID       = tfe_variable_set.azure-creds.id
    }
  }
}

# Wait until credentials are valid
resource "time_sleep" "wait" {
  depends_on = [null_resource.push-creds]

  create_duration = "30s"
}


resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-${var.environment}-user-pool"

  deletion_protection = var.deletion_protection ? "ACTIVE" : "INACTIVE"

  # Login por email en vez de username separado.
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  password_policy {
    minimum_length                   = var.password_min_length
    require_lowercase                = var.password_require_lowercase
    require_uppercase                = var.password_require_uppercase
    require_numbers                  = var.password_require_numbers
    require_symbols                  = var.password_require_symbols
    temporary_password_validity_days = var.temporary_password_validity_days
  }

  mfa_configuration = var.mfa_configuration

  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" && contains(var.mfa_methods, "TOTP") ? [1] : []
    content {
      enabled = true
    }
  }

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  # Atributo estándar: email (obligatorio, es el identificador de login)
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Atributo estándar: name
  schema {
    name                     = "name"
    attribute_data_type      = "String"
    required                 = var.name_attribute_required
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  dynamic "schema" {
    for_each = var.custom_attributes
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.type
      mutable                  = schema.value.mutable
      developer_only_attribute = false

      dynamic "string_attribute_constraints" {
        for_each = schema.value.type == "String" ? [1] : []
        content {
          min_length = try(schema.value.min_length, 0)
          max_length = try(schema.value.max_length, 2048)
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value.type == "Number" ? [1] : []
        content {
          min_value = try(schema.value.min_length, null)
          max_value = try(schema.value.max_length, null)
        }
      }
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [schema]
  }
}

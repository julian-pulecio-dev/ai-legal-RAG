variable "project_name" {
  description = "Project name, used as a prefix on resources."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "deletion_protection" {
  description = "If true, protects the User Pool against accidental deletion."
  type        = bool
  default     = false
}

variable "password_min_length" {
  type    = number
  default = 12
}

variable "password_require_lowercase" {
  type    = bool
  default = true
}

variable "password_require_uppercase" {
  type    = bool
  default = true
}

variable "password_require_numbers" {
  type    = bool
  default = true
}

variable "password_require_symbols" {
  type    = bool
  default = true
}

variable "temporary_password_validity_days" {
  type    = number
  default = 7
}

variable "mfa_configuration" {
  description = "OFF, ON, or OPTIONAL."
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "mfa_methods" {
  description = "MFA methods enabled when mfa_configuration != OFF. Supported: TOTP."
  type        = list(string)
  default     = ["TOTP"]
}

variable "advanced_security_mode" {
  description = "OFF, AUDIT, or ENFORCED. Detection of compromised credentials and risky activity."
  type        = string
  default     = "AUDIT"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "advanced_security_mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "custom_attributes" {
  description = "Additional custom user attributes."
  type = list(object({
    name       = string
    type       = string # "String" or "Number"
    mutable    = bool
    min_length = optional(number)
    max_length = optional(number)
  }))
  default = []
}

variable "name_attribute_required" {
  description = "Whether the standard 'name' attribute is required at sign-up."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo en los recursos."
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, staging, prod)."
  type        = string
}

variable "deletion_protection" {
  description = "Si es true, protege el User Pool contra borrado accidental."
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
  description = "OFF, ON u OPTIONAL."
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration debe ser OFF, ON u OPTIONAL."
  }
}

variable "mfa_methods" {
  description = "Métodos de MFA habilitados cuando mfa_configuration != OFF. Soportado: TOTP."
  type        = list(string)
  default     = ["TOTP"]
}

variable "advanced_security_mode" {
  description = "OFF, AUDIT o ENFORCED. Detección de credenciales comprometidas y actividad de riesgo."
  type        = string
  default     = "AUDIT"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "advanced_security_mode debe ser OFF, AUDIT o ENFORCED."
  }
}

variable "custom_attributes" {
  description = "Atributos custom adicionales del usuario."
  type = list(object({
    name       = string
    type       = string # "String" o "Number"
    mutable    = bool
    min_length = optional(number)
    max_length = optional(number)
  }))
  default = []
}

variable "name_attribute_required" {
  description = "Si el atributo estándar 'name' es obligatorio en el registro."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

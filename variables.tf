variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "Azure Region"

  default = "switzerlandnorth"
}

variable "vm_size" {
  type        = string
  description = "VM Size"

  default = "Standard_D2s_v3"
}

variable "admin_username" {
  type        = string
  description = "VM Username"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "VM Password"
}

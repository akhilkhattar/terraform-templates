variable "region" {
}
variable "vpc_name" {
    default = whizlabs_VPC
}
variable "IGW" {
  default = IGW
}

variable "Public-Subnet" {
  default = Public-Subnet
}

variable "Private-Subnet" {
  default = Private-Subnet
}

variable "natgw" {
  default = natgw
}

variable "WebSG" {
  default = WebSG
}

variable "PrivateServer" {
  default = PrivateServer
}

variable "PublicWebServer" {
  default = PublicWebServer
}
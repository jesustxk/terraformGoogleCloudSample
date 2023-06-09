output "hostname_1" {
  value = module.turbofy-back-vm.instance_name
}

output "public_ip_1" {
  value = module.turbofy-back-vm.instance_ip_addr
}

output "hostname_2" {
  value = module.turbofy-front-vm.instance_name
}

output "public_ip_2" {
  value = module.turbofy-front-vm.instance_ip_addr
}
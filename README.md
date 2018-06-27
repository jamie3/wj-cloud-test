# Instructions

Creates an azure resource group with 2 VMs, trusted and unstrusted (public ip). Untrusted_vm exposes public ssh access. Trusted_vm only exposes ssh to only from untrusted_vm.

See terraform file for more info

### Pre-requisites

- Install AZ CLI
- Install Terraform https://www.terraform.io/
- Install SSH

## Run

`az login`

`terraform plan`

`terraform apply`

Fetch IP address of untrusted VM that was created

`az network public-ip show --resource-group interview-test --name public-ip |grep ipAddress`

SSH into public untrusted VM.

`ssh Jamie@<public_untrusted_ip>`

From untrusted VM ssh into trusted VM

`ssh Jamie@<trusted_ip>`

Goodluck and godspeed.

~ Jamie
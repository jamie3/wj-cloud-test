# Instructions

# Pre-requisites

- Install AZ CLI
- Install Terraform
- Install SSH

# Run

`az login`

`terraform plan`

`terraform apply`

SSH into public untrusted VM

`ssh Jamie@<public_untrusted_ip>`

From untrusted VM ssh into trusted VM

`ssh Jamie@<trusted_ip>`
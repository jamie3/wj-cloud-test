# Instructions

# Pre-requisites

- Install AZ CLI
- Install Terraform
- Install SSH

# Run

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

Please provide the code and documentation for a script that does the following in Azure
(please select your preference in language):

 create a new resource group called - interview-test
 vnet - with 3 subnets (untrusted, trusted, gateway)
 2 vms -
o 1 with a public IP in the untrusted subnet,
o one in the trusted subnet with no public IPs
 NSG's around each subnet,
o NSG for untrusted subnet only allowing ssh or RDP - depending on which type of
vm they pick to our IP on the untrusted
o NSG around the trusted subnet only allowing ssh or rdp access from the
untrusted subnet.
o NSG around the gateway only allowing ssh or rdp from the trusted subnet.
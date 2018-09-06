# interface_azure

az vmss extension set \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --name CustomScript \
  --resource-group myVmssGroup \
  --vmss-name stormtroopers \
  --settings @customConfig.json

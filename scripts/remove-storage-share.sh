#!/bin/bash

az storage share list --account-key OzddMqaY72hasZ6bHC3rxpnRfFnBPGqx3sDn3+C0SN30rkmAWaPGZKFdRO1LpUZa4R3nnyOmMZyRi6yF44FuKg== --account-name spitz --output table > storage-share
sed -i '1,2d' storage-share
sed -i '1d' storage-share

set -x

for i in $(awk '{print $1}' storage-share)
do
	az storage share delete --name $i --account-name spitz --account-key OzddMqaY72hasZ6bHC3rxpnRfFnBPGqx3sDn3+C0SN30rkmAWaPGZKFdRO1LpUZa4R3nnyOmMZyRi6yF44FuKg==
done

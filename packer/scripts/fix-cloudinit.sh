#!/bin/sh

# This is the grossest thing I've ever done but I'm at my wit's end and don't know what else to try
# cloud-provider-aws requires fqdn because ip-based hostnames are not unique across VPCs
# and setting prefer_fqdn_over_hostname in user-data does not seem to make any difference

sed -Eir 's/(^ +prefer_fqdn = )False/\1True/' /usr/lib/python3.13/site-packages/cloudinit/distros/__init__.py
# Troubleshooting

## Cluster provisioning logs

If anything goes wrong during deployment, the Rancher logs and UI status will not show much detail. You need to look for the job created to create the machines in the `fleet-default` namespace. They will match the machine pool name. The pod logs for the job will show the error in enough detail to remediate.
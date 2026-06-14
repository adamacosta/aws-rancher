# Tips and tricks

## Rancher logs

To stream Rancher application logs:

```sh
kubectl logs -n cattle-system -l app=rancher -c rancher -f
```

To stream audit logs:

```sh
kubectl logs -n cattle-system -l app=rancher -c rancher -f
```

## To start traefik

```bash
docker run -ti -p 1194:1194 -p 8080:8080 -v $PWD/etc/traefik:/etc/traefik:ro traefik:latest
```
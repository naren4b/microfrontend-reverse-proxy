Start 
```bash
export MSYS_NO_PATHCONV=1 
podman network create lab-net
podman pod create --name my-lb -p 80:80 -p 443:443 --network lab-net
podman pod create --name dep-electronics --network lab-net
podman pod create --name dep-clothing --network lab-net

```

Run the Electronics Department
```bash
# Run the electronics container mapping the unique HTML file
podman run -d \
  --name dep-electronics \
  --pod dep-electronics \
  -v "$PWD/dep-electronics/html/://usr/share/nginx/html" \
  docker.io/library/nginx:latest

```

Run the Clothing Department
```bash
# Run the clothing container mapping the unique HTML file
podman run -d \
  --name dep-clothing \
  --pod dep-clothing \
  -v "$PWD/dep-clothing/html/://usr/share/nginx/html" \
  docker.io/library/nginx:latest

```

Run the nginx pod 
```bash
# Run the LB
podman run -d \
  --name my-lb \
  --pod my-lb \
  -v "$PWD/my-lb/config/nginx.conf://etc/nginx/nginx.conf" \
  -v "$PWD/my-lb/html://usr/share/nginx/html" \
  -v "$PWD/my-lb/certs://etc/nginx/certs" \
  docker.io/library/nginx:latest


```
Verification 
```bash
# 1. Test HTTP-to-HTTPS redirect rule (Should give a 301 Redirect status)
curl -I http://localhost

# 2. Test the Secure Home Page
curl -k https://localhost

# 3. Test Secure Electronics Department path routing
curl -k https://localhost/red

# 4. Test Secure Clothing Department path routing
curl -k https://localhost/blue


```

Clean up 
```bash
podman pod rm -f my-lb 2>/dev/null
podman pod rm -f dep-electronics 2>/dev/null
podman pod rm -f dep-clothing 2>/dev/null
podman network rm lab-net

```
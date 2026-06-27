mkdir -p my-lb/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout my-lb/certs/tls.key \
  -out my-lb/certs/tls.crt \
  -subj "/C=IN/ST=KTK/L=BLR/O=Demo/CN=localhost"

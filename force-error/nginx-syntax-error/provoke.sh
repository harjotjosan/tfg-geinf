#!/bin/bash
# Provocation script for Nginx Syntax Error (DOCKER VERSION)
# Run this on the Proxy VM (10.0.27.228)

CONTAINER_NAME="carparts-proxy"

echo "Provoking Nginx syntax error in container: $CONTAINER_NAME..."

# 1. Create a backup inside the container
docker exec $CONTAINER_NAME cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

# 2. Introduce a syntax error (remove a semicolon from 'listen 80;')
# This targets a line that WE KNOW is in the file.
docker exec $CONTAINER_NAME sed -i 's/listen 80;/listen 80/' /etc/nginx/nginx.conf

# 3. Restart the container to force Nginx to load the broken config
echo "Restarting container to apply broken configuration..."
docker restart $CONTAINER_NAME

echo "----------------------------------------------------"
echo "Nginx configuration corrupted (removed semicolon from 'listen 80')."
echo "Container restarted. Run 'docker ps' to see if it's crashing."
echo "Website should now be DOWN."

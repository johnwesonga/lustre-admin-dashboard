#!/bin/bash
# install latest nginx image
podman pull nginx

podman run --name admin_nginx -p 8080:80 -d \
  -v ~/projects/gleam/lustre/lustre-admin-dashboard/conf/default.conf:/etc/nginx/conf.d/default.conf:Z \
  nginx
# The purpose of the script is to invoke the env variables by envsubst,
# The script get used as the entrypoint of the container to be executed
# each time the container is started, its read the env vars and replace
# them creating a new nginx.conf file to be used by nginx. then hand over
# the control to nginx, all that because nginx does not support env vars
# in its config file, so we need to do it manually.


#!/bin/sh
set -e

envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec nginx -g "daemon off;"
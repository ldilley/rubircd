#!/bin/sh
openssl req -x509 -nodes -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365
if [ -f key.pem ]; then
  chmod 400 key.pem
fi

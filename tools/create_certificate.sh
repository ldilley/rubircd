#!/bin/sh
openssl req -x509 -nodes -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365
if [ -f key.pem ]; then
  chmod 400 key.pem
  printf "\nPlace cert.pem and key.pem in the cfg directory and enable SSL/TLS in options.yml if desired.\n"
  printf "Also, you may optionally include ca.pem (if you have one) within the same directory for additional validation.\n"
fi

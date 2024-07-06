#!/bin/bash

curl -sSL https://github.com/ouch-org/ouch/releases/download/0.5.1/ouch-x86_64-unknown-linux-gnu.tar.gz | sudo tar -xz -C /usr/local/bin --strip-components=1 --wildcards '*/ouch'

#!/bin/bash

curl -sSL https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-x86_64-unknown-linux-gnu.tar.gz | sudo tar -xz -C /usr/local/bin --strip-components=1 --wildcards '*/sd'

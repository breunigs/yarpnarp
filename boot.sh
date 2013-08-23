#!/bin/sh

nohup ruby /usr/bin/rackup -s thin -o localhost -p 31337 -P rack.pid > server.log&

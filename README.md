YarpNarp
========

YarpNarp is a *very* simple tool to collect people’s yes/no answers.
There is no security whatsoever, so you probably want only nice
people to use it. 


Requirements
------------

You’ll need a server which runs Ruby 1.9.2+ and Apache/nginx. If you’re
using Debian, have at least the following packages installed:
`ruby1.9.1 ruby-sqlite3 ruby-rack`


Setup
-----

1. If you can run `rackup -s thin` and don’t get an error, it means you
can successfully run YarpNarp.
2. Adjust your `SUPER_SECRET_CHANGE_ME` so people can’t reset the DB by
   accident in `config.ru`.
3. You can integrate YarpNarp any way you like into your server
   landscape. We’re using a reverse lookup because it’s easy to set up
   and YarpNarp won’t be high traffic anyway.
  - run `rackup -s thin` in a screen session
  - in `/etc/nginx/sites-enabled/yarpnarp`:

   ```
   server {
        listen YOUR_V4_IP:80;
        listen YOUR_V6_IP:80;

        keepalive_timeout 60;

        root /path/to/your/yarpnarp/;
        access_log /var/log/nginx/yarpnarp-access.log combined;
        error_log /var/log/nginx/yarpnarp-error.log;
        index index.html index.htm;

        server_name SAME_AS_OUR_HOST;

        location / {
            proxy_pass http://localhost:9292;
        }
    }
    ```

License and attribution
-----------------------

yarpnarp is licensed under the ISC license, see `LICENSE` for details.

#!/usr/bin/zsh

set -e

cd $(dirname $0)

ps x | grep "[r]uby /usr/bin/rackup -s thin -p 31337" | cut -d" " -f1 | xargs -r kill

nohup ruby /usr/bin/rackup -s thin -p 31337 > server.log&

sleep 1

echo "\n"
read -q answer\?"RESET/Clear database as well? [yn]" || true
echo "\n"
if [ "$answer" = "y" ] ; then
  sleep 3
  wget -q -O /dev/null "http://0.0.0.0:31337/?action=SUPER_SECRET_CHANGE_ME"
  echo "cleared"
else
  echo "database kept intact"
fi

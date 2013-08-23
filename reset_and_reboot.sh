#!/usr/bin/zsh

set -e

cd $(dirname $0)

#ps x | grep "[r]uby /usr/bin/rackup -s thin -p 31337" | cut -d" " -f1 | xargs -r kill

if [ -f rack.pid ]; then
  echo "PID file found, trying to kill…"
  kill -9 $(cat rack.pid) || true
fi

./boot.sh&

sleep 1

echo "\n"

if [ "$1" = "automatically_reset" ]; then
  answer="y"
else
  read -q answer\?"RESET/Clear database as well? [yn]" || true
fi

echo "\n"
if [ "$answer" = "y" ] ; then
  sleep 3
  rm -f "meet_at"
  wget -q -O /dev/null "http://localhost:31337/?action=SUPER_SECRET_CHANGE_ME"
  echo "cleared"
else
  echo "database kept intact"
fi

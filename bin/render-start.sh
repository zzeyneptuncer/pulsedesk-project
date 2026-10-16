#!/usr/bin/env bash
set -euo pipefail

# Free instances lose local SQLite data on restart; restore the demo on boot.
mkdir -p storage tmp/pids
ruby bin/rails db:prepare
ruby bin/rails db:seed
exec bundle exec puma -C config/puma.rb -b "tcp://0.0.0.0:${PORT:-10000}"

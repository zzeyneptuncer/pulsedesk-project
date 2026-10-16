#!/usr/bin/env bash
set -euo pipefail

bundle install
ruby bin/rails assets:precompile
ruby bin/rails db:prepare
ruby bin/rails db:seed

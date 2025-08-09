#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../sim"
make lint
make sim 
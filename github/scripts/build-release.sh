#!/usr/bin/env bash
# Shared production/smoke packaging path. No tag or release operations.
set -euo pipefail
7z a -p"malte" -t7z Z_LAG_OS.apbx ./src/*
7z t -p"malte" Z_LAG_OS.apbx
sha256sum Z_LAG_OS.apbx > Z_LAG_OS.apbx.sha256

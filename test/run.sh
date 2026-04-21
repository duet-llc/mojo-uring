#!/bin/bash
set -euo pipefail

find test -name "test_*.mojo" -print0 | xargs -0 -P 0 -I TEST mojo -I src TEST

#!/bin/bash

# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

find test -name "test_*.mojo" -print0 | xargs -0 -P 0 -I TEST mojo -I src TEST

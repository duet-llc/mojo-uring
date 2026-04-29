# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.testing import TestSuite, assert_raises

from uring import Params, Uring


def test_uring_success() raises:
    _ = Uring(128, Params())


def test_uring_invalid_entries() raises:
    with assert_raises(contains="Invalid argument"):
        _ = Uring(65536, Params())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

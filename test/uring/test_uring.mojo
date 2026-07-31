# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.testing import TestSuite, assert_raises

from uring import Params, Uring


def test_uring_success() raises:
    var ring = Uring(128, Params())
    ring^.close()


def test_uring_traits() raises:
    comptime assert conforms_to(Uring, Movable)
    comptime assert not conforms_to(Uring, Copyable)
    comptime assert not conforms_to(Uring, ImplicitlyDeletable)


def test_uring_invalid_entries() raises:
    with assert_raises(contains="Invalid argument"):
        var ring = Uring(65536, Params())
        ring^.close()


def test_uring_nop_compiles() raises:
    var ring = Uring(8, Params())
    var coroutine = ring.nop()
    coroutine^.force_destroy()
    ring^.close()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

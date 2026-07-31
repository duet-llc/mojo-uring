# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.testing import TestSuite, assert_equal, assert_raises

from uring import Params, Uring


def test_uring_success() raises:
    _ = Uring(128, Params())


def test_uring_traits() raises:
    comptime assert conforms_to(Uring, ImplicitlyDeletable)
    comptime assert conforms_to(Uring, Movable)
    comptime assert not conforms_to(Uring, Copyable)


def test_uring_invalid_entries() raises:
    with assert_raises(contains="Invalid argument"):
        _ = Uring(65536, Params())


def test_uring_nop_compiles() raises:
    var io = Uring(8, Params())
    var co = io.nop()
    co^.force_destroy()


def test_ring_index_wraparound() raises:
    var head = UInt32(0xFFFFFF80)
    var tail = UInt32(128)
    assert_equal(tail - head, 256)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

"""Tests for the ring module."""

from std.testing import assert_equal, TestSuite
from uring import Ring


def test_ring_creation() raises:
    """Test creating a Ring."""
    var ring = Ring(256)
    assert_equal(ring.get_queue_size(), 256)


def test_ring_add() raises:
    """Test the add operation."""
    var ring = Ring(512)
    var result = ring.add(3, 4)
    assert_equal(result, 7)


def test_ring_add_zero() raises:
    """Test add with zero values."""
    var ring = Ring(128)
    assert_equal(ring.add(0, 5), 5)
    assert_equal(ring.add(10, 0), 10)
    assert_equal(ring.add(0, 0), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

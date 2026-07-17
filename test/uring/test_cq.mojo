# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.sys.info import align_of, size_of
from std.testing import TestSuite, assert_equal

from uring._cq import _CompletionQueueEntry


def test_completion_queue_entry_offsets() raises:
    comptime R = reflect[_CompletionQueueEntry]
    assert_equal(R.field_offset[name="_user_data"](), 0)
    assert_equal(R.field_offset[name="_res"](), 8)
    assert_equal(R.field_offset[name="_flags"](), 12)


def test_completion_queue_entry_layout() raises:
    assert_equal(align_of[_CompletionQueueEntry](), 8)
    assert_equal(size_of[_CompletionQueueEntry](), 16)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.sys.info import align_of, size_of
from std.testing import TestSuite, assert_equal

from uring._sq import _SubmissionQueueEntry


def test_submission_queue_entry_offsets() raises:
    comptime R = reflect[_SubmissionQueueEntry]
    assert_equal(R.field_offset[name="_opcode"](), 0)
    assert_equal(R.field_offset[name="_flags"](), 1)
    assert_equal(R.field_offset[name="_ioprio"](), 2)
    assert_equal(R.field_offset[name="_fd"](), 4)
    assert_equal(R.field_offset[name="_off"](), 8)
    assert_equal(R.field_offset[name="_addr"](), 16)
    assert_equal(R.field_offset[name="_len"](), 24)
    assert_equal(R.field_offset[name="_rw_flags"](), 28)
    assert_equal(R.field_offset[name="_user_data"](), 32)
    assert_equal(R.field_offset[name="_buf_index"](), 40)
    assert_equal(R.field_offset[name="_personality"](), 42)
    assert_equal(R.field_offset[name="_splice_fd_in"](), 44)
    assert_equal(R.field_offset[name="_pad2"](), 48)


def test_submission_queue_entry_layout() raises:
    assert_equal(align_of[_SubmissionQueueEntry](), 8)
    assert_equal(size_of[_SubmissionQueueEntry](), 64)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

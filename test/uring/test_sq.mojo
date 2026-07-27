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


def test_submission_queue_entry_traits() raises:
    comptime assert conforms_to(_SubmissionQueueEntry, ImplicitlyCopyable)


def test_submission_queue_entry_reset() raises:
    var sqe = _SubmissionQueueEntry()
    sqe._opcode = 255
    sqe._flags = 1
    sqe._ioprio = 2
    sqe._fd = -1
    sqe._off = 3
    sqe._addr = 4
    sqe._len = 5
    sqe._rw_flags = 6
    sqe._user_data = 7
    sqe._buf_index = 8
    sqe._personality = 9
    sqe._splice_fd_in = -10
    sqe._pad2[0] = 11
    sqe._pad2[1] = 12
    sqe._reset()
    assert_equal(sqe._opcode, 0)
    assert_equal(sqe._flags, 0)
    assert_equal(sqe._ioprio, 0)
    assert_equal(sqe._fd, 0)
    assert_equal(sqe._off, 0)
    assert_equal(sqe._addr, 0)
    assert_equal(sqe._len, 0)
    assert_equal(sqe._rw_flags, 0)
    assert_equal(sqe._user_data, 0)
    assert_equal(sqe._buf_index, 0)
    assert_equal(sqe._personality, 0)
    assert_equal(sqe._splice_fd_in, 0)
    assert_equal(sqe._pad2[0], 0)
    assert_equal(sqe._pad2[1], 0)


def test_submission_queue_entry_prep_nop() raises:
    var sqe = _SubmissionQueueEntry()
    sqe._opcode = 255
    sqe._user_data = 42
    sqe._prep_nop()
    assert_equal(sqe._opcode, 0)
    assert_equal(sqe._user_data, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

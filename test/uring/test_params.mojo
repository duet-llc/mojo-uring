# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.sys.info import align_of, size_of
from std.testing import TestSuite, assert_equal

from uring import Params
from uring._params import (
    _CompletionQueueRingOffsets,
    _Params,
    _SubmissionQueueRingOffsets,
)


def test_params_traits() raises:
    comptime assert conforms_to(Params, Movable)
    comptime assert not conforms_to(Params, Copyable)


def test_params_offsets() raises:
    comptime R = reflect[_Params]
    assert_equal(R.field_offset[name="_sq_entries"](), 0)
    assert_equal(R.field_offset[name="_cq_entries"](), 4)
    assert_equal(R.field_offset[name="_flags"](), 8)
    assert_equal(R.field_offset[name="_sq_thread_cpu"](), 12)
    assert_equal(R.field_offset[name="_sq_thread_idle"](), 16)
    assert_equal(R.field_offset[name="_features"](), 20)
    assert_equal(R.field_offset[name="_wq_fd"](), 24)
    assert_equal(R.field_offset[name="_resv"](), 28)
    assert_equal(R.field_offset[name="_sq_off"](), 40)
    assert_equal(R.field_offset[name="_cq_off"](), 80)


def test_params_layout() raises:
    assert_equal(align_of[_Params](), 8)
    assert_equal(size_of[_Params](), 120)


def test_submission_queue_ring_offsets() raises:
    comptime R = reflect[_SubmissionQueueRingOffsets]
    assert_equal(R.field_offset[name="_head"](), 0)
    assert_equal(R.field_offset[name="_tail"](), 4)
    assert_equal(R.field_offset[name="_ring_mask"](), 8)
    assert_equal(R.field_offset[name="_ring_entries"](), 12)
    assert_equal(R.field_offset[name="_flags"](), 16)
    assert_equal(R.field_offset[name="_dropped"](), 20)
    assert_equal(R.field_offset[name="_array"](), 24)
    assert_equal(R.field_offset[name="_resv1"](), 28)
    assert_equal(R.field_offset[name="_user_addr"](), 32)


def test_submission_queue_ring_offsets_layout() raises:
    assert_equal(align_of[_SubmissionQueueRingOffsets](), 8)
    assert_equal(size_of[_SubmissionQueueRingOffsets](), 40)


def test_completion_queue_ring_offsets() raises:
    comptime R = reflect[_CompletionQueueRingOffsets]
    assert_equal(R.field_offset[name="_head"](), 0)
    assert_equal(R.field_offset[name="_tail"](), 4)
    assert_equal(R.field_offset[name="_ring_mask"](), 8)
    assert_equal(R.field_offset[name="_ring_entries"](), 12)
    assert_equal(R.field_offset[name="_overflow"](), 16)
    assert_equal(R.field_offset[name="_cqes"](), 20)
    assert_equal(R.field_offset[name="_flags"](), 24)
    assert_equal(R.field_offset[name="_resv1"](), 28)
    assert_equal(R.field_offset[name="_user_addr"](), 32)


def test_completion_queue_ring_offsets_layout() raises:
    assert_equal(align_of[_CompletionQueueRingOffsets](), 8)
    assert_equal(size_of[_CompletionQueueRingOffsets](), 40)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

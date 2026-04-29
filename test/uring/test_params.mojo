# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.reflection import offset_of
from std.sys.info import size_of
from std.testing import TestSuite, assert_equal

from uring.params import (
    _CompletionQueueRingOffsets,
    _Params,
    _SubmissionQueueRingOffsets,
)


def test_params_offsets() raises:
    assert_equal(offset_of[_Params, name="_sq_entries"](), 0)
    assert_equal(offset_of[_Params, name="_cq_entries"](), 4)
    assert_equal(offset_of[_Params, name="_flags"](), 8)
    assert_equal(offset_of[_Params, name="_sq_thread_cpu"](), 12)
    assert_equal(offset_of[_Params, name="_sq_thread_idle"](), 16)
    assert_equal(offset_of[_Params, name="_features"](), 20)
    assert_equal(offset_of[_Params, name="_wq_fd"](), 24)
    assert_equal(offset_of[_Params, name="_resv"](), 28)
    assert_equal(offset_of[_Params, name="_sq_off"](), 40)
    assert_equal(offset_of[_Params, name="_cq_off"](), 80)


def test_params_size() raises:
    assert_equal(size_of[_Params](), 120)


def test_submission_queue_ring_offsets_offsets() raises:
    assert_equal(offset_of[_SubmissionQueueRingOffsets, name="_head"](), 0)
    assert_equal(offset_of[_SubmissionQueueRingOffsets, name="_tail"](), 4)
    assert_equal(offset_of[_SubmissionQueueRingOffsets, name="_ring_mask"](), 8)
    assert_equal(
        offset_of[_SubmissionQueueRingOffsets, name="_ring_entries"](), 12
    )
    assert_equal(offset_of[_SubmissionQueueRingOffsets, name="_flags"](), 16)
    assert_equal(offset_of[_SubmissionQueueRingOffsets, name="_dropped"](), 20)
    assert_equal(offset_of[_SubmissionQueueRingOffsets, name="_array"](), 24)
    assert_equal(offset_of[_SubmissionQueueRingOffsets, name="_resv1"](), 28)
    assert_equal(
        offset_of[_SubmissionQueueRingOffsets, name="_user_addr"](), 32
    )


def test_submission_queue_ring_offsets_size() raises:
    assert_equal(size_of[_SubmissionQueueRingOffsets](), 40)


def test_completion_queue_ring_offsets_offsets() raises:
    assert_equal(offset_of[_CompletionQueueRingOffsets, name="_head"](), 0)
    assert_equal(offset_of[_CompletionQueueRingOffsets, name="_tail"](), 4)
    assert_equal(offset_of[_CompletionQueueRingOffsets, name="_ring_mask"](), 8)
    assert_equal(
        offset_of[_CompletionQueueRingOffsets, name="_ring_entries"](), 12
    )
    assert_equal(offset_of[_CompletionQueueRingOffsets, name="_overflow"](), 16)
    assert_equal(offset_of[_CompletionQueueRingOffsets, name="_cqes"](), 20)
    assert_equal(offset_of[_CompletionQueueRingOffsets, name="_flags"](), 24)
    assert_equal(offset_of[_CompletionQueueRingOffsets, name="_resv1"](), 28)
    assert_equal(
        offset_of[_CompletionQueueRingOffsets, name="_user_addr"](), 32
    )


def test_completion_queue_ring_offsets_size() raises:
    assert_equal(size_of[_CompletionQueueRingOffsets](), 40)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

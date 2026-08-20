# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import (
    AnyCoroutine,
    _CoroutineContext,
    _coro_resume_fn,
)
from std.testing import TestSuite, assert_raises, assert_true

from uring import Context, Params, Uring
from uring._coroutine import _coro_from_addr, _coro_to_addr


def _mark_completed(payload: AnyCoroutine):
    Pointer[Bool, MutUntrackedOrigin](
        unsafe_from_address=_coro_to_addr(payload)
    )[] = True


def test_uring_success() raises:
    _ = Uring(128, Params())


def test_uring_invalid_entries() raises:
    with assert_raises(contains="Invalid argument"):
        _ = Uring(65536, Params())


def test_uring_nop_without_cancelation_compiles() raises:
    var io = Uring(8, Params())
    var ctx = Context()
    var co = io.nop(ctx)
    co^._unsafe_force_deinit()


def test_uring_nop_completion() raises:
    var io = Uring(8, Params())
    var ctx = Context()
    var co = io.nop(ctx)
    var completed = False
    var completion = co._get_ctx[_CoroutineContext]()
    completion[]._resume_fn = _mark_completed
    completion[]._parent_hdl = _coro_from_addr(Int(MutPointer(to=completed)))
    _coro_resume_fn(co._handle)
    io._submit()
    io._complete()
    co^._unsafe_force_deinit()
    assert_true(completed)


def test_uring_nop_with_cancelation_compiles() raises:
    var io = Uring(8, Params())
    var ctx = Context[cancelable=True]()
    var co = io.nop(ctx)
    co^._unsafe_force_deinit()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run(quiet=True)

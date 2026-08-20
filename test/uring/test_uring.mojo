# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import _coro_resume_fn
from std.testing import TestSuite, assert_raises, assert_true

from uring import Context, Params, Uring


struct _CoroutineContext[origin: MutOrigin, //](TrivialRegisterPassable):
    comptime _resume_fn_type = def(mut Bool) thin -> None

    var _resume_fn: Self._resume_fn_type
    var _complete: Pointer[Bool, Self.origin]

    def __init__(out self, ref[Self.origin] completed: Bool):
        self._resume_fn = Self._mark_completed
        # The callback mutates this external flag, so the pointer is mutable and
        # retains the flag's precise origin rather than erasing it.
        self._complete = Pointer(to=completed)

    @staticmethod
    def _mark_completed(mut completed: Bool):
        completed = True


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
    co._get_ctx[
        _CoroutineContext[origin=origin_of(completed)]
    ]()[] = _CoroutineContext(completed)
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

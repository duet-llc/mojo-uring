# SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc>
#
# SPDX-License-Identifier: Apache-2.0

from std.builtin.coroutine import _coro_resume_fn
from std.testing import TestSuite, assert_raises, assert_true

from uring import Context, Params, Uring


def _mark_completed(mut completed: Bool):
    completed = True


struct _CallbackContext(TrivialRegisterPassable):
    comptime Callback = def(mut Bool) thin -> None

    var _callback: Self.Callback
    var _payload: Pointer[Bool, MutUntrackedOrigin]

    def __init__(out self, mut completed: Bool):
        self._callback = _mark_completed
        self._payload = Pointer[Bool, MutUntrackedOrigin](
            unsafe_from_address=Int(MutPointer(to=completed))
        )


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
    co._get_ctx[_CallbackContext]()[] = _CallbackContext(completed)
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

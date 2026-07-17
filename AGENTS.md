<!-- SPDX-FileCopyrightText: 2026 Duet LLC <contact@duet.llc> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

- For each Mojo struct mirroring a kernel header, add an `_offsets` test for every field offset and a separate `_layout` test for alignment and total size.
- For each exported type, test its intended trait conformances.

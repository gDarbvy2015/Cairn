# Cairn Cache Format (v1)

This document is the normative specification of the Cairn on-disk format and
hashing scheme. Both the Rust engine (`cairn`) and the Go wrapper (`cairn-run`)
implement it exactly, so a cache produced by one tool is fully usable by the
other.


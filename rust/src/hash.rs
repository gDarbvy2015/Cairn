//! Deterministic, non-cryptographic content hashing.
//!
//! Cairn uses the 64-bit FNV-1a hash to produce content addresses. FNV-1a is
//! fast, dependency-free, and fully deterministic across platforms and

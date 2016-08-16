//! A tiny, dependency-free JSON writer and reader.
//!
//! Cairn manifests are simple, flat-ish JSON documents. Rather than pull in a
//! serialization crate, we ship a focused implementation that supports exactly
//! the value shapes the manifest format uses: objects, arrays, strings,
//! unsigned integers, and booleans. The writer emits **canonical** JSON with
//! keys in insertion order and no insignificant whitespace, so that manifest
//! bytes are stable and reproducible across runs.

use std::collections::BTreeMap;
use std::fmt::Write as _;

/// A JSON value restricted to the shapes Cairn needs.
#[derive(Clone, Debug, PartialEq)]
pub enum Json {
    Str(String),
    Uint(u64),
    Bool(bool),
    Array(Vec<Json>),
    /// Ordered map so serialization is deterministic.
    Object(Vec<(String, Json)>),
}

//! The on-disk content-addressed store.
//!
//! Layout under the cache root (default `.cairn-cache`):
//!
//! ```text
//! <root>/
//!   objects/<aa>/<digest>       content-addressed blobs (aa = first 2 hex chars)
//!   manifests/<key>.json        manifests keyed by cache key
//! ```
//!
//! Blobs are deduplicated: identical content is stored once regardless of how
//! many manifests reference it. The same layout is understood by the Go
//! wrapper, so a manifest written by one tool can be restored by the other.


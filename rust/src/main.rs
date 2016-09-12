//! `cairn` — the content-addressed build cache CLI.
//!
//! Subcommands:
//!
//! ```text
//! cairn hash <file>...                       print digests of files
//! cairn key   --input F... [-- cmd...]       compute a cache key
//! cairn store --key K --input F... --output F... [-- cmd...]
//!                                            store outputs + manifest
//! cairn restore --key K [--out-dir DIR]      restore outputs from cache
//! cairn verify  --key K                      verify store integrity for a key
//! cairn show    --key K                      print a manifest as JSON
//! ```
//!

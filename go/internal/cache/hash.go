// Package cache implements the Cairn content-addressed cache format in Go.
//
// It is a faithful, standard-library-only port of the Rust engine: the same
// FNV-1a 64-bit hashing scheme, the same canonical cache-key stream, and the

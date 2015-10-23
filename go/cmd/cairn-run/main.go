// Command cairn-run is the Cairn command-execution wrapper.
//
// It computes a cache key from declared input files and the command line. On a
// cache hit it restores the recorded outputs instead of re-running the
// command; on a miss it runs the command, captures the declared outputs into
// the content-addressed store, and writes a manifest. The store layout and
// manifest format are byte-compatible with the Rust `cairn` engine.
//
// Usage:
//
//	cairn-run [options] -- <command> [args...]

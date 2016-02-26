package cache

import (
	"fmt"
	"os"
	"path/filepath"
)

// Store is the on-disk content-addressed store, byte-compatible with the Rust
// engine's layout:

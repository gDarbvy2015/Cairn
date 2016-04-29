<!-- Cairn — a field guide to a content-addressed build cache. -->

# Cairn — a field guide

<p align="center">
  <img src="docs/assets/strata.svg" alt="Build artifacts descending into content-addressed rock strata, each seam labelled with an FNV-1a digest shard" width="820">
</p>

> A cairn is a stack of stones left to mark that *someone has already been this
> way*. This Cairn does the same for a build: it marks work that has already
> been done, so you never have to walk it twice.

Cairn is a **universal, content-addressed build cache**. It hashes the inputs
to a build step, files the outputs in a deduplicated object store keyed by
content, and — when the same inputs come around again — hands the outputs back
instead of re-running the work. It does not care what language your build is
written in; it cares only about *bytes in* and *bytes out*.

The system is quarried from two tools that agree, seam for seam, on one format:


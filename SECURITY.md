# Security Policy

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use GitHub's private
[security advisory](https://github.com/gDarbvy2015/Cairn/security/advisories/new) form, or contact a
maintainer directly if the form is unavailable to you.

Include what an attacker gains in one sentence, the version or commit you are running, the smallest
reproduction you can manage, and whether the input is attacker-controlled in your setup. You should
get an acknowledgement within a few working days and a disclosure timeline before anything is
published.

## Scope

Cairn hashes build inputs and serves outputs from a content-addressed store. In
scope: crafted inputs that mis-key an entry (path separators, unicode names, symlinks),
a partially written object accepted as complete, an eviction that breaks an in-flight
restore, and path handling in the store reader.

# Live Documentation

The canonical WARPi documentation source is the tracked `docs/` directory in this repository.

The live WARPi path `/opt/warpi/docs` is a deployed copy for on-device visibility and for `kernel-doc-audit`. It is not a second documentation source of truth and should not be edited directly for durable changes.

## Synchronization Model

Use `bin/warpi-docs-sync` to populate `/opt/warpi/docs` from the repository `docs/` tree. The sync writes `.warpi-docs-manifest.sha256` into the live documentation directory.

`kernel-doc-audit` validates that the live manifest exists and that every manifest-listed file still matches its deployed hash. This detects stale, missing, or edited live documentation without requiring the live WARPi host to contain a Git checkout.

## Recovery

Before replacing `/opt/warpi/docs`, create a timestamped backup under `/root/kernel-backups/warpi-docs/`.

To roll back a documentation-only sync, restore the backed-up directory contents and rerun `kernel-doc-audit --json`. This does not require network mode switching, route changes, Wi-Fi/radio changes, or Tailscale changes.

# Security Model

WARPi should expose a constrained, auditable control surface.

## Identities

K.E.R.N.E.L. uses dedicated named identities for approved remote operations.

Current live model:

- `kernel`: administrative validation identity with key-based SSH and passwordless sudo for approved WARPi administration.
- `kernel-agent`: constrained status/telemetry identity for read-oriented checks and future bounded command-surface work.

The `kernel` account password is locked; access is through the approved public SSH key. The `kernel-agent` account remains useful while WARPi's safer command surface is being designed.

Routine K.E.R.N.E.L. interaction should prefer:

- `kernel-report --json`
- `kernel-doc-audit --json`
- `kernel-security <approved-command> <target>`
- future `warpi ...` command surface

Avoid routine dependence on arbitrary root shell execution.

## Wireless Boundaries

Wireless testing is limited to explicitly authorized VaughnLab systems/networks.

Active wireless behavior requires explicit approval and a lab/engagement profile:

- AP association behavior
- deauthentication
- captive portal activity
- DNS spoofing
- handshake capture
- responder-style behavior

## Git Hygiene

Never commit:

- secrets or keys
- tokens or OAuth material
- private evidence/captures
- sensitive operational logs
- credential-bearing configs

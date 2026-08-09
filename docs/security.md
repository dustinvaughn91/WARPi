# Security Model

WARPi should expose a constrained, auditable control surface.

## Identities

K.E.R.N.E.L. uses a dedicated `kernel-agent` identity for approved remote operations.

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


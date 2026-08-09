# Security Policy

This repository may document a live private field platform. Treat it as sensitive even when individual files are written to be public-safe.

Do not commit:

- passwords
- private keys
- API tokens
- OAuth client secrets
- Tailscale auth material
- cookies or sessions
- sensitive packet captures
- private evidence bundles
- credential-bearing logs
- undisclosed third-party target data

Use placeholders in examples. Store real secrets only in approved local secret-handling paths outside Git.

Wireless testing must remain inside explicit authorization. Active wireless behavior such as association attacks, deauthentication, captive portals, DNS spoofing, handshake capture, or responder-style behavior requires an approved lab/engagement profile and human approval.


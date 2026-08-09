# Operating Model

WARPi is a field platform, not just a toolbox. The platform should be predictable, recoverable, and understandable from its own status output.

## Principles

- Reality before roadmap: inspect the live device before assuming old documentation is correct.
- Backup before change: preserve known-good configs/scripts before major modifications.
- GitHub is durable memory: meaningful architecture/configuration changes get documented.
- Least privilege: K.E.R.N.E.L. should use bounded WARPi operations, not arbitrary root shell execution for routine work.
- Test after every meaningful change.
- Keep daily checkpoints during active project work.
- Wireless testing is limited to explicitly authorized VaughnLab systems and networks.

## Routine Workflow

1. Read relevant documentation.
2. Verify live health/status.
3. Define a small change set.
4. Make one logical change.
5. Test the affected behavior.
6. Document persistent changes.
7. Commit meaningful milestones.

## Approval Gates

Pause before changing:

- system configuration
- services or boot behavior
- networking/firewall/Tailscale
- identities or sudoers
- Mission Control behavior
- active wireless behavior
- firmware/packages on attached devices
- anything that may expose secrets or traffic captures


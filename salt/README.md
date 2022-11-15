# SaltStack - Infrastructure Automation

This SaltStack Formula for [SaltStack](https://github.com/saltstack/salt) allows to easily manage SaltStack components using SaltStack itself.

It supports currently:
- [Salt Master](https://docs.saltproject.io/en/latest/ref/configuration/master.html) via [`salt.master`](master/init.sls)
- [Salt Minion](https://docs.saltproject.io/en/latest/ref/configuration/minion.html) via [`salt.minion`](minion/init.sls)
- [Salt Cloud](https://docs.saltproject.io/en/latest/topics/cloud/) via [`salt.cloud`](cloud/init.sls)

## Configuration

This SaltStack Formula can be configured through SaltStack Pillar values provided below the key `salt`.

**Example:**

```yaml
salt:
  minion:
    configuration:
      data:
        ipv6: true
```

### Configuring the systemd unit

To pass custom options to the `salt-minion` service unit, use Pillars following the example below:

```yaml
salt:
  minion:
    service:
      unitoptions:
        Service:
          - SystemCallFilter: @io
          - Environment: CUSTOM_ENV_VAR=somevalue
          - Environment: ANOTHER_ENV_VAR=anothervalue
        Unit:
          - Documentation: https://docserver.int/salt/minion
```

## Compatibility

**Requirements:**
- **OS:**      Linux
- **systemd:** `>=249`

**Developed/tested with:**
- **OS:** Ubuntu 22.04/jammy; SLES15-SP2
- **SaltStack:** `2018.3.3`; `3002.2`; `3005.1`
- **Python:** `3.6.5`; `3.6.13`, `3.9.15`
- **Jinja2:** `3.1.0`

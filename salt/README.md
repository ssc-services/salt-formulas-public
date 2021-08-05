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

## Compatibility

**Requirements:**
- **OS:**      Linux
- **systemd:** `>=232`

**Developed/tested with:**
- **OS:** Ubuntu 18.04/bionic
- **SaltStack:** `2018.3.3`
- **Python:** `3.6.5`
- **Jinja2:** `2.10`

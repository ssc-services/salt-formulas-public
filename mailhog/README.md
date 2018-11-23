# MailHog - Web and API based SMTP testing

This SaltStack Formula for [MailHog](https://github.com/mailhog/MailHog) allows to easily provide local SMTP testing for development or testing purposes.

By simply assigning/applying the state `mailhog`, a local service will provide SMTP capabilities on `0.0.0.0:1025` and a web interface for viewing and managing received mails on `http://0.0.0.0:8025`.

## Configuration

This SaltStack Formula can be configured through SaltStack Pillar values provided below the key `mailhog`.

**Example:**

```yaml
mailhog:
  service:
    params: # use `/usr/local/bin/mailhog --help` for available parameters
      invite-jim: none # use none in case a param doesn't require a value
      jim-reject-sender: 0.5
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

## Maintenance

In case a newer [MailHog release](https://github.com/mailhog/MailHog/releases) is available, either the default values of `version` and `source.checksum` in `mailhog/map.jinja` can be overriden, or the new release can be easily provided as Pillar data:

```yaml
mailhog:
  version: 1.2.3
  source:
    checksum:
      value: 1c930c143782568f8efa87c56247e285406f640e2b53471e619df5a881d36729
```

Generating the checksum for a specific release (here: `1.2.3`) is as easy as running:

```bash
curl -L https://github.com/mailhog/MailHog/releases/download/v1.2.3/MailHog_linux_amd64 | sha256sum
```

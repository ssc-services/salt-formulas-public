{% from "mailhog/map.jinja" import mailhog %}

mailhog-executable:
  file.managed:
    - source:      {{ mailhog.source.url }}
    - source_hash: {{ mailhog.source.checksum.type }}={{ mailhog.source.checksum.value }}
    - name:        /usr/local/bin/mailhog
    - user:        root
    - group:       root
    - mode:        0555
    - makedirs:    true

mailhog-service-unit:
  file.managed:
    - name:     /etc/systemd/system/mailhog.service
    - source:   salt://mailhog/files/mailhog.service.jinja
    - user:     root
    - group:    root
    - mode:     0400
    - template: jinja

mailhog-systemd-reload:
  module.run:
    - name: service.systemctl_reload
    - require:
      - file: mailhog-service-unit
    - onchanges:
      - file: mailhog-service-unit

mailhog-service:
  service.running:
    - name:   mailhog
    - enable: true
    - watch:
      - file: mailhog-executable
      - file: mailhog-service-unit
    - require:
      - file:   mailhog-service-unit
      - module: mailhog-systemd-reload
      - file:   mailhog-executable

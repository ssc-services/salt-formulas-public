# by setting the `salt-minion` service to `Restart=always`, it'll be
# automatically restarted once the cache-cleaner has finished its job
salt-minion-service-override:
  file.managed:
    - name: /etc/systemd/system/salt-service.d/override.conf
    - makedirs: true
    - contents:
      - '[Service]'
      - Restart=always
    - require_in:
      - service: salt-minion-service
    - watch_in:
      - service: salt-minion-service

{%- for type in ['service', 'timer'] %}
salt-minion-cache-clear-{{ type }}-unit:
  file.managed:
      - name:     /etc/systemd/system/salt-minion-cache-clear.{{ type }}
      - user:     root
      - group:    root
      - source:   salt://salt/minion/files/salt-minion-cache-clear.{{ type }}.jinja
      - template: jinja
      - require_in:
        - module: salt-minion-reload-units
      - watch_in:
        - module: salt-minion-reload-units
{%- endfor %}

salt-minion-cache-clear-service:
  service.running:
      - name:   salt-minion-cache-clear.timer
      - enable: true
      - require:
        - module: salt-minion-reload-units
        - file:   salt-minion-cache-clear-service-unit
        - file:   salt-minion-cache-clear-timer-unit
      - watch:
        - file: salt-minion-cache-clear-service-unit
        - file: salt-minion-cache-clear-timer-unit
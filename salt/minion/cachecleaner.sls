{%- from "salt/map.jinja" import saltdata %}

{%- for type in ['service', 'timer'] %}
salt-minion-cache-clear-{{ type }}-unit:
  file.{{ 'managed' if saltdata.minion.cachecleaner.enabled is sameas true else 'absent' }}:
    - name:     /etc/systemd/system/salt-minion-cache-clear.{{ type }}
    - user:     root
    - group:    root
    - source:   salt://salt/minion/files/salt-minion-cache-clear.{{ type }}.jinja
    - template: jinja
    - watch_in:
      - module: salt-common-reload-units
{%- endfor %}

salt-minion-cache-clear-timer:
  service.{{ 'running' if saltdata.minion.cachecleaner.enabled is sameas true else 'dead' }}:
    - name:   salt-minion-cache-clear.timer
    - enable: {{ saltdata.minion.cachecleaner.enabled|yaml }}
    - require:
      - module: salt-common-reload-units
    - watch:
      - file: salt-minion-cache-clear-service-unit
      - file: salt-minion-cache-clear-timer-unit

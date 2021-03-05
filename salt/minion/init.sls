{%- from "salt/map.jinja" import saltdata %}

include:
  - salt.common
  - salt.minion.cachecleaner

salt-minion-pkg-dependencies:
  pkg.latest:
    - pkgs: {{ saltdata.minion.pkgs.dependencies|yaml }}
    - require_in:
      - pkg: salt-minion-pkg

salt-minion-pkg:
  pkg.latest:
    - name: {{ saltdata.minion.pkgs.primary }}
    - require:
      - sls: salt.common.pkgrepo

salt-minion-directory-configuration:
  file.{{ 'directory' if saltdata.minion.configuration.mode == 'managed' else 'exists' }}:
    - name:  {{ saltdata.minion.directories.configuration }}/minion.d
    - user:  {{ saltdata.minion.user.name }}
    - group: {{ saltdata.minion.group.name }}
    - mode:  0700
    - require:
      - file: salt-common-directory-configuration

{%- for dir in ['cache', 'persistence', 'pki'] %}
salt-minion-directory-{{ dir }}:
  file.directory:
    - name:  {{ saltdata.minion.directories.get(dir) }}/minion
    - user:  {{ saltdata.minion.user.name }}
    - group: {{ saltdata.minion.group.name }}
    - mode:  0700
    - force: true
    - require:
      - file: salt-common-directory-{{ dir }}
{%- endfor %}

{%- if saltdata.minion.configuration.mode == 'managed' %}
salt-minion-configuration:
  file.serialize:
    - name:      {{ saltdata.minion.directories.configuration }}/minion.d/managed.conf
    - user:      {{ saltdata.minion.user.name }}
    - group:     {{ saltdata.minion.group.name }}
    - mode:      0500
    - formatter: YAML
    - dataset:   {{ saltdata.minion.configuration.data|yaml }}
    - require:
      - file: salt-minion-directory-configuration
    - watch_in:
      - service: salt-minion-service
{%- endif %}

salt-minion-service:
  service.{{ saltdata.minion.service.mode }}:
    - name:   {{ saltdata.minion.service.name }}
    - enable: {{ saltdata.minion.service.enable }}
    - require:
      - sls:  salt.common
      - file: salt-minion-directory-cache
      - file: salt-minion-directory-pki
    - watch:
      - pkg:  salt-minion-pkg-dependencies
      - pkg:  salt-minion-pkg

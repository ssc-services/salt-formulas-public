{% from "salt/map.jinja" import saltdata %}

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
      # TODO: depend on a generic state which abstracts distribution-specific repositories
      - pkgrepo: saltstack-deb-repo

salt-minion-directory-configuration:
  file.{{ 'directory' if saltdata.minion.configuration.mode == 'managed' else 'exists' }}:
    - name:  {{ saltdata.common.directories.configuration }}/minion.d
    - user:  {{ saltdata.minion.user.name }}
    - group: {{ saltdata.minion.group.name }}
    - mode:  0700
    - require:
      - file: salt-common-directory-configuration

{% for dir in ['cache', 'persistence', 'pki'] %}
salt-minion-directory-{{ dir }}:
  file.directory:
    - name:  {{ saltdata.common.directories.get(dir) }}/minion
    - user:  {{ saltdata.minion.user.name }}
    - group: {{ saltdata.minion.group.name }}
    - mode:  0770
    - force: true
    - require:
      - file: salt-common-directory-{{ dir }}
{% endfor %}

{%- if saltdata.minion.configuration.mode == 'managed' %}
salt-minion-configuration:
  file.serialize:
    - name:      {{ saltdata.common.directories.configuration }}/minion.d/managed.conf
    - user:      {{ saltdata.minion.user.name }}
    - group:     {{ saltdata.minion.group.name }}
    - mode:      0500
    - formatter: YAML
    - dataset:   {{ saltdata.minion.configuration|yaml }}
    - require:
      - file: salt-minion-directory-configuration
    - require_in:
      - service: salt-minion-service
    - watch_in:
      - service: salt-minion-service
{%- endif %}

salt-minion-service:
  service.{{ saltdata.minion.service.mode }}:
    - name:   {{ saltdata.minion.service.name }}
    - enable: {{ saltdata.minion.service.enable }}
    - require:
      - pkg:  salt-minion-pkg-dependencies
      - pkg:  salt-minion-pkg
      - sls:  salt.common
      - file: salt-minion-directory-cache
      - file: salt-minion-directory-pki
    - watch:
      - pkg:  salt-minion-pkg-dependencies
      - pkg:  salt-minion-pkg

salt-minion-reload-units:
  module.wait:
    - name: service.systemctl_reload

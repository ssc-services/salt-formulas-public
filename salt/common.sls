{%- from "salt/map.jinja" import saltdata %}

include:
  - salt.common.pkgrepo

salt-common-user:
  user.present:
    - name:          {{ saltdata.common.user.name }}
    - system:        true
    - gid_from_name: true
    - home:          {{ saltdata.common.directories.persistence }}

salt-common-group:
  group.present:
    - name:   {{ saltdata.common.group.name }}
    - system: true
    - require_in:
      - user: salt-common-user

{%- for dir, path in saltdata.common.directories.items() %}
salt-common-directory-{{ dir }}:
  file.directory:
    - name:     {{ path }}
    - user:     {{ saltdata.common.user.name }}
    - group:    {{ saltdata.common.group.name }}
    - mode:     0770
    - makedirs: true
    - require:
      - user:  salt-common-user
      - group: salt-common-group
{%- endfor %}

salt-common-reload-units:
  module.wait:
    - name: service.systemctl_reload

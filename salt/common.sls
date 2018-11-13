{% from "salt/map.jinja" import saltdata %}

# TODO: make this distribution independent & more generic
saltstack-deb-repo:
  pkgrepo.managed:
    - name:       deb http://repo.saltstack.com/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/latest {{ grains['oscodename'] }} main
    - humanname:  SaltStack APT/{{ grains['os'] }} Repository
    - dist:       {{ grains['oscodename'] }}
    - file:       /etc/apt/sources.list.d/saltstack.list
    - key_url:    https://repo.saltstack.com/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/latest/SALTSTACK-GPG-KEY.pub
    - clean_file: true

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

{% for dir, path in saltdata.common.directories.items() %}
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
{% endfor %}

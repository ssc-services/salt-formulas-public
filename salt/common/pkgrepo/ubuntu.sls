{%- from "salt/map.jinja" import saltdata %}

saltstack-deb-repo:
  pkgrepo.managed:
    - name:       deb [ arch={{ grains['osarch'] }} ] {{ saltdata.common.repository.base_url }}/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/{{ saltdata.common.version }} {{ grains['oscodename'] }} main
    - humanname:  SaltStack APT/{{ grains['os'] }} Repository
    - dist:       {{ grains['oscodename'] }}
    - file:       /etc/apt/sources.list.d/saltstack.list
    - key_url:    {{ saltdata.common.repository.base_url }}/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/{{ saltdata.common.version }}/SALTSTACK-GPG-KEY.pub
    - clean_file: true

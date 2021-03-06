{%- from "salt/map.jinja" import saltdata %}

saltstack-deb-repo:
  pkgrepo.managed:
    - name:       deb [ arch={{ grains['osarch'] }} ] http://repo.saltstack.com/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/{{ saltdata.common.version }} {{ grains['oscodename'] }} main
    - humanname:  SaltStack APT/{{ grains['os'] }} Repository
    - dist:       {{ grains['oscodename'] }}
    - file:       /etc/apt/sources.list.d/saltstack.list
    - key_url:    https://repo.saltstack.com/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/latest/SALTSTACK-GPG-KEY.pub
    - clean_file: true

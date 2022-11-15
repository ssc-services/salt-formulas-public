{%- from "salt/map.jinja" import saltdata %}
{%- set keyfile = '/usr/share/keyrings/salt-archive-keyring.gpg' %}

# as SaltStack still uses the deprecated 'apt-key' tool internally, which will stop
# working with Ubuntu 20.20, manage the repo key and sources.list file manually instead
# see also:
# - https://github.com/saltstack/salt/issues/59785
# - https://github.com/saltstack/salt/issues/59456
saltstack-deb-repo-key:
  file.managed:
    - name:        {{ keyfile }}
    - source:      "{{ saltdata.common.repository.base_url.rstrip('/') }}/salt/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/{{ saltdata.common.version }}/salt-archive-keyring.gpg"
    - skip_verify: true
    - user:        root
    - group:       root
    - mode:        0644
    - makedirs:    true

saltstack-deb-repo-file:
  file.managed:
    - name:     /etc/apt/sources.list.d/saltstack.list
    - user:     root
    - group:    root
    - mode:     0644
    - makedirs: true
    - contents: "deb [ arch={{ grains['osarch'] }} signed-by={{ keyfile }} ] {{ saltdata.common.repository.base_url.rstrip('/') }}/salt/py3/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/{{ grains['osarch'] }}/{{ saltdata.common.version }} {{ grains['oscodename'] }} main"

saltstack-deb-repo-refresh:
  module.run:
{%- if 'module.run' in salt['config.get']('use_superseded') %}
    - pkg.refresh_db: []
{%- else %}
    - name: pkg.refresh_db
{%- endif %}
    - onchanges:
      - saltstack-deb-repo-key
      - saltstack-deb-repo-file

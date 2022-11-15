{%- from "salt/map.jinja" import saltdata %}

include:
  - salt.common

salt-master-pkg-dependencies:
  pkg.latest:
    - pkgs: {{ saltdata.master.pkgs.dependencies|yaml }}
    - require_in:
      - pkg: salt-master-pkg

salt-master-pkg:
  pkg.latest:
    - name: {{ saltdata.master.pkgs.primary }}
    - require:
      - sls: salt.common.pkgrepo

salt-master-directory-configuration:
  file.directory:
    - name:  {{ saltdata.master.directories.configuration }}/master.d
    - user:  {{ saltdata.master.user.name }}
    - group: {{ saltdata.master.group.name }}
    - mode:  0700
    - require:
      - file:  salt-common-directory-configuration
      - user:  salt-common-user
      - group: salt-common-group

salt-master-configuration:
  file.serialize:
    - name:      {{ saltdata.master.directories.configuration }}/master.d/managed.conf
    - user:      {{ saltdata.master.user.name }}
    - group:     {{ saltdata.master.group.name }}
    - mode:      0400
    - formatter: YAML
    - dataset:   {{ saltdata.master.configuration.data|yaml }}
    - require:
      - file:  salt-master-directory-configuration
      - user:  salt-common-user
      - group: salt-common-group
    - watch_in:
      - service: salt-master-service

{%- for keytype in ['gpg', 'ssh'] %}
salt-master-directory-{{ keytype }}keys:
  file.directory:
    - name:  {{ saltdata.master.directories.configuration }}/master.{{ keytype }}keys.d
    - user:  {{ saltdata.master.user.name }}
    - group: {{ saltdata.master.group.name }}
    - mode:  0700
    - require:
      - file:  salt-common-directory-configuration
      - user:  salt-common-user
      - group: salt-common-group
    - watch_in:
      - service: salt-master

  {%- for key, value in saltdata.master['keys'][keytype].items() %}
salt-master-keys-{{ keytype }}-key-{{ key }}:
  file.managed:
    - name:       {{ saltdata.master.directories.configuration }}/master.{{ keytype }}keys.d/{{ key }}
    - user:       {{ saltdata.master.user.name }}
    - group:      {{ saltdata.master.group.name }}
    - mode:       0400
    - contents: |
        {{ value }}
    - require:
      - file:  salt-master-directory-{{ keytype }}keys
      - user:  salt-common-user
      - group: salt-common-group
    - watch_in:
      - service: salt-master-service
  {%- endfor %}
{%- endfor %}

salt-master-gpg-agent-configuration:
  file.managed:
    - name:     {{ saltdata.master.directories.configuration }}/master.gpgkeys.d/gpg-agent.conf
    - user:     {{ saltdata.master.user.name }}
    - group:    {{ saltdata.master.group.name }}
    - mode:     0400
    - contents: "pinentry-program {{ saltdata.master.gpg.pinentry_program }}"
    - require:
      - file:  salt-master-directory-gpgkeys
      - user:  salt-common-user
      - group: salt-common-group

# Using base64 dumps for this is quite ugly, there must be better ways to manage GPG keys in Salt, but:
# - states.gpg: can fetch keys only from a keyserver
# - GGP Pillars should be replaced sooner than later with Vault-managed Pillars/credentials anyways
{%- if saltdata.master.options.get('gpg', false) is sameas true %}
  {%- for file in ['pubring.gpg', 'secring.gpg', 'trustdb.gpg'] %}
salt-master-gpg-data-{{ file }}-saltsrc:
  file.decode:
    - name:            {{ saltdata.master.directories.configuration }}/gpgkeys/{{ file }}.saltsrc
    # pulling data in an SLS straight from a Pillar is an exception in this case,
    # as `file.decode` only supports it this way and there's currently no support
    # for "Pillar files". See also:
    # - https://github.com/saltstack/salt/issues/31006
    # - https://github.com/saltstack/salt/issues/18406#issuecomment-146151604
    - contents_pillar: salt:master:gpg:data:{{ file }}
    - encoding_type:   base64
    - require:
      - file: salt-master-directory-gpgkeys

salt-master-gpg-data-{{ file }}:
  file.managed:
    - name:   {{ saltdata.master.directories.configuration }}/gpgkeys/{{ file }}
    - source: {{ saltdata.master.directories.configuration }}/{{ file }}.saltsrc
    - user:   {{ saltdata.master.user.name }}
    - group:  {{ saltdata.master.group.name }}
    - mode:   0400
    - onchanges:
      - file: salt-master-gpg-data-{{ file }}-saltsrc
    - require:
      - file:  salt-master-gpg-data-{{ file }}-saltsrc
      - user:  salt-common-user
      - group: salt-common-group
    - watch_in:
      - service: salt-master-service
  {%- endfor %}
{%- endif %}

salt-master-service-unit-dropin:
  file.managed:
    - name: /etc/systemd/system/salt-master.service.d/managed.conf
    - template: jinja
    - source:   salt://salt/files/salt-master.service.d_managed.conf.jinja
    - user:     {{ saltdata.master.user.name }}
    - group:    {{ saltdata.master.group.name }}
    - mode:     0400
    - makedirs: true
    - watch_in:
      - service: salt-master-service

salt-master-logfile-conflict:
  file.symlink:
    - name:   /var/log/salt/master
    - target: '../private/salt/master'
    - force: yes
    - require:
      - pkg: salt-master-pkg
    - require_in:
      - service: salt-master-service

salt-master-service:
  service.running:
    - name: salt-master
    - enable: true
    - watch:
      - file: salt-master-configuration
      - pkg:  salt-master-pkg-dependencies
      - pkg:  salt-master-pkg

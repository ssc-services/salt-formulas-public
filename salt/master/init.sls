{% from "salt/map.jinja" import saltdata %}

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
    - name:  {{ saltdata.common.directories.configuration }}/master.d
    - user:  {{ saltdata.master.user.name }}
    - group: {{ saltdata.master.group.name }}
    - mode:  0700
    - require:
      - file: salt-common-directory-configuration

salt-master-configuration:
  file.serialize:
    - name:      {{ saltdata.common.directories.configuration }}/master.d/managed.conf
    - user:      {{ saltdata.master.user.name }}
    - group:     {{ saltdata.master.group.name }}
    - mode:      0400
    - formatter: YAML
    - dataset:   {{ saltdata.master.configuration|yaml }}
    - require:
      - file: salt-master-directory-configuration
    - watch_in:
      - service: salt-master-service

{% set components = {
  'cloud': [
    'conf',
    'keys',
    'maps',
    'profiles',
    'providers',
  ],
  'master': [
    'gpgkeys',
    'sshkeys',
  ],
} %}
{% for component, names in components.items() %}
  {% for name in names %}
salt-master-directory-{{ component }}-{{ name }}:
  file.directory:
    - name:  {{ saltdata.common.directories.configuration }}/{{ component }}.{{ name }}.d
    - user:  {{ saltdata.master.user.name }}
    - group: {{ saltdata.master.group.name }}
    - mode:  0700
    - require:
      - file: salt-common-directory-configuration
    - watch_in:
      - service: salt-master
  {% endfor %}
{% endfor %}

{% for key, value in saltdata.cloud['keys'].items() %}
salt-cloud-keys-key-{{ key }}:
  file.managed:
    - name:  {{ saltdata.common.directories.configuration }}/cloud.keys.d/{{ key }}
    - user:  {{ saltdata.master.user.name }}
    - group: {{ saltdata.master.group.name }}
    - mode:  0400
    - contents: |
        {{ value }}
    - require:
      - file: salt-master-directory-cloud-keys
{% endfor %}

{% for keytype in ['gpg', 'ssh'] %}
  {% for key, value in saltdata.master['keys'][keytype].items() %}
salt-master-keys-{{ keytype }}-key-{{ key }}:
  file.managed:
    - name:            {{ saltdata.common.directories.configuration }}/master.{{ keytype }}keys.d/{{ key }}
    - user:            {{ saltdata.master.user.name }}
    - group:           {{ saltdata.master.group.name }}
    - mode:            0400
    - contents: |
        {{ value }}
    - require:
      - file: salt-master-directory-master-{{ keytype }}keys
    - require_in:
      - service: salt-master-service
    - watch_in:
      - service: salt-master-service
  {% endfor %}
{% endfor %}

salt-master-gpg-agent-configuration:
  file.managed:
    - name:     {{ saltdata.common.directories.configuration }}/master.gpgkeys.d/gpg-agent.conf
    - user:     {{ saltdata.master.user.name }}
    - group:    {{ saltdata.master.group.name }}
    - mode:     0400
    - contents: "pinentry-program /usr/bin/pinentry-curses"
    - require:
      - file: salt-master-directory-master-gpgkeys

# Using base64 dumps for this is quite ugly, there must be better ways to manage GPG keys in Salt, but:
# - states.gpg: can fetch keys only from a keyserver
# - GGP Pillars should be replaced sooner than later with Vault-managed Pillars/credentials anyways
{% if saltdata.master.options.get('gpg', false) is sameas true %}
  {% for file in ['pubring.gpg', 'secring.gpg', 'trustdb.gpg'] %}
salt-master-gpg-data-{{ file }}-saltsrc:
  file.decode:
    - name:            {{ saltdata.common.directories.configuration }}/gpgkeys/{{ file }}.saltsrc
    # pulling data in an SLS straight from a Pillar is an exception in this case,
    # as `file.decode` only supports it this way and there's currently no support
    # for "Pillar files". See also:
    # - https://github.com/saltstack/salt/issues/31006
    # - https://github.com/saltstack/salt/issues/18406#issuecomment-146151604
    - contents_pillar: salt:master:gpg:data:{{ file }}
    - encoding_type:   base64
    - require:
      - file: salt-master-directory-master-gpgkeys

salt-master-gpg-data-{{ file }}:
  file.managed:
    - name:   {{ saltdata.common.directories.configuration }}/gpgkeys/{{ file }}
    - source: {{ saltdata.common.directories.configuration }}/{{ file }}.saltsrc
    - user:   {{ saltdata.master.user.name }}
    - group:  {{ saltdata.master.group.name }}
    - mode:   0400
    - onchanges:
      - file: salt-master-gpg-data-{{ file }}-saltsrc
    - require:
      - file: salt-master-gpg-data-{{ file }}-saltsrc
    - require_in:
      - service: salt-master-service
    - watch_in:
      - service: salt-master-service
  {% endfor %}
{% endif %}

{% for key, value in saltdata.cloud.providers.items() %}
salt-cloud-providers-{{ key }}:
  file.serialize:
    - name:      {{ saltdata.common.directories.configuration }}/cloud.providers.d/{{ key }}.conf
    - user:      {{ saltdata.master.user.name }}
    - group:     {{ saltdata.master.group.name }}
    - mode:      0400
    - dataset:   {{ value|yaml }}
    - formatter: YAML
    - require:
      - file: salt-master-directory-cloud-providers
{% endfor %}

{% for key, value in saltdata.cloud.profiles.items() %}
salt-cloud-profiles-{{ key }}:
  file.serialize:
    - name:      {{ saltdata.common.directories.configuration }}/cloud.profiles.d/{{ key }}.conf
    - user:      {{ saltdata.master.user.name }}
    - group:     {{ saltdata.master.group.name }}
    - mode:      0400
    - dataset: |
        {{ value|yaml }}
    - formatter: YAML
    - require:
      - file: salt-master-directory-cloud-profiles
    - require_in:
      - service: salt-master
    - watch_in:
      - service: salt-master
{% endfor %}

salt-master-service-unit-dropin:
  file.managed:
    - name: /etc/systemd/system/salt-master.service.d/managed.conf
    - template: jinja
    - source:   salt://salt/files/salt-master.service.d_managed.conf.jinja
    - user:     {{ saltdata.master.user.name }}
    - group:    {{ saltdata.master.group.name }}
    - mode:     0400
    - makedirs: true
    - require_in:
      - service: salt-master-service
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
    - require:
      - pkg:  salt-master-pkg-dependencies
      - pkg:  salt-master-pkg
      - file: salt-master-configuration
    - watch:
      - pkg: salt-master-pkg-dependencies
      - pkg: salt-master-pkg

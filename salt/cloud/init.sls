{%- from "salt/map.jinja" import saltdata %}

include:
  - salt.common

salt-cloud-pkg-dependencies:
  pkg.latest:
    - pkgs: {{ saltdata.cloud.pkgs.dependencies|yaml }}
    - require_in:
      - pkg: salt-cloud-pkg

salt-cloud-pkg:
  pkg.latest:
    - name: {{ saltdata.cloud.pkgs.primary }}
    - require:
      - sls: salt.common.pkgrepo

{%- set elements = [
  'conf',
  'keys',
  'maps',
  'profiles',
  'providers',
] %}
{%- for element in elements %}
salt-cloud-directory-{{ element }}:
  file.directory:
    - name:  {{ saltdata.cloud.directories.configuration }}/cloud.{{ element }}.d
    - user:  {{ saltdata.cloud.user.name }}
    - group: {{ saltdata.cloud.group.name }}
    - mode:  0700
    - require:
      - file: salt-common-directory-configuration
{%- endfor %}

{%- for key, value in saltdata.cloud['keys'].items() %}
salt-cloud-keys-key-{{ key }}:
  file.managed:
    - name:  {{ saltdata.cloud.directories.configuration }}/cloud.keys.d/{{ key }}
    - user:  {{ saltdata.cloud.user.name }}
    - group: {{ saltdata.cloud.group.name }}
    - mode:  0400
    - contents: |
        {{ value }}
    - require:
      - file: salt-cloud-directory-keys
{%- endfor %}

{%- for key, value in saltdata.cloud.providers.items() %}
salt-cloud-providers-{{ key }}:
  file.serialize:
    - name:      {{ saltdata.cloud.directories.configuration }}/cloud.providers.d/{{ key }}.conf
    - user:      {{ saltdata.cloud.user.name }}
    - group:     {{ saltdata.cloud.group.name }}
    - mode:      0400
    - dataset:   {{ value|yaml }}
    - formatter: YAML
    - require:
      - file: salt-cloud-directory-providers
{%- endfor %}

{%- for key, value in saltdata.cloud.profiles.items() %}
salt-cloud-profiles-{{ key }}:
  file.serialize:
    - name:      {{ saltdata.cloud.directories.configuration }}/cloud.profiles.d/{{ key }}.conf
    - user:      {{ saltdata.cloud.user.name }}
    - group:     {{ saltdata.cloud.group.name }}
    - mode:      0400
    - dataset: |
        {{ value|yaml }}
    - formatter: YAML
    - require:
      - file: salt-cloud-directory-profiles
{%- endfor %}

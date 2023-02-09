{%- set slsid = "salt.common.pkgrepo." ~ salt['grains.get']('os')|lower %}
{%- if salt['state.sls_exists'](slsid) %}
include:
  - {{ slsid }}
{%- endif %}

# https://github.com/saltstack/salt/issues/10852
salt-minion-pkgrepo-include-only-dummy:
  test.nop

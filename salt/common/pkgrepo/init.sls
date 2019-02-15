include:
  - salt.common.pkgrepo.{{ salt['grains.get']('os')|lower }}

# https://github.com/saltstack/salt/issues/10852
salt-minion-pkgrepo-include-only-dummy:
  test.nop

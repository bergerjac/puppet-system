class system (
  $config   = {},
  $use_stages = true,
  $schedule = undef,
) {
  if $use_stages {
    # Ensure that files and directories are created before
    # other resources (like mounts) that may depend on them
    if ! defined(Stage['third']) {
      stage { 'third': before => Stage['main'] }
    }
    # Ensure packages, users and groups are created
    # before other resources that may depend on them
    if ! defined(Stage['second']) {
      stage { 'second': before => Stage['third'] }
    }
    # Ensure providers are set before resources are created
    if ! defined(Stage['first']) {
      stage { 'first':  before => Stage['second'] }
    }
    # Things to do last because the depend on lots of other resources
    if ! defined(Stage['last']) {
      stage { 'last': require => Stage['main'] }
    }

    $execs_stage = last
    $files_stage = third
    $groups_stage = second
    $groups_realize_stage = second
    $mounts_stage = last
    $templates_stage = last
    $schedules_stage = first
    $selbooleans_stage = first
    $packages_stage = second
    $providers_stage = first
    $users_stage = second
    $users_realize_stage = second
    $yumrepos_stage = first
    $yumgroups_stage = second
  } else {
    $execs_stage = main
    $files_stage = main
    $groups_stage = main
    $groups_realize_stage = main
    $mounts_stage = main
    $templates_stage = main
    $schedules_stage = main
    $selbooleans_stage = main
    $packages_stage = main
    $providers_stage = main
    $users_stage = main
    $users_realize_stage = main
    $yumrepos_stage = main
    $yumgroups_stage = main

    # Dependencies:
    # initial from stages:
    # providers, schedules -> yumrepos, selbooleans, groups, users
    #   selbooleans, yumrepos -> yumgroups
    #     yumgroups -> packages
    #       packages, users::realize -> files
    #         files -> augeas, crontabs, facts, hosts, limits, mail, network, services, sshd, sysconfig, sysctl
    #           augeas, crontabs, facts, hosts, limits, mail, network, services, sshd, sysconfig, sysctl -> execs, mounts, templates
    #   groups -> groups::realize
    #     groups::realize -> users::realize
    #   users -> users::realize
    #
    # optimized:
    # providers -> hosts, mail, mounts
    # schedules -> yumrepos, selbooleans, groups, users
    #   selbooleans, yumrepos -> yumgroups
    #     yumgroups -> packages
    #       packages, users::realize -> files
    #         files -> augeas, crontabs, facts, hosts, limits, mail, network, services, sshd, sysconfig, sysctl
    #           augeas, crontabs, facts, hosts, limits, mail, network, services, sshd, sysconfig, sysctl -> execs, templates
    #           hosts, network, services -> mounts
    #   groups -> groups::realize
    #     groups::realize -> users::realize
    #   users -> users::realize
  }

  class { '::system::augeas':
    config => $config['augeas'],
    require => Class['::system::files'],
  }

  class { '::system::crontabs':
    config => $config['crontabs'],
    require => Class['::system::files'],
  }

  class { '::system::execs':
    config => $config['execs'],
    stage  => $execs_stage,
    require => Class['::system::augeas', '::system::crontabs',
      '::system::facts', '::system::hosts', '::system::limits',
      '::system::mail', '::system::network', '::system::services',
      '::system::sshd', '::system::sysconfig', '::system::sysctl'],
  }

  class { '::system::facts':
    config => $config['facts'],
    require => Class['::system::files'],
  }

  class { '::system::files':
    config => $config['files'],
    stage  => $files_stage,
    require => Class['::system::packages', '::system::users::realize'],
  }

  class { '::system::groups':
    config => $config['groups'],
    stage  => $groups_stage,
    require => Class['::system::schedules'],
  }

  class { '::system::groups::realize':
    groups  => $config['realize_groups'],
    stage   => $groups_realize_stage,
    require => Class['::system::groups'],
  }

  class { '::system::hosts':
    config => $config['hosts'],
    require => Class['::system::providers', '::system::files']
  }

  class { '::system::limits':
    config => $config['limits'],
    require => Class['::system::files'],
  }

  class { '::system::mail':
    config => $config['mail'],
    require => Class['::system::providers', '::system::files']
  }

  class { '::system::mounts':
    config => $config['mounts'],
    stage  => $mounts_stage,
    require => Class['::system::providers', '::system::hosts',
      '::system::network', '::system::services']
  }

  include '::system::network'
  Class['::system::files'] -> Class['::system::network']

  class { '::system::packages':
    config  => $config['packages'],
    stage   => $packages_stage,
    require => Class['::system::yumgroups'],
  }

  class { '::system::schedules':
    config => $config['schedules'],
    stage  => $schedules_stage,
  }

  class { '::system::selbooleans':
    config => $config['selbooleana'],
    stage  => $selbooleans_stage,
    require => Class['::system::schedules'],
  }

  class { '::system::services':
    config => $config['services'],
    require => Class['::system::files'],
  }

  class { '::system::sshd':
    config => $config['sshd'],
    require => Class['::system::files'],
  }

  class { '::system::sysconfig':
    config => $config['sysconfig'],
    require => Class['::system::files'],
  }

  class { '::system::sysctl':
    config => $config['sysctl'],
    require => Class['::system::files'],
  }

  class { '::system::templates':
    config => $config['templates'],
    stage  => $templates_stage,
    require => Class['::system::augeas', '::system::crontabs',
      '::system::facts', '::system::hosts', '::system::limits',
      '::system::mail', '::system::network', '::system::services',
      '::system::sshd', '::system::sysconfig', '::system::sysctl'],
  }

  class { '::system::users':
    config  => $config['users'],
    stage   => $users_stage,
    require => Class['::system::groups', '::system::schedules'],
  }

  class { '::system::users::realize':
    users   => $config['realize_users'],
    stage   => $users_realize_stage,
    require => Class['::system::users', '::system::groups::realize'],
  }

  class { '::system::yumgroups':
    config => $config['yumgroups'],
    stage  => $yumgroups_stage,
    require => Class['::system::selbooleans', '::system::yumrepos'],
  }

  class { '::system::yumrepos':
    config  => $config['yumrepos'],
    stage   => $yumrepos_stage,
    require => Class['::system::schedules'],
  }

  class { '::system::providers':
    config => $config['providers'],
    stage  => $providers_stage,
  }
}

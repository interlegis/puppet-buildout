# env.pp
# requires https://github.com/stankevich/puppet-python
#          https://github.com/example42/puppet-wget
#          https://github.com/puppetlabs/puppetlabs-concat
#          https://github.com/puppetlabs/puppetlabs-stdlib

define buildout::env ( $dir        = $buildout::params::dir,
                       $source     = 'http://downloads.buildout.org/2/bootstrap.py',
                       $user       = $buildout::params::user,
                       $group      = $buildout::params::group,
                       $params     = {},
                       $cachefile  = undef,
                     ) {

  include buildout::params

  $sys_packages = [ 'python-setuptools',
                    'python2.7-dev',
                    'python-pkg-resources',
                    'libc6-dev',
                    'gcc-4.4', 'make', 'build-essential',
                    'software-properties-common',
                  ]
  ensure_resource ( 'package', $sys_packages, { 'ensure' => 'installed' } )

  if !defined(Class['python']) {
    class { 'python':
      version    => 'system',
      dev        => true,
      virtualenv => true,
      pip        => true,
    }
  }

  # Clone buildout
  include wget
  file { "${dir}/$name":
    ensure  => directory,
    owner   => $user,
    group   => $group,
  }

  if !defined(File["${dir}/buildout-cache"]) {
    if $cachefile {
      wget::fetch { "buildout-cache-file-for-{$dir}":
        source      => $cachefile,
        destination => "${dir}/buildout-cache.tar.gz",
        user        => $user,
      }
      exec { "untar_buildout_cache_for_${dir}":
        creates => "${dir}/buildout-cache",
        cwd => "${dir}",
        command => "/bin/tar -xvzf buildout-cache.tar.gz",
        subscribe => Wget::Fetch["buildout-cache-file-for-{$dir}"],
        user => $user
      }
      file { "${dir}/buildout-cache":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => 'ug+r',
        require => Exec["untar_buildout_cache_for_${dir}"],
      }
    } else {
      file { [  "${dir}/buildout-cache",
                "${dir}/buildout-cache/eggs",
                "${dir}/buildout-cache/downloads"] :
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => 'ug+r',
      }
    }
  }


  wget::fetch { "bootstrap_$name":
    source      => $source,
    destination => "${dir}/$name/bootstrap.py",
    user        => $user,
    require     => File["${dir}/$name"],
  }

  # Create virtualenv
  python::virtualenv { "${dir}/$name":
    ensure       => present,
    version      => 'system',
    owner        => $user,
    group        => $group,
    cwd          => "${dir}/$name",
    require      => [ File["${dir}/$name"],
                    ],
  }

  exec { "run_bootstrap_$name":
    creates => "${dir}/$name/bin/buildout",
    cwd => "${dir}/$name",
    command => "${dir}/$name/bin/python ${dir}/$name/bootstrap.py",
    subscribe => Wget::Fetch["bootstrap_$name"],
    require =>  [ Python::Virtualenv["${dir}/$name"],
                  Buildout::Cfgfile["buildout_cfg_$name"],
                ],
    user => $user,
  }

  buildout::cfgfile { "buildout_cfg_$name":
    filename => "buildout.cfg",
    dir      => "${dir}/$name",
    user     => $user,
    group    => $group,
    params   => $params,
  }

  exec { "run_buildout_$name":
    cwd => "${dir}/$name",
    command     => "${dir}/$name/bin/buildout -c ${dir}/$name/buildout.cfg",
    subscribe   => [ Exec["run_bootstrap_$name"],
                     Buildout::Cfgfile["buildout_cfg_$name"],
                   ],
    refreshonly => true,
    user        => $user,
    logoutput   => true,
    timeout     => 0,
    notify      => Exec["update_group_permissions_$name"],
    require     => File["${dir}/buildout-cache"],
  }

  exec { "update_group_permissions_$name":
    cwd         => "${dir}/buildout-cache",
    command     => "/bin/chmod g+r -R ${dir}/buildout-cache",
    refreshonly => true,
    logoutput   => true,
  }
  
}

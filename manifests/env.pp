# env.pp
# requires https://github.com/stankevich/puppet-python
#          https://github.com/example42/puppet-wget
#          https://github.com/puppetlabs/puppetlabs-concat

define buildout::env ( $dir       = $buildout::params::dir,
                       $cache_dir = $buildout::params::cache_dir,
                       $source    = $buildout::params::source, 
                       $user      = $buildout::params::user,
                       $group     = $buildout::params::group,
                       $params    = {},
                     ) {

  $sys_packages = [ 'python-setuptools',
                    'python2.7-dev',
                    'python-pkg-resources',
                    'libc6-dev',
                    'gcc-4.4', 'make', 'build-essential',
                    'software-properties-common',
                  ]

  if !defined(Package[$sys_packages]) {
    package { $sys_packages: ensure => "installed" }
  }

  include buildout::params
   
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

  if !defined(File["${dir}/${cache_dir}"]) {
    file { [ "${dir}/${cache_dir}",
             "${dir}/${cache_dir}/eggs",
             "${dir}/${cache_dir}/downloads"] :
      ensure  => directory,
      owner   => $user,
      group   => $group,
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
    require => [ Python::Virtualenv["${dir}/$name"],
                 Concat["${dir}/$name/buildout.cfg"],
               ],
    user => $user,
  }  

  concat { "${dir}/$name/buildout.cfg":
    owner => $user, group => $group, mode => 440,
  }

  concat::fragment { "buildoutcfg_header_$name":
    target  => "${dir}/$name/buildout.cfg",
    content => "# This file is managed by Puppet. Changes will be periodically overwritten.\n\n",
    order   => '01',
  }

  $buildout_default_params = { eggs-directory => "${dir}/${cache_dir}/eggs",
                               download-cache => "${dir}/${cache_dir}/downloads",
                               parts          => "" }   

  $buildout_final_params = merge($buildout_default_params, $buildout_params)
 
  plone::buildoutsection { "buildout_$name":
    section_name => "buildout",
    cfghash      => delete($buildout_final_params,'parts'),
    buildout_dir => "${dir}/$name",
    order        => '02',
  }
  
  concat::fragment { "buildoutcfg_parts_$name":
    target  => "${dir}/$name/buildout.cfg",
    content => "parts = \n",
    order   => '03',
  }

  exec { "run_buildout_$name":
    cwd => "${dir}/$name",
    command => "${dir}/$name/bin/buildout -c ${dir}/$name/buildout.cfg",
    subscribe => [ Exec["run_bootstrap_$name"],
                   File["${dir}/$name/buildout.cfg"],
                 ],
    refreshonly => true,
    user => $user,
    logoutput => true,
    timeout => 0,
  }
  
}

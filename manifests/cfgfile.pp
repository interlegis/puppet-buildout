# cfgfile.pp

define buildout::cfgfile ( $filename   = "$name.cfg",
                           $dir        = $buildout::params::dir,
                           $user       = $buildout::params::user,
                           $group      = $buildout::params::group,
                           $partsext   = false,
                           $params     = {},
                         ) {
  concat { "${dir}/${filename}":
    owner => $user, group => $group, mode => 440,
  }

  concat::fragment { "cfg_header_$name":
    target  => "${dir}/${filename}",
    content => "# This file is managed by Puppet. Changes will be periodically overwritten.\n\n",
    order   => '01',
  }

  $buildout_default_params = { eggs-directory => "${dir}/buildout-cache/eggs",
                               download-cache => "${dir}/buildout-cache/downloads",
                               parts          => "" }

  $buildout_final_params = merge($buildout_default_params, $params)
 
  buildout::section { "buildout_$name":
    section_name => "buildout",
    cfghash      => delete($buildout_final_params,'parts'),
    buildout_dir => $dir,
    cfgfile      => $filename,
    order        => '02',
  }

  concat::fragment { "cfg_parts_$name":
    target  => "${dir}/${filename}",
    content => $partsext ? { false => "parts = \n", true => "parts += \n" },
    order   => '03',
  }


}

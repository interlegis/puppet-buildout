# part.pp

define buildout::part ( $part_name    = $name,
                        $cfghash      = {},
                        $buildout_dir = $buildout::params::dir,
                        $order        = '99',
                        $cfgfile      = 'buildout.cfg',
                      ) {

  concat::fragment { "part_def_$name":
    target  => "${buildout_dir}/${cfgfile}",
    content => "   $part_name\n",
    order   => "04${order}",
  }

  buildout::section { "part_$name":
    section_name => "$part_name",
    cfghash      => $cfghash,
    buildout_dir => "${buildout_dir}",
    order        => "99${order}",
    cfgfile      => $cfgfile,
  }

}

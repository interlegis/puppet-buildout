# part.pp

define buildout::part ( $part_name  = $name,
                        $cfghash    = {},
                        $dir        = $buildout::params::dir,
                        $order      = '99',
                      ) {

  concat::fragment { "part_def_$name":
    target  => "${dir}/buildout.cfg",
    content => "   $part_name\n",
    order   => "04${order}",
  }

  plone::buildoutsection { "part_$name":
    section_name => "$part_name",
    cfghash      => $cfghash,
    buildout_dir => "${dir}",
    order        => "99${order}",
  }

}

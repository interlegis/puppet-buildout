# section.pp

define buildout::section ( $section_name  = $name, 
                           $cfghash       = {},
			   $dir           = $buildout::params::dir,
                           $order         = '99',
                         ) {

  concat::fragment { "buildoutcfg_section_$name":
    target  => "${dir}/buildout.cfg",
    content => template('buildout/buildout.cfg.erb'),
    order   => $order,
  }

}

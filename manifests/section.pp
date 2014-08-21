# section.pp

define buildout::section ( $section_name  = $name, 
                           $cfghash       = {},
			   $buildout_dir  = $buildout::params::dir,
                           $order         = '99',
                           $cfgfile       = 'buildout.cfg',
                         ) {

  concat::fragment { "buildoutcfg_section_$name":
    target  => "${buildout_dir}/${cfgfile}",
    content => template('buildout/buildout.cfg.erb'),
    order   => $order,
  }

}

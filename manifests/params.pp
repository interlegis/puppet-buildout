#params.pp

class buildout::params {

  $dir       = '/srv/buildout'
  $source    = 'http://downloads.buildout.org/2/bootstrap.py'
  $user      = 'root'
  $group     = 'root'

}

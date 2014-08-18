# init.pp

class buildout ( $envs = {},
               ) {

  validate_hash ($envs)
  create_resources ( 'buildout::env', $envs ) 

}

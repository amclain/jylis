actor Main
  new create(env: Env) =>
    try
      let auth     = env.root as AmbientAuth
      let system   = System(ConfigFromCLI(env, env.err)?)
      let database = Database(system)
      let server   = Server(auth, system, database)
      let cluster  = Cluster(auth, system, database)
      system.dispose.setup(database, server, cluster)
      
      env.out.print(Logo())
      env.out.print("advertises cluster address: " + system.config.addr.string())
      env.out.print("serves commands on port:    " + system.config.port)
    end

use "promises"
use crdt = "crdt"
use "resp"

class val System
  let config:  Config
  let dispose: SystemDispose
  let repo:    SystemRepoManager
  let log:     Log
  
  new val create(config': Config) =>
    config  = config'
    dispose = SystemDispose
    repo    = SystemRepoManager(config)
    log     = config.log .> set_sys(repo)

actor SystemDispose
  var _dispose: (Dispose | None) = None
  
  be setup(database: Database, server: Server, cluster: Cluster) =>
    _dispose = Dispose(database, server, cluster) .> on_signal()
  
  be apply() =>
    try (_dispose as Dispose).dispose() end

actor SystemRepoManager is RepoManagerAny
  let _config: Config
  let _core: RepoManagerCore[RepoSYSTEM, RepoSYSTEMHelp]
  
  new create(config': Config) =>
    _config = config'
    _core   = _core.create("SYSTEM", _config.addr.hash64())
  
  be apply(resp: Respond, cmd: Array[String] val) =>
    _core(resp, cmd)
  
  be flush_deltas(fn: _SendDeltasFn) =>
    _core.flush_deltas(fn)
  
  be converge_deltas(deltas: crdt.TokensIterator iso) =>
    _core.converge_deltas(consume deltas)
  
  be clean_shutdown(promise: Promise[None]) =>
    _core.clean_shutdown(promise)
  
  ///
  // System private methods, meant for use only within the jylis server.
  // Generally, the purpose is to fill data that is read-only to the user.
  
  be log(string': String) =>
    let string: String = _config.addr.string().>push(' ').>append(string')
    _core.repo()._inslog(string)
    _core.repo()._trimlog(_config.system_log_trim)

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
  var _dispose_when_ready: Bool = false
  
  be setup(
    database: Database,
    disk: DiskAny,
    server: Server,
    cluster: Cluster)
  =>
    _dispose = Dispose(database, disk, server, cluster) .> on_signal()
    if _dispose_when_ready then apply() end
  
  be apply() =>
    try (_dispose as Dispose).dispose() else _dispose_when_ready = true end

actor SystemRepoManager is RepoManagerAny
  let _config: Config
  let _core: RepoManagerCore[RepoSYSTEM, RepoSYSTEMHelp]
  
  new create(config': Config) =>
    _config = config'
    _core   = _core.create("SYSTEM", _config.addr.hash64())
  
  be apply(resp: Respond, cmd: Array[String] val) =>
    _core(resp, cmd)
  
  be flush_deltas(fn: _NameTokensFn) =>
    _core.flush_deltas(fn)
  
  be converge_deltas(deltas: crdt.TokensIterator iso) =>
    _core.converge_deltas(consume deltas)
  
  be send_data(send_fn: _NameTokensFn) =>
    _core.send_data(send_fn)
  
  be send_history(send_fn: _NameTokensFn) =>
    _core.send_history(send_fn)
  
  be compare_history(
    history: crdt.TokensIterator iso,
    send_fn: _NameTokensFn,
    need_fn: _NameFn)
  =>
    _core.compare_history(consume history, send_fn, need_fn)
  
  be clean_shutdown(promise: Promise[None]) =>
    _core.clean_shutdown(promise)
  
  ///
  // System private methods, meant for use only within the jylis server.
  // Generally, the purpose is to fill data that is read-only to the user.
  
  be log(string': String) =>
    let string: String = _config.addr.string().>push(' ').>append(string')
    _core.repo()._inslog(string)
    _core.repo()._trimlog(_config.system_log_trim)

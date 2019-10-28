
/// 表示 Scope 目前所处的状态
/// 初始状态为 [ScopeStatus.detached]
enum ScopeStatus {
    /// 分离状态
    /// 表示当前 [Scope] 还没有贴附在任何 [ScopeLifeState] 下
    detached,

    /// 贴附状态
    /// 表示当前 [Scope] 已经贴附在某个 [ScopeLifeState] 上
    attached,

    /// 销毁状态
    /// 表示当前 [Scope] 已不再使用
    destroy,
}


mixin ScopeLifeState<T extends Scope> {
    /// 当前生命周期中的 [Scope]
    /// 当第一次获取时，调用 [genScope] 生成指定的 [Scope]
    T _scope;
    T get scope {
        if(_scope == null)
            _scope = genScope();
        assert(_scope != null);
        return _scope;
    }

    /// 生成指定类型的 [Scope]
    T genScope();


    void attach();
}


/// Scope 基类
///
abstract class Scope {

    /// 表示 Scope 当前的状态
    ScopeStatus _scopeStatus = ScopeStatus.detached;
    ScopeStatus get currentStatus => _scopeStatus;

    /// 贴附 Scope
    /// 该方法会启用 Scope
    void _attach() {

    }

    /// 分离 Scope
    ///
    void _detach() {

    }
}


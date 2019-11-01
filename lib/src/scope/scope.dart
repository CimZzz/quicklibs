
/// 表示 Scope 目前所处的状态
/// 初始状态为 [ScopeStatus.detached]
enum ScopeStatus {
    /// 启用状态
    /// 表示当前 [Scope] 还没有被启用
    activated,

    /// 停用状态
    /// 表示当前 [Scope] 还没有被停用
    deactivated,

    /// 销毁状态
    /// 表示当前 [Scope] 已不再使用
    destroy,
}

/// 域消息回调
typedef ScopeMessageCallback = Future Function(dynamic obj);

/// 域消息回调包装器
/// 用来检查消息回调的运行权限
class _ScopeMessageCallbackWrap {
    _ScopeMessageCallbackWrap(this.allowStatus, this.callback);

    final ScopeStatus allowStatus;
    final ScopeMessageCallback callback;
}


/// 域消息回调
typedef ScopeActiveDelayMessageCallback = void Function(Map<dynamic, dynamic>);

/// 广播接收器回调
typedef ScopeBroadcastReceiver = Function(dynamic obj);

typedef ScopeProxyRunnable<T> = Future<T> Function();

/// Scope 基类
/// 作用域 基类
///
abstract class Scope {
    //
    // 根作用域
    //
    //
    static _RootScope _rootScope;
    static Scope get rootScope {
        _rootScope ??= _RootScope();
        return _rootScope;
    }


    //
    // 生命周期状态
    //
    //

    /// 表示 Scope 当前的状态
    ScopeStatus _scopeStatus = ScopeStatus.deactivated;
    ScopeStatus get currentStatus => _scopeStatus;

    /// 启用 Scope
    /// 该方法会激活 Scope 全部功能
    /// 由全局方法调用私有方法的目的是为了确保方法在被继承的过程中
    /// 不被篡改
    static activate(Scope scope) {
        if(scope != rootScope) {
            scope._activate();
        }
    }

    /// 实际启用 Scope 的逻辑
    void _activate() {
        assert(this._scopeStatus != ScopeStatus.destroy);
        if(this._scopeStatus == ScopeStatus.destroy) {
            return;
        }
        this._scopeStatus = ScopeStatus.activated;

        ///
        /// 这里涉及一些处理逻辑
        _flushActiveDelayMessage();
        ///
        this.onActivated();
    }


    /// 停用 Scope
    /// 该方法会禁用 Scope 绝大多数功能
    /// 由全局方法调用私有方法的目的是为了确保方法在被继承的过程中
    /// 不被篡改
    static deactivate(Scope scope) {
        if(scope != rootScope) {
            scope._deactivate();
        }
    }

    /// 实际停用 Scope 的逻辑
    void _deactivate() {
        assert(this._scopeStatus != ScopeStatus.destroy);
        if(this._scopeStatus == ScopeStatus.destroy) {
            return;
        }
        this._scopeStatus = ScopeStatus.deactivated;

        ///
        /// 这里涉及一些处理逻辑
        ///
        this.onDeactivated();
    }


    /// 销毁 Scope
    /// 该方法会回收 Scope 全部资源并将其销毁，不可再用
    /// 由全局方法调用私有方法的目的是为了确保方法在被继承的过程中
    /// 不被篡改
    static destroy(Scope scope) {
        if(scope != rootScope) {
            scope._destroy();
        }
    }

    /// 实际销毁 Scope 的逻辑
    void _destroy() {
        if(this._scopeStatus == ScopeStatus.destroy) {
            return;
        }
        this._scopeStatus = ScopeStatus.destroy;

        ///
        /// 这里涉及一些处理逻辑
        ///
        dropSelf();
        dropChildren();
        _destroyActiveDelay();
        _destroyBroadcast();
        ///
        this.onDestroy();
    }

    //
    // 层次结构
    //
    //

    /// 上级 Scope
    /// 目前上级 Scope 只在向上回溯时起到作用
    Scope _parent;

    /// 子项 Scope 列表
    List<Scope> _children;

    /// 将参数中的 Scope 作为当前 Scope 的子域
    T fork<T extends Scope>(T scope) {
        assert(scope != null);
        assert(scope._scopeStatus != ScopeStatus.destroy);
        assert(_scopeStatus != ScopeStatus.destroy);
        if(scope == null) {
            return null;
        }
        if(scope._scopeStatus == ScopeStatus.destroy) {
            return null;
        }
        if(_scopeStatus == ScopeStatus.destroy) {
            return null;
        }
        scope.dropSelf();
        this._children ??= <Scope>[];
        this._children.add(scope);
        scope._parent = this;
        return scope;
    }

    /// 将自身从上级 Scope 中断开
    void dropSelf() {
        if(_parent != null) {
            _parent._children?.remove(this);
            _parent = null;
        }
    }

    /// 将全部子域与自己断开
    void dropChildren() {
        if(_children != null) {
            List<Scope> temporaryChildren = List.from(_children);
            temporaryChildren.forEach((scope) {
                scope.dropSelf();
            });
        }
    }


    //
    // 消息（重要）
    //
    //

    /// 消息回调路由表
    /// 存放全部关于消息的回调
    Map<dynamic, _ScopeMessageCallbackWrap> _callbackMap;


    /// 注册消息回调路由
    /// 状态权限默认为 [ScopeStatus.deactivated]
    void registerMessageCallback(dynamic key, ScopeMessageCallback callback) {
        registerStatusMessageCallback(key, ScopeStatus.deactivated, callback);
    }

    /// 注册消息回调路由
    void registerStatusMessageCallback(dynamic key, ScopeStatus allowRunStatus, ScopeMessageCallback callback) {
        assert(allowRunStatus != ScopeStatus.destroy);
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        this._callbackMap ??= <dynamic, _ScopeMessageCallbackWrap>{};
        this._callbackMap[key] = _ScopeMessageCallbackWrap(
            allowRunStatus,
            callback
        );
    }

    /// 注销消息回调路由
    void unregisterMessageCallback(dynamic key) {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        if(this._callbackMap != null) {
            this._callbackMap.remove(key);
        }
    }


    /// 分发一次性消息，并且获取处理结果
    /// 当找到可以处理对应消息的消息回调时，将会中断遍历立即返回执行结果（Future）
    /// 默认向下遍历，向上回溯需要手动配置
    /// @params allowTraceBack 表示是否需要向上回溯（只针对直接父域）
    Future dispatchOneTimeMessage(dynamic key, dynamic data, {bool allowTraceBack = false}) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return null;
        }

        return _dispatchOneTimeMessage(key, data, true, allowTraceBack);
    }

    /// 实际分发一次性消息的逻辑
    /// @params allowTraceBack 只有在一次遍历的第一次时有可能为 true，其余情况下均为 false
    Future _dispatchOneTimeMessage(dynamic key, dynamic data, bool isFirstNode, bool allowTraceBack) async {
        // 先看自身是否拥有给定的消息回调
        // 如果找到那么直接可以调用并返回
        final selfCallback = await _getCallbackByKey(key);
        if(selfCallback != null) {
            return _invokeScopeMessageCallback(data, selfCallback);
        }

        // 如果自身无法处理，则会向下追溯寻求解决方法
        if(_children != null) {
            final childrenCopies = List.from(_children);
            for(int i = 0 ; i < childrenCopies.length ; i ++) {
                final childRes = await childrenCopies[i]._dispatchOneTimeMessage(key, data, false);
                // 如果在子项中找到了解决方法，那么会将子域结果返回，
                // 并中断本次回溯
                if(childRes != null) {
                    return childRes;
                }
            }
        }


        // 如果子项没有找到的话，考虑进行向上回溯
        if(allowTraceBack) {
            var tempParent = _parent;
            while(tempParent != null) {
                final callback = await tempParent._getCallbackByKey(key);
                // 如果父域可以处理该消息，那么使用父域的消息回调进行处理
                if(callback != null) {
                    return tempParent._invokeScopeMessageCallback(
                            data, callback);
                }
            }
        }

        return null;
    }

    /// 向下分发消息
    /// 由该 Scope 向自己及其子域分发消息
    Future dispatchMessage(dynamic key, dynamic data) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        return _dispatchMessage(key, data);
    }

    /// 实际向下分发消息的逻辑
    void _dispatchMessage(dynamic key, dynamic data) async {
        final selfCallback = await _getCallbackByKey(key);
        if(selfCallback != null) {
            await _invokeScopeMessageCallback(data, selfCallback);
        }

        if(_children != null) {
            final childrenCopies = List.from(_children);
            for(int i = 0 ; i < childrenCopies.length ; i ++) {
                childrenCopies[i]._dispatchMessage(key, data);
            }
        }
    }

    /// 根据给定的键值找到对应的消息回调
    /// 本方法被标记为 "async" 的原因是为了不阻塞当前执行
    Future<_ScopeMessageCallbackWrap> _getCallbackByKey(dynamic key) async {
        await null;
        final map = this._callbackMap;
        if(map == null) {
            return null;
        }

        return this._callbackMap[key];
    }

    /// 调用消息回调方法。
    /// 根据当前 Scope 的状态决定是否执行回调
    Future _invokeScopeMessageCallback(dynamic data, _ScopeMessageCallbackWrap callback) {
        // 如果消息回调允许的执行状态小于回调载体，表示当前状态不允许调用该消息回调
        // 直接返回 null
        if(callback.allowStatus.index < currentStatus.index) {
            return null;
        }
        return callback.callback(data);
    }

    //
    // 活跃延迟消息（重要）
    //
    // 与域消息不同的是，活跃延迟消息不能跨域，只能作用于本域，
    // 并且只在域处于 [ScopeStatus.activated] 的状态下才会执行，
    // 如果本域处于 [ScopeStatus.deactivated] 状态的话，会将收到的每条消息
    // 收集到表中，直到状态切换至 [ScopeStatus.activated] 时统一执行
    // 如果状态切换至 [ScopeStatus.destroy]，会将之前收集的全部消息移除，
    // 并且不会再接受任何消息
    //

    /// 活动延迟消息维持表
    ///
    /// 在 [ScopeStatus.deactivated] 状态下的活动延迟消息都会被收集到这个表中
    Map<dynamic, dynamic> _activeDelayMap;

    /// 用来判断当前是否正在处理活动延迟消息
    bool _flushingActiveDelayMessage = false;

    /// 活动延迟消息回调
    ScopeActiveDelayMessageCallback _activeDelayCallback;

    /// 注册活动延迟消息回调
    /// 只可注册一次
    void registerActiveDelayCallback(ScopeActiveDelayMessageCallback callback) {
        assert(_scopeStatus != ScopeStatus.destroy);
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        if(_activeDelayCallback == null) {
            _activeDelayCallback = callback;
        }
    }

    /// 释放全部活动延迟消息
    /// 只有在 [ScopeStatus.activated] 状态下才可调用
    void _flushActiveDelayMessage() async {
        assert(_scopeStatus == ScopeStatus.activated);
        if(_flushingActiveDelayMessage) {
            return;
        }
        if(_activeDelayCallback != null && _activeDelayMap != null) {
            _flushingActiveDelayMessage = true;
            final copiesMap = _activeDelayMap;
            _activeDelayMap = null;
            _activeDelayCallback(copiesMap);
            _flushingActiveDelayMessage = false;
            // 如果在处理的过程中，又有新的活动延迟消息的话，
            // 会在下一次执行过程中去处理
            if(_activeDelayMap != null) {
                await null;
                if(_scopeStatus == ScopeStatus.activated) {
                    _flushActiveDelayMessage();
                }
            }
        }
    }

    /// 发送活动延迟消息
    void postActiveDelayMessage(dynamic key, dynamic data) {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        _activeDelayMap ??= <dynamic, dynamic>{};
        _activeDelayMap[key] = data;

        if(_scopeStatus == ScopeStatus.activated) {
            _flushActiveDelayMessage();
        }
    }

    /// 重置活动延迟消息相关资源
    void resetActiveDelay() {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        _flushingActiveDelayMessage = false;
        _activeDelayMap = null;
    }

    /// 销毁活动延迟消息相关资源
    void _destroyActiveDelay() {
        resetActiveDelay();
        _activeDelayCallback = null;
    }


    //
    // 广播（重要）
    // 全局广播，可一对多
    // 广播原理图:
    //                 通过 key                   for-each
    // _broadcastMap -------------> Set<Scope> -------------> _dispatchBroadcast
    //
    // 当第一次通过 Scope 注册广播接收者:
    //
    // 1. 将 Scope 注册到指定 key 下的 Set<Scope> 中
    // 2. 将 ScopeBroadcastReceiver 注册到 Scope 的 _broadcastReceiverMap 中
    //
    // 第二次通过 Scope 注册同样的广播接收者:
    //
    // 直接将 ScopeBroadcastReceiver 注册到 Scope 的 _broadcastReceiverMap 中
    //

    /// 全局广播 Scope 入口
    /// 每个发布的广播都是经由此处发送到每个 Scope 中
    static Map<dynamic, Set<Scope>> _broadcastMap;
    static Map<dynamic, Set<Scope>> get broadcastMap {
        _broadcastMap ??= <dynamic, Set<Scope>>{};
        return _broadcastMap;
    }

    /// 确保指定 Scope 存在于广播 Scope 集合中
    static void _ensureExistBroadcastSet(dynamic key, Scope scope) {
        Set<Scope> scopeSet = broadcastMap.putIfAbsent(key, () => <Scope>{});
        scopeSet.add(scope);
    }

    /// 移除指定 key 下面的指定 Scope
    static void _removeSpecifiedScope(dynamic key, Scope scope) {
        Set<Scope> scopeSet = broadcastMap[key];
        if(scopeSet == null) {
            return null;
        }

        scopeSet.remove(scope);
    }

    /// 发送广播给对应 key 下注册的全部广播接收器
    static void broadcast(dynamic key, dynamic data) async {
        Set<Scope> scopeSet = broadcastMap[key];
        if(scopeSet == null) {
            return null;
        }

        scopeSet.forEach((scope) async {
            await scope._dispatchBroadcast(key, data);
        });
    }


    /// 广播接收器路由表
    Map<dynamic, Set<ScopeBroadcastReceiver>> _broadcastReceiverMap;

    /// 注册广播接收器
    /// 如果指定 key 下不存在接收器集合，表示第一次注册该 key 对应的接收器，
    /// 会调用 [_ensureExistBroadcastSet] 方法保证该 Scope 在 [_broadcastMap] 中
    /// 存在对应的映射关系
    void registerBroadcast(dynamic key, ScopeBroadcastReceiver receiver) {
        assert(_scopeStatus != ScopeStatus.destroy);
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        _broadcastReceiverMap ??= <dynamic, Set<ScopeBroadcastReceiver>>{};
        Set<ScopeBroadcastReceiver> receiverSet = _broadcastReceiverMap[key];
        if(receiverSet == null) {
            _ensureExistBroadcastSet(key, this);
            receiverSet = <ScopeBroadcastReceiver>{};
            _broadcastReceiverMap[key] = receiverSet;
        }

        receiverSet.add(receiver);
    }

    /// 注销广播接收器
    /// 如果指定广播接收器的话，则只注销指定的广播接收器，否则会将指定 key 值下全部的广播接收器
    /// 全部注销
    /// @params receiver 指定的广播接收器
    void unregisterBroadcast(dynamic key, {ScopeBroadcastReceiver receiver}) {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        // 如果不存在广播接收器路由表，
        // 间接表示当前没有注册任何广播接收者，
        // 所以什么事都不做
        if(_broadcastReceiverMap == null) {
            return;
        }

        Set<ScopeBroadcastReceiver> receiverSet = _broadcastReceiverMap[key];

        // 如果不存在对应 key 下不存在接收器集合，直接返回
        if(receiverSet == null) {
            return;
        }

        // 判断是否全部注销
        if(receiver == null) {
            // 全部注销
            _broadcastReceiverMap.remove(key);
            _removeSpecifiedScope(key, this);
        }
        else {
            // 注销指定的广播接收器
            receiverSet.remove(receiver);
            if(receiverSet.isEmpty) {
                // 如果接收者集合为空，同样注销
                _broadcastReceiverMap.remove(key);
                _removeSpecifiedScope(key, this);
            }
        }
    }

    /// 将广播事件分发给广播接收器路由表
    void _dispatchBroadcast(dynamic key, dynamic data) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        // 如果不存在广播接收器路由表，
        // 间接表示当前没有注册任何广播接收者，
        // 所以什么事都不做
        if(_broadcastReceiverMap == null) {
            return;
        }

        Set<ScopeBroadcastReceiver> receiverSet = _broadcastReceiverMap[key];

        if(receiverSet != null) {
            receiverSet.forEach((receiver) async {
                await null;
                if(_scopeStatus == ScopeStatus.destroy) {
                    return;
                }
                receiver(data);
            });
        }
    }

    /// 销毁广播接收器相关的资源
    void _destroyBroadcast() {
        if(_broadcastReceiverMap == null) {
            return;
        }
        _broadcastReceiverMap.keys.forEach((key) {
            _removeSpecifiedScope(key, this);
        });
        _broadcastReceiverMap.clear();

        _broadcastReceiverMap = null;
    }

    //
    // 监管 Future（重要）
    //
    //

    /// 代理执行 Future
    /// 当 Scope 状态为销毁状态时返回 null
    Future<T> proxy<T>(ScopeProxyRunnable<T> runnable) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return null;
        }
        var future = runnable();
        final result = await future;
        if(_scopeStatus == ScopeStatus.destroy) {
            return null;
        }
        return result;
    }


    //
    // 子类需要实现的方法
    //
    //

    /// 启用的回调方法
    /// 自定义 Scope 可以在这里处理启用时应做的逻辑
    void onActivated();

    /// 停用的回调方法
    /// 自定义 Scope 可以在这里处理停用时应做的逻辑
    void onDeactivated();

    /// 销毁的回调方法
    /// 自定义 Scope 可以在这里回收额外的一些资源
    void onDestroy();
}

/// 根作用域
class _RootScope extends Scope {
    /// 根作用域永远处于激活状态
    _RootScope() {
        _activate();
    }

    @override
    void onActivated() {
        // TODO: implement onActivated
    }

    @override
    void onDeactivated() {
        // TODO: implement onDeactivated
    }

    @override
    void onDestroy() {
        // TODO: implement onDestroy
    }
}

/// 一般作用域
class GeneralScope extends Scope {
    @override
    void onActivated() {

    }

    @override
    void onDestroy() {

    }

    @override
    void onDeactivated() {

    }
}
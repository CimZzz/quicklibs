
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

/// 异步代理运行回调
typedef ScopeProxyAsyncRunnable<T> = Future<T> Function();

/// 同步代理运行回调
typedef ScopeProxySyncRunnable<T> = T Function();

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

    Scope({this.scopeName, this.scopeId});

    /// Scope 名
    /// 便于调试
    final String scopeName;

    /// Scope Id
    /// 只有指定 id 的 Scope 才可以发送指定消息
    final dynamic scopeId;

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
        _destroyStoredData();
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

    /// 子项 Scope id 映射表
    Map<dynamic, Scope> _scopeIdMap;

    /// 将参数中的 Scope 作为当前 Scope 的子域
    /// * [Scope.rootScope] 不能作为子 Scope
    T fork<T extends Scope>(T scope) {
        assert(scope != null);
        assert(scope._scopeStatus != ScopeStatus.destroy);
        assert(_scopeStatus != ScopeStatus.destroy);
        if(scope == Scope._rootScope) {
            return null;
        }
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
        if(scope.scopeId != null) {
            this._scopeIdMap ??= Map();
            this._scopeIdMap[scope.scopeId] = scope;
        }
        scope._parent = this;
        return scope;
    }

    /// 将自身从上级 Scope 中断开
    void dropSelf() {
        if(_parent != null) {
            _parent._children?.remove(this);
            _parent._scopeIdMap?.remove(this.scopeId);
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
    Future dispatchOneTimeMessage(dynamic key, dynamic data, {bool allowTraceBack = false, bool onlyTraceBack = false}) async {
        return await _dispatchOneTimeMessage(key, data, allowTraceBack, onlyTraceBack);
    }

    /// 实际分发一次性消息的逻辑
    /// @params allowTraceBack 只有在一次遍历的第一次时有可能为 true，其余情况下均为 false
    Future _dispatchOneTimeMessage(dynamic key, dynamic data, bool allowTraceBack, bool onlyTraceBack) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return null;
        }

        // 先看自身是否拥有给定的消息回调
        // 如果找到那么直接可以调用并返回
        final selfCallback = await _getCallbackByKey(key);
        if(selfCallback != null) {
            return _invokeScopeMessageCallback(data, selfCallback);
        }

        // 如果自身无法处理，则会向下追溯寻求解决方法
        // 但是如果只做向上回溯的话，那么该步骤会被忽略
        if(!onlyTraceBack && _children != null) {
            final childrenCopies = List<Scope>.from(_children);
            for(int i = 0 ; i < childrenCopies.length ; i ++) {
                final childRes = await childrenCopies[i]._dispatchOneTimeMessage(key, data, false, false);
                // 如果在子项中找到了解决方法，那么会将子域结果返回，
                // 并中断本次回溯
                if(childRes != null) {
                    return childRes;
                }
            }
        }


        // 如果子项没有找到的话，考虑进行向上回溯
        // 如果只做向上回溯，会无视 allowTraceBack 强行进行向上回溯
        if(onlyTraceBack || allowTraceBack) {
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
        return _dispatchMessage(key, data);
    }

    /// 实际向下分发消息的逻辑
    void _dispatchMessage(dynamic key, dynamic data) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

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

    /// 向上分发消息
    /// 由该 Scope 向父级 Scope 传递消息
    /// @params traceCount 表示向上回溯次数，默认会向上回溯一次
    Future dispatchParentMessage(dynamic key, dynamic data, { int traceCount = 1}) async {
        return await _dispatchParentMessage(key, data, traceCount);
    }

    /// 实际向上分发消息的逻辑
    void _dispatchParentMessage(dynamic key, dynamic data, int traceCount) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        final selfCallback = await _getCallbackByKey(key);
        if(selfCallback != null) {
            await _invokeScopeMessageCallback(data, selfCallback);
        }

        var parent = this._parent;
        int nextTraceCount = traceCount != null ? traceCount - 1 : null;

        if(parent != null && (nextTraceCount == null || (nextTraceCount >= 0))) {
            await parent._dispatchParentMessage(key, data, nextTraceCount);
        }
    }

    /// 分发同代消息
    /// 对自己及同父 Scope 下的表兄弟分发消息
    Future dispatchCousinMessage(dynamic key, dynamic data) async {
        return await _dispatchCousinMessage(key, data);
    }

    /// 实际分发同代消息
    Future _dispatchCousinMessage(dynamic key, dynamic data) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return;
        }

        final parent = this._parent;
        if(parent != null) {
            await parent.dispatchMessage(key, data);
        }
        else {
            final selfCallback = await _getCallbackByKey(key);
            if(selfCallback != null) {
                await _invokeScopeMessageCallback(data, selfCallback);
            }
        }
    }

    /// 分发一次性同代消息
    /// 当找到可以处理对应消息的消息回调时，将会中断遍历立即返回执行结果（Future）
    Future dispatchCousinOneTimeMessage(dynamic key, dynamic data) async {
        return await _dispatchCousinOneTimeMessage(key, data);
    }

    /// 实际分发一次性同代消息
    Future _dispatchCousinOneTimeMessage(dynamic key, dynamic data) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return null;
        }

        final parent = this._parent;
        if(parent != null) {
            return await parent._dispatchOneTimeMessage(key, data, false, false);
        }
        else {
            final selfCallback = await _getCallbackByKey(key);
            if(selfCallback != null) {
                return await _invokeScopeMessageCallback(data, selfCallback);
            }
        }

        return null;
    }

    /// 向指定 id 的子 Scope 分发消息
    /// 如果直接子 Scope 不存在指定 id，可以设置 `onlyAllowDirectChildren = false`
    /// 进行深度遍历.
    Future dispatchSpecifiedMessage(dynamic id, dynamic key, dynamic data, { bool onlyAllowDirectChildren = true } ) async {
        await _dispatchSpecifiedMessage(id, key, data, onlyAllowDirectChildren);
        return;
    }

    /// 实际向指定 id 的子 Scope 分发消息
    Future<bool> _dispatchSpecifiedMessage(dynamic id, dynamic key, dynamic data, bool onlyAllowDirectChildren) async {
        if(_scopeStatus == ScopeStatus.destroy) {
            return false;
        }

        final directlyChild = _scopeIdMap != null ? _scopeIdMap[id] : null;
        if(directlyChild != null) {
            await directlyChild._dispatchMessage(key, data);
            return true;
        }
        else if(_children != null && !onlyAllowDirectChildren) {
            final childrenCopies = List<Scope>.from(_children);
            for(int i = 0 ; i < childrenCopies.length ; i ++) {
                final isFound = await childrenCopies[i]._dispatchSpecifiedMessage(id, key, data, onlyAllowDirectChildren);
                if(isFound) {
                    return true;
                }
            }
        }

        return false;
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
    // 监管（重要）
    //
    //

    /// 代理异步执行 Future
    /// 当 Scope 状态为销毁状态时返回 null
    Future<T> proxyAsync<T>(ScopeProxyAsyncRunnable<T> runnable) async {
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

    /// 代理同步执行回调
    /// 当 Scope 状态为销毁状态时返回 null
    T proxySync<T>(ScopeProxySyncRunnable<T> runnable) {
        if(_scopeStatus == ScopeStatus.destroy) {
            return null;
        }

        return runnable();
    }

    //
    // 状态存储（重要）
    // 可以往 Scope 中存储数据，实现快捷存储的目的
    // 目前可以向自身与父 Scope 中读写数据

    /// 存储数据所用对象
    Map _storedDataMapObj;
    Map get _storedDataMap {
        return this._storedDataMapObj ??= Map();
    }

    /// 获取存储的数据
    /// 如果没有找到对应数据，可以设置 `fromParentIfNotExist = true` 从父 Scope 中
    /// 获取对应 Key 下的数据，如果存在父 Scope 的话；如果父 Scope 仍然不存在数据，可以设置
    /// `fromParentUntilNotExist = true`，如此会一直向上查找，直到找数据或已到达顶级 Scope.
    /// * `untilNotExistParent` 只在 `fromParentIfNotExist = true` 下才生效.
    /// 但是如果自身对应 Key 下存在数据，但是类型不匹配的话，会直接返回 `null`.
    T getStoredData<T>(dynamic key, { bool fromParentIfNotExist = false, bool untilNotExistParent = false } ) {
        dynamic result;
        if(_storedDataMapObj != null) {
            result = _storedDataMap[key];
        }

        if(result == null && fromParentIfNotExist) {
            result = _parent?.getStoredData(
                key,
                fromParentIfNotExist: untilNotExistParent,
                untilNotExistParent: untilNotExistParent
            );
        }

        if(result is T) {
            return result;
        }

        return null;
    }

    /// 设置存储数据
    /// 可以设置 `syncParent = true`，同时会将数据同步到父 Scope 中；若想同步全部父 Scope，
    /// 设置 `untilNotExistParent = true` 会一直向上同步，直到到达顶级 Scope.
    T setStoredData<T>(dynamic key, T data, { bool syncParent = false,  bool untilNotExistParent = false }) {
        _storedDataMap[key] = data;
        if(syncParent) {
            _parent?.setStoredData<T>(
                key,
                data,
                syncParent: untilNotExistParent,
                untilNotExistParent: untilNotExistParent
            );
        }

        return data;
    }

    /// 只设置父 Scope 存储数据，不影响自身
    T setParentStoredData<T>(dynamic key, T data, { bool syncParent = false,  bool untilNotExistParent = false }) {
        return _parent?.setStoredData<T>(
            key,
            data,
            syncParent: syncParent,
            untilNotExistParent: untilNotExistParent
        );
    }

    /// 重置存储所用的全部数据
    /// * 只会重置自身存储的数据，不影响父 Scope 中的数据
    void resetStoredData() {
        if(this._storedDataMapObj != null) {
            this._storedDataMapObj.clear();
            this._storedDataMapObj = null;
        }
    }

    /// 销毁存储所用的全部数据
    /// * 只会销毁自身存储的数据，不影响父 Scope 中的数据
    void _destroyStoredData() {
        resetStoredData();
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
    }

    @override
    void onDeactivated() {
    }

    @override
    void onDestroy() {
    }
}

/// 一般作用域
class GeneralScope extends Scope {
    GeneralScope({String scopeName, dynamic scopeId}) : super(scopeName: scopeName, scopeId: scopeId);

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
import 'package:quicklibs/quicklibs.dart';

void main() {
    example13();
}

/// 测试样例1
/// 使用根 Scope 注册消息监听器
void example1() {
    Scope.rootScope.registerMessageCallback("message", (data) {
        print(data);
    });

    Scope.rootScope.dispatchMessage("message", "hello world");

    Scope.rootScope.unregisterMessageCallback("message");

    Scope.rootScope.registerMessageCallback("message", (data) {
        print("receiver data: $data");
    });

    Scope.rootScope.dispatchMessage("message", "hello world");
}

/// 测试样例2
/// 创建 Scope，并调用方法管理其状态
void example2() {
    // 根 Scope 永远处于 [ScopeStatus.activated] 且不可变，
    // 所以创建 Scope 来进行演示
    final scope = GeneralScope();
    print(scope.currentStatus);
    Scope.activate(scope);
    print(scope.currentStatus);
    Scope.deactivate(scope);
    print(scope.currentStatus);
    Scope.destroy(scope);
    print(scope.currentStatus);
}

/// 测试样例3
/// 创建 Scope，注册不同状态权限的消息接收器，再在不同状态下发送消息
void example3() async {
    final scope = GeneralScope();
    scope.registerStatusMessageCallback("activatedMsg", ScopeStatus.activated, (data) {
        print("receiver ActivateMsg");
    });
    scope.registerMessageCallback("deactivatedMsg", (data) {
        print("receiver DeactivateMsg");
    });

    // 状态权限不允许选择 [ScopeStatus.destroy]，因为在 Scope 被销毁的
    // 情况下，是不能收到任何消息的，所以在内部会 assert 检查设置状态是否为 [ScopeStatus.destroy]
    // scope.registerStatusMessageCallback("destroyMsg", ScopeStatus.destroy, (data) {
    //     print("receiver DestroyMsg");
    // });

    print("activated 状态:");
    Scope.activate(scope);
    await scope.dispatchMessage("activatedMsg", null);
    await scope.dispatchMessage("deactivatedMsg", null);

    print("deactivated 状态:");
    Scope.deactivate(scope);
    await scope.dispatchMessage("activatedMsg", null);
    await scope.dispatchMessage("deactivatedMsg", null);

}


/// 测试样例4
/// 创建 Scope，并将其作为根 Scope 的子域，通过根 Scope 发送消息
void example4() {
    final childScope = GeneralScope();
    Scope.activate(childScope);
    childScope.registerMessageCallback("message", (data) {
        print("child scope receiver data: $data");
    });
    Scope.rootScope.registerMessageCallback("message", (data) {
        print("root receiver data: $data");
    });
    Scope.rootScope.fork(childScope);
    Scope.rootScope.dispatchMessage("message", "hello world");
}



/// 测试样例5
/// 一次性消息
/// 同样创建 Scope，并将其作为根 Scope 的子域，通过根 Scope 发送一次性消息
/// 一次性消息有个特点，可以通过消息获取返回值
void example5() async {
    final childScope = GeneralScope();
    Scope.activate(childScope);
    childScope.registerMessageCallback("message", (data) async {
        print("child scope receiver data: $data");
        return "from child";
    });
    Scope.rootScope.registerMessageCallback("message", (data) async {
        print("root receiver data: $data");
        return "result from root";
    });
    Scope.rootScope.fork(childScope);
    final result = await Scope.rootScope.dispatchOneTimeMessage("message", "hello world");
    print(result);
}

/// 测试样例6
/// 创建 Scope，测试活动延迟消息
///
void example6() {
    final scope = GeneralScope();
    scope.registerActiveDelayCallback((map) {
        print("执行活动延迟消息回调");
        map.forEach((key, value) {
            print("activated: key -> $key, value -> $value");
        });
    });
    scope.postActiveDelayMessage("activeKey1", "activeValue1");
    scope.postActiveDelayMessage("activeKey2", "activeValue2");
    scope.postActiveDelayMessage("activeKey3", "activeValue3");
    scope.postActiveDelayMessage("activeKey4", "activeValue4");
    scope.postActiveDelayMessage("activeKey4", "activeValueRepeat4");
    // 启用 Scope，此时 Scope 应该会自动释放全部的活动延迟消息
    Scope.activate(scope);
    // 在启用状态下，发送的每一条消息都会被立即执行
    scope.postActiveDelayMessage("activeKey1", "hello world");
    print("end");
}

/// 测试样例7
/// 创建 Scope，测试广播
void example7() {
    final scope = GeneralScope();
    scope.registerBroadcast("broadcast", (data) {
        print("scope receiver: $data");
    });

    Scope.rootScope.registerBroadcast("broadcast", (data) {
        print("Root Scope receiver: $data");
    });

    Scope.broadcast("broadcast", "i like fruit!");
}

/// 测试样例8
/// 创建 Scope，测试代理 Future
void example8() async {
    final scope = GeneralScope();

    // 定义三个耗时任务
    Future<String> task1() async {
        await Future.delayed(const Duration(seconds: 1));
        return "task1 completed";
    }

    Future<String> task2() async {
        await Future.delayed(const Duration(seconds: 2));
        return "task2 completed";
    }

    Future<String> task3() async {
        await Future.delayed(const Duration(seconds: 1));
        return "task3 completed";
    }

    // 开始测试倒计时，4秒后销毁 Scope
    Future.delayed(const Duration(seconds: 4), () => Scope.destroy(scope));

    String task1Result = await scope.proxyAsync(task1);
    String task2Result = await scope.proxyAsync(task2);
    String task3Result = await scope.proxyAsync(task3);

    print("task1Result -> $task1Result, task2Result -> $task2Result, task3Result -> $task3Result");
}

/// 测试样例9
/// 创建 Scope，测试向上发布消息
void example9() async {
    // 向根 Scope 注册一个消息回调，实例一个 Scope 作为其
    // 子 Scope 并向上发布消息.
    Scope.rootScope.registerMessageCallback("root", (data) async {
        print(data);
    });

    final scope = GeneralScope();
    Scope.rootScope.fork(scope);
    scope.dispatchParentMessage("root", "hello world");
}

/// 测试样例10
/// 创建 Scope，测试存储数据，以及向上存储数据
void example10() async {
    final grandchild = GeneralScope();
    final child = GeneralScope();
    final self = Scope.rootScope;

    self.fork(child);
    child.fork(grandchild);

    // `syncParent = true`，数据会同步到父 Scope
    // `untilNotExistParent = true`，数据会一直同步到根 Scope
    grandchild.setStoredData("number", "hello world", syncParent: true, untilNotExistParent: true);

    print(grandchild.getStoredData("number"));
    print(child.getStoredData("number"));
    print(self.getStoredData("number"));
}

/// 测试样例11
/// 分发同代消息
/// 向同父 Scope 下的全部子节点分发消息
void example11() async {
    final child1 = GeneralScope();
    final child2 = GeneralScope();
    final self = Scope.rootScope;

    self.fork(child1);
    self.fork(child2);

    child1.registerMessageCallback("child1_callback", (data) async {
        print("child1: $data");
    });

    child2.registerMessageCallback("child2_callback", (data) async {
        print("child2: $data");
    });

    self.dispatchMessage("child1_callback", "由 rootScope 分发的消息");
    self.dispatchMessage("child2_callback", "由 rootScope 分发的消息");
    child1.dispatchCousinMessage("child2_callback", "由 child1 分发的消息");
}

/// 测试样例12
/// 分发一次性同代消息
/// 向同父 Scope 下的子节点分发一次性消息
void example12() async {
    final child1 = GeneralScope();
    final child2 = GeneralScope();
    final self = Scope.rootScope;

    self.fork(child1);
    self.fork(child2);

    child1.registerMessageCallback("child1_callback", (data) async {
        return "child1_data";
    });

    child2.registerMessageCallback("child2_callback", (data) async {
        return "child2_data: " + data;
    });

    print(await child1.dispatchCousinOneTimeMessage("child2_callback", "hello child2"));
}

/// 测试样例13
/// 向指定 id 的 Scope分发消息
void example13() async {
    final child1 = GeneralScope(scopeId: "child1");
    final child2 = GeneralScope(scopeId: "child2");
    final grandchild1 = GeneralScope(scopeId: "grandChild1");
    final self = Scope.rootScope;

    self.fork(child1);
    self.fork(child2);
    child1.fork(grandchild1);


    child1.registerMessageCallback("callback", (data) async {
        print("child1 recv data: $data");
    });

    child2.registerMessageCallback("callback", (data) async {
        print("child2 recv data: $data");
    });

    grandchild1.registerMessageCallback("callback", (data) async {
        print("grandchild1 recv data: $data");
    });

    self.dispatchSpecifiedMessage("child1", "callback", "good child 1");
    self.dispatchSpecifiedMessage("child2", "callback", "good child 2");
    self.dispatchSpecifiedMessage("grandChild1", "callback", "hello grandChild1");
    self.dispatchSpecifiedMessage("grandChild1", "callback", "good grandChild1", onlyAllowDirectChildren: false);
}
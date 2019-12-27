## 1.0.0

- 上传至 pub 库

## 1.0.1

- 完善 time 类

## 1.0.2

- 修改 time parse 关于时区的问题

## 1.0.8

- 新增 intEachList 方法，直接返回 List 类型结果

## 1.0.9

- 新增 Scope 类，实现消息的传递、限定作用域的功能

## 1.1.0

- 修复 Scope 包名路径的问题

## 1.1.1

- 调整代码格式

## 1.1.2

- 调整说明

## 1.1.3

- 缩短说明

## 1.1.4

- 新增同步代理监管

## 1.1.5

- Scope 新增向上发布消息方法

## 1.1.6

- 新增转换对象类型方法

## 1.1.7

- Scope 新增存储数据方法 `StoredData`
- Scope.rootScope 不能成为其他 Scope 的子 Scope

## 1.1.8

- Scope 新增分发同代消息方法
- Scope 新增分发一次性同代消息方法
- Scope 新增向指定 id 的 Scope 分发消息方法

## 1.1.9

- 修复 GeneralScope 的 scopeId 只能是字符串类型的问题，现在其可以指定为 dynamic 类型了

## 1.2.0

- Scope 新增 dispatchChildMessage 方法，可以向子项发送消息了
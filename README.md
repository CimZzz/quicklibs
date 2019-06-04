Dart 快速开发工具库

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## 开始使用

当前最新版本为: 1.0.3

在 "pubspec.yaml" 文件中加入
```yaml
dependencies:
  quicklibs: ^1.0.3
```


## Usage

[简化迭代器](#简化迭代器): 用提供闭包来实现循环每一步控制逻辑

[Time](#time): 提供一系列关于时间的操作，如时间格式化，字符串转时间等方法

### 简化迭代器

闭包命名
```dart
typedef EachBeginCallback<T> = T Function();
typedef EachCallback<T> = Function(T elem);
typedef EachOverCallback<T> = bool Function(T obj);
typedef EachChangeCallback<T> = T Function(T obj);
```

- EachBeginCallback<T> 循环初始化回调
- EachCallback<T> 循环回调
- EachOverCallback<T> 循环条件判断回调
- EachChangeCallback<T> 循环执行末尾回调

以 for 循环为例
```dart
for(var i = 0 ; i < 10 ; i ++) {
	
};
```
将回调带入后
```dart
for(EachBeginCallback; EachOverCallback; EachChangeCallback) {
    final result = EachCallback;
    if(result != null)
    	return result;
}
```

对应的迭代函数为

```dart
dynamic each<T>({
	EachBeginCallback<T> beginCallback,
	EachChangeCallback<T> changeCallback,
	EachOverCallback<T> overCallback,
	EachCallback<T> callback,
}) {
	T obj = beginCallback();
	while(!overCallback(obj)) {
		final val = callback(obj);
		if(val != null)
			return val;
		obj = changeCallback(obj);
	}
}
```

#### 简化整数迭代器

```dart

dynamic intEach(EachCallback<int> callback,{
		int start = 0,
		int end = 0,
		int total = 0,
		EachChangeCallback<int> changeCallback
	});
```

- EachCallback 循环回调
- start 起始下标(可选)
- end 终止下标(可选)
- total 表示循环总数(可选)
- EachChangeCallback 循环执行末尾回调，用于提供自增/自减方法变化下标

举个例子，一个最简单的循环

```dart
loop1() {
	var i = 0;
	intEach((position) {
		//do something
		i += position;
	}, total: 100);
	
	print(i);
}
```

上述程序结果为 4950，等同于 ∑99。

同样也可以写作
```dart
loop2() {
	var i = 0;
	intEach((position) {
		//do something
		i += position;
	}, start: 0, end: 100);
	
	print(i);
}
```

结果同样为 4950

上述两个例子展示了执行整数迭代循环的两种方式，下面总结一下全部的方式

1. 提供 total 参数与 start 参数，表示从 start 对应的下标开始，循环 total 次
2. 提供 start 参数与 end 参数，表示从 start 对应下标开始，到 end 下标终止（遵循 "左闭右开" 原则）



##### changeCallback

整数迭代器会跟传递的参数自动识别迭代的方向（正/负），提供默认的 自增/自减 闭包。

当然，如果普通的自增自减无法满足需求（比如以指数增长），可以通过 changeCallback 来决定增长趋势

```dart
loop3() {
	intEach((position) {
		//do something
		print("curPosition: $position");
	}, total: 100, changeCallback: (position) => position == 0 ? 1 : position * 3);
}
```

上述程序执行结果如下:

```text
curPosition: 0
curPosition: 1
curPosition: 3
curPosition: 9
curPosition: 27
curPosition: 81
```

注意: changeCallback 增长方向要与实际方向一致，否则循环不会执行


#### 中断循环

对于大部分闭包循环来说，中断循环始终是一个烦人的问题。不过通过这个迭代器，只要在迭代回调中返回任意值，可以很轻易的实现中断闭包循环，而这个值还会当做迭代的最终结果返回

如下方一个整数迭代器：

```dart

loop4() {
	var i = 0;
	var j = intEach((position) {
		if(position > 50)
			return i;
		i += position;
	}, total: 100);
	
	print("i: $i, j: $j");
}
```

执行结果为: 

```text
i: 1275, j: 1275
```

### Time

提供了一系列关于操作时间的方法，通过 Time 类来访问其中方法

闭包命名
```dart
typedef TimeFormatCallback = void Function(DateTime, int, StringBuffer);
typedef TimeParseCallback = void Function(_TimeParseBuilder, String);
typedef TimeFormatter = String Function(DateTime);
typedef TimeParser = int Function(String);
```

缺省的时间占位符
- y: 表示年份
- M: 表示月份
- d: 表示天
- H: 表示小时(全时制)
- m: 表示分钟
- s: 表示秒

#### 时间格式化

将 DateTime 按照指定格式转化成字符串

```dart
static String format(
     DateTime dateTime,
     String formatStr,
     {List<TimePlaceholder> otherPlaceholder}
)
```

- dateTime DateTime 实例
- formatStr 格式化字符串，如 "yyyy-MM-dd HH:mm:ss"
- otherPlaceholder 其他自定义时间占位符(可选)

示例如下

```dart
void example1() {
	print(Time.format(DateTime.now(), "yyyy-MM-dd HH:mm:ss"));
}
```

执行结果:
```text
2019-06-04 14:56:14
```

#### 时间格式化方法对象

将格式化方法包装成闭包对象返回，每次调用只需传递 DateTime 作为参数即可

将格式化中一些对象进行复用，优化了执行效率

```dart
static TimeFormatter generateFormatMethod(
    String formatStr,
    {List<TimePlaceholder> otherPlaceholder}
)
```

- formatStr 格式化字符串，如 "yyyy-MM-dd HH:mm:ss"
- otherPlaceholder 其他自定义时间占位符(可选)

返回 TimeFormatter 类型的闭包对象

示例如下

```dart
void example2() {
	final method = Time.generateFormatMethod("yyyy-MM-dd HH:mm:ss");
	print(method(DateTime.now()));
}
```

执行结果:
```text
2019-06-04 14:56:14
```


#### 时间解析方法

将字符串按照指定格式转化为 时间戳（注意不是 DateTime 实例）

注意: 如果源字符串中包含非占位符，用 "\*" 来代替

```dart
static int parse(
    String sourceStr, 
    String formatStr, 
    {
    	List<TimePlaceholder> otherPlaceholder, 
    	bool isSafe = false, 
    	Duration timeZoneOffset
    }
)
```

- sourceStr 源字符串，如 "2019-06-04 15:05:25"
- formatStr 格式化字符串，如 "yyyy\*MM\*dd\*HH\*mm\*ss"
- otherPlaceholder 其他自定义时间占位符(可选)
- isSafe 如果为 true，解析发生异常时返回 null，否则会抛出异常(可选)
- timeZoneOffset 时区偏移量，默认为本地时区(可选)


示例如下:

```dart
void example3() {
	print(Time.parse("2019-06-04 15:05:25", "yyyy*MM*dd*HH*mm*ss"));
}
```

执行结果:

```text
1559631925000 // 本人在东八区，北京时间
```

#### 时间解析方法对象

将解析方法包装成闭包对象返回，每次调用只需传递源字符串作为参数即可

将解析化中一些对象进行复用，优化了执行效率

```dart
static TimeParser generateParseMethod(
    String formatStr, 
    {
    	List<TimePlaceholder> otherPlaceholder, 
    	bool isSafe = false, 
    	Duration timeZoneOffset
    }
)
```

- formatStr 格式化字符串，如 "yyyy\*MM\*dd\*HH\*mm\*ss"
- otherPlaceholder 其他自定义时间占位符(可选)
- isSafe 如果为 true，解析发生异常时返回 null，否则会抛出异常(可选)
- timeZoneOffset 时区偏移量，默认为本地时区(可选)

返回 TimeParser 类型的闭包对象

示例如下:

```dart
void example4() {
	final method = Time.generateParseMethod("yyyy*MM*dd*HH*mm*ss");
	print(method("2019-06-04 15:05:25"));
}
```

执行结果:

```text
1559631925000
```

#### 测量执行时间

在开发测试中，会需要测量某段代码具体的执行时间，来选择最优的算法

提供了一个用来满足这个需求的方法

```dart
static Duration measure(void run())
```

- run 表示执行方法函数闭包

示例如下:

```dart
void example5() {
	final duration = Time.measure(() {
		print("hello world");
	});
	
	print(duration);
}
```

执行结果:

```text
hello world
0:00:00.000369
```

利用这个方法，我们可以来比较一下时间解析方法的效率

```dart
void example6() {
	final loopCount = 10000;
	
	final duration1 = Time.measure(() {
		intEach((position) {
			DateTime.parse("2019-06-04 15:05:25");
		}, total: loopCount);
	});
	
	final duration2 = Time.measure(() {
		intEach((position) {
			Time.parse("2019-06-04 15:05:25", "yyyy*MM*dd*HH*mm*ss");
		}, total: loopCount);
	});
	
	
	final duration3 = Time.measure(() {
		final method = Time.generateParseMethod("yyyy*MM*dd*HH*mm*ss");
		intEach((position) {
			method("2019-06-04 15:05:25");
		}, total: loopCount);
	});
	
	
	print("dart 原生Api解析 $loopCount 次耗时: $duration1");
	print("Time 直接解析 $loopCount 次耗时: $duration2");
	print("Time 生成解析方法解析 $loopCount 次耗时: $duration3");
}
```

执行结果:

```text
dart 原生Api解析 10000 次耗时: 0:00:00.233731
Time 直接解析 10000 次耗时: 0:00:00.089006
Time 生成解析方法解析 10000 次耗时: 0:00:00.012564
```

从结果可见，生成解析方法比原生方法大约快 20 倍左右
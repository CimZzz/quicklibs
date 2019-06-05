Dart 快速开发工具库

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## 开始使用

当前最新版本为: 1.0.8

在 "pubspec.yaml" 文件中加入
```yaml
dependencies:
  quicklibs: ^1.0.8
```

github
```text
https://github.com/CimZzz/quicklibs
```


## Usage

- [迭代器](#迭代器): 用提供闭包来实现循环每一步控制逻辑

- [Time](#time): 提供一系列关于时间的操作，如时间格式化，字符串转时间等方法

- [转换方法](#转换方法): 提供一系列关于转换具体类型的操作

### 迭代器

闭包命名
```dart
typedef EachBeginCallback<T> = T Function();
typedef EachCallback<T> = Function(T elem);
typedef EachJudgeCallback<T> = bool Function(T obj);
typedef EachChangeCallback<T> = T Function(T obj);
typedef EachOverCallback = dynamic Function(dynamic obj);
typedef EachOverAsCallback<T> = T Function(dynamic obj);
```

- EachBeginCallback<T> 为一次循环回调闭包，只在循环开始时执行一次（可选）
- EachCallback<T> 为循环体回调闭包，每次循环均会执行（可选）
- EachJudgeCallback<T> 为判断循环终止回调闭包，当返回 false 时循环终止
- EachChangeCallback<T> 为末尾循环体回调闭包，每次循环体最后执行
- EachOverCallback 处理循环结果闭包回调，一般在循环执行完成后调用
- EachOverAsCallback<T> 处理循环结果闭包回调，一般在循环执行完成后调用，在处理的同时会将结果进行转型


以 for 循环为例（仅仅为参考样例）
```text
for(var i = 0 ; i < 10 ; i ++) {
	
};
```
将回调带入后
```text
for(EachBeginCallback; EachJudgeCallback; EachChangeCallback) {
    final result = EachCallback;
    if(result != null)
    	return EachOverCallback(result);
}
```

#### 迭代构造器 EachBuilder\<T>


提供一系列构造迭代器的方法

```dart
EachBuilder begin(EachBeginCallback<T> beginCallback); //构建一次循环回调闭包

EachBuilder change(EachChangeCallback<T> changeCallback); //构建末尾循环体回调闭包

EachBuilder judge(EachJudgeCallback<T> judgeCallback); //构建判断循环终止回调闭包

EachBuilder call(EachCallback<T> callback); //构建循环体回调闭包

EachBuilder configAll({
    EachBeginCallback<T> beginCallback,
    EachChangeCallback<T> changeCallback,
    EachJudgeCallback<T> judgeCallback,
    EachCallback<T> callback
}); // 一次性配置全部回调（空闭包会被忽略）

void loopOnly(); // 只执行循环不考虑结果

EachResult loop(); // 执行循环返回结果 EachResult

E loopForResult<E>(); // 执行循环直接获取最终结果

List<E> loopForList<E>(); // 执行循环直接获取最终指定类型列表

```

loopOnly 例子如下:

```dart
loop1() {
	final builder = EachBuilder<int>();
	builder.begin(() => 0);
	builder.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => print(position))
		.loopOnly();
}
```

执行结果为:
```text
0
1
2
3
4
``` 

如果循环需要返回值，可以通过 loop 函数来获取循环结果，
至于返回值，可以通过 EachCallback<T> 回调闭包返回，这里分为两种情况:

1. 返回类型为 EachResult 类型，强制中断循环返回 EachResult
2. 返回类型为 非EachResult 类型，将值存入临时的 List 中（不保证下标位置关系），
在循环结束后返回一个包装 List 对象的 EachResult 对象

loop 例子如下:
```dart
loop2() {
	final list = EachBuilder<int>()
			.begin(() => 0)
			.judge((position) => position < 5)
			.change((position) => position + 1)
			.call((position) => position)
			.loop()
			.end();
	
	print(list);
}
```

执行结果为:

```text
[0, 1, 2, 3, 4]
```

或者使用 loopForResult 来实现同样的功能

```dart
loop3() {
	final list = EachBuilder<int>()
		.begin(() => 0)
		.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => position)
		.loopForResult();
	
	print(list);
}
```

同样，loopForList 也能实现同样功能，并且会返回一个明确类型的列表而不是 dynamic 类型的列表

```dart
loop12() {
	final list = EachBuilder<int>()
		.begin(() => 0)
		.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => position)
		.loopForList<int>();
	
	print(list);
}
```

#### 迭代结果 EachResult

如果使用迭代构造器的 loop 方法，则会在执行结束后返回 EachResult 作为循环结果

我们可以操作这个 EachResult 对象来处理返回结果

提供一些处理迭代结果的方法:

```dart
EachResult then(EachOverCallback overCallback); // 追加处理结果回调

T as<T>(EachOverAsCallback<T> overCallback); // 执行一次处理结果回调后返回有具体类型的结果

dynamic end(); // 返回结果
```

注意: 当 EachResult 返回结果后，无法通过任何方式追加处理结果回调

下面这个例子，通过循环产生一个整数数组，然后通过结果处理返回数组之和:

```dart
loop4() {
	final value = EachBuilder<int>()
		.begin(() => 0)
		.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => position)
		.loop() // 返回 EachResult
		.then((list) {
			var sum = 0;
			list.forEach((num) {
				sum += num;
			});
			return sum;
		})
		.end();
	print(value);
}
```

执行结果如下:

```text
10
```

这个处理结果是单链表结构，意味着可以链接多个处理回调。当收到返回结果为 EachResult 类型时，则不在执行下去忽略其余处理回调，如:

```dart
loop5() {
	final value = EachBuilder<int>()
		.begin(() => 0)
		.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => position)
		.loop() // 返回 EachResult
		.then((list) {
		var sum = 0;
		list.forEach((num) {
			sum += num;
		});
		return sum;
		})
		.then((sum){
			return sum * 10;
		})
		.then((sum) {
			return sum + 50;
		})
		.then((sum){
			return EachResult(sum - 1);
		})
		.then((sum) {
			return sum * 10000;
		})
		.end();
	print(value);
}
```

执行结果为:

```text
149
```

如果可以明确最后一个处理回调，建议使用 as 方法

需要注意的是此方法不能返回 EachResult 类型对象

```dart
loop6() {
	final value = EachBuilder<int>()
		.begin(() => 0)
		.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => position)
		.loop() // 返回 EachResult
		.then((list) {
            var sum = 0;
            list.forEach((num) {
                sum += num;
            });
            return sum;
        })
        .then((sum){
            return sum * 10;
        })
        .then((sum) {
            return sum + 50;
        })
        .as((sum){
            return sum - 1;
        });
	print("value type: ${value.runtimeType}, value: $value");
}
```

执行结果为:

```text
value type: int, value: 149
```

#### 简化整数迭代器

常规循环通过构造器方式直接创建太过繁琐复杂，因为我们并不需要那么强的兼容性，
我们这里封装了一种常用的整数迭代器，具体还是使用迭代构造器来实现的，绝大部分迭代逻辑无需自己实现

```dart

/// 快捷生成整数循环迭代器的方法，返回最终结果
/// 通过 [intEachBuilder] 生成整数循环构造器，通过返回的 EachBuilder<int> 获得返回值
dynamic intEach({
		int start = 0,
		int end = 0,
		int total = 0,
		EachCallback<int> callback,
		EachChangeCallback<int> changeCallback
	});

/// 快捷生成整数循环迭代器的方法，返回最终 List 结果
/// 通过 [intEachBuilder] 生成整数循环构造器，通过返回的 EachBuilder<int> 获得返回 List 值
List<E> intEachList<E>({
	int start = 0,
	int end = 0,
	int total = 0,
	EachCallback<int> callback,
	EachChangeCallback<int> changeCallback
	});

/// 快捷生成整数循环迭代器的方法，返回 EachBuilder<int>
EachBuilder<int> intEachBuilder({
		int start = 0,
		int end = 0,
		int total = 0,
		EachCallback<int> callback,
		EachChangeCallback<int> changeCallback
	});
```

- EachCallback 循环回调
- start 起始下标(可选)
- end 终止下标(可选)
- total 表示循环总数(可选)
- EachChangeCallback 循环执行末尾回调，用于提供自增/自减方法变化下标

**以下实例均以 "intEach" 方法为例**

举个例子，一个最简单的循环

```dart
loop7() {
	var i = 0;
	intEach(
		callback: (position) {
		//do something
		i += position;
	}, total: 100);
	
	print(i);
}
```

上述程序结果为 4950，等同于 ∑99。

同样也可以写作
```dart
loop8() {
	var i = 0;
	intEach(
		callback: (position) {
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
loop9() {
	intEach(
		callback: (position) {
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

#### 简化列表迭代器

有些时候原生的 list-for-each 方式并不能满足我们的需求，
我们提供了简化的列表迭代器

```dart
/// 快捷生成列表循环迭代器的方法，返回最终结果
/// 通过 [listEachBuilder] 生成整数循环构造器，通过返回的 EachBuilder<int> 获得返回值
dynamic listEach<T>(List<T> list,{
	EachCallback<T> callback
});

/// 快捷生成列表循环迭代器的方法，返回 EachBuilder<int>
EachBuilder<int> listEachBuilder<T>(List<T> list,{
	EachCallback<T> callback
});
```

下面演示一个简单的列表遍历
```dart
loop13() {
	listEach([1, 2, 3, 4, 5],
	callback: (item) {
		print(item);
	});
}
```

执行结果如下:
```text
1
2
3
4
5
```

我们可以利用 EachBuilder 的特性，来完成列表一些特殊操作，如下

```dart
loop14() {
	var list = ["1", "2", "3", "4", "5"];
	var newList = listEachBuilder(
		list,
		callback: (item) {
			return int.parse(item);
		}
	).loopForList<int>();
	
	print("list type: ${list.runtimeType}, $list");
	print("newList type: ${newList.runtimeType}, $newList");
}
```

执行结果如下:

```text
list type: List<String>, [1, 2, 3, 4, 5]
newList type: List<int>, [1, 2, 3, 4, 5]
```

注意: 前提是在 callback 回调中返回对应的类型，否则会自动筛选列表，将满足指定类型的元素重新组成一个新的列表

#### 中断循环

对于大部分闭包循环来说，中断循环始终是一个烦人的问题。不过通过这个迭代器，只要在迭代回调中返回由 EachResult 包装的值，
可以很轻易的实现中断闭包循环，而这个值还会当做迭代的最终结果返回

注意: 如果返回值不使用 EachResult 包装，则会记录到一个内部的临时列表中，在循环正常结束后将会返回该列表。如果没有返回值则
不会触发任何逻辑

如下方一个整数迭代器：

```dart

loop10() {
	var i = 0;
	var j = 
	intEach(
		callback: (position) {
		if(position > 50)
			return EachResult(i);
		i += position;
	}, total: 100);
	
	print("i: $i, j: $j");
}
```

执行结果为: 

```text
i: 1275, j: 1275
```

#### 快速通过迭代生成列表

在每次迭代返回一个整数值，当循环结束后可以获得由返回值组成的一个列表

如下方一个整数迭代器：

```dart
loop11() {
	var list = 
	intEach(
		callback: (position) {
		return position * 10;
	}, total: 10);
	
	print(list);
}
```

执行结果为:

```text
[0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
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
	intEach(
		callback: (position) {
			DateTime.parse("2019-06-04 15:05:25");
		}, total: loopCount);
	});
	
	final duration2 = Time.measure(() {
	intEach(
		callback: (position) {
			Time.parse("2019-06-04 15:05:25", "yyyy*MM*dd*HH*mm*ss");
		}, total: loopCount);
	});
	
	
	final duration3 = Time.measure(() {
		final method = Time.generateParseMethod("yyyy*MM*dd*HH*mm*ss");
	intEach(
		callback: (position) {
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

### 转换方法

#### 转化动态对象为指定类型列表

```dart
/// 如果 needPicker 为 false 时，只有 obj 是 List<T> 类型才会返回具体值，否则一律返回 null
/// 如果 needPicker 为 true 时，分多种情况拾取指定类型的对象
/// 1. obj 是 Iterable 的子类，遍历迭代器，将所有指定类型的对象放入新的列表中，返回新的列表
/// 2. obj 是指定类型对象，则将对象包装到一个新的列表中，返回新的列表
List<T> convertTypeList<T>(dynamic obj, {bool needPicker = false});
```

示例如下:

```dart
void convert1() {
	final list = [1, "2", 5];
	print(convertTypeList<String>(list, needPicker: false));
}

void convert2() {
	final list = [1, "2", 5];
	print(convertTypeList<String>(list, needPicker: true));
}
```


执行结果为:

```text
null
[2]
```
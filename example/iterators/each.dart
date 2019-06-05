import 'package:quicklibs/quicklibs.dart';

void main() {
}


loop1() {
	final builder = EachBuilder<int>();
	builder.begin(() => 0);
	builder.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => print(position))
		.loopOnly();
}

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

loop3() {
	final list = EachBuilder<int>()
		.begin(() => 0)
		.judge((position) => position < 5)
		.change((position) => position + 1)
		.call((position) => position)
		.loopForResult();
	
	print(list);
}

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

loop7() {
	var i = 0;
	intEach(
		callback: (position) {
			//do something
			i += position;
		}, total: 100);
	
	print(i);
}

loop8() {
	var i = 0;
	intEach(
		callback: (position) {
			//do something
			i += position;
		}, start: 0, end: 100);
	
	print(i);
}

loop9() {
	intEach(
		callback: (position) {
			//do something
			print("curPosition: $position");
		}, total: 100, changeCallback: (position) => position == 0 ? 1 : position * 3);
}

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

loop11() {
	var list =
	intEach(
		callback: (position) {
			return position * 10;
		}, total: 10);
	print(list);
}
import 'package:quicklibs/quicklibs.dart';

void main() {
}

void example1() {
	print(Time.format(DateTime.now(), "yyyy-MM-dd HH:mm:ss"));
}

void example2() {
	final method = Time.generateFormatMethod("yyyy-MM-dd HH:mm:ss");
	print(method(DateTime.now()));
}

void example3() {
	print(Time.parse("2019-06-04 15:05:25", "yyyy*MM*dd*HH*mm*ss"));
}

void example4() {
	final method = Time.generateParseMethod("yyyy*MM*dd*HH*mm*ss");
	print(method("2019-06-04 15:05:25"));
}

void example5() {
	final duration = Time.measure(() {
		print("hello world");
	});
	
	print(duration);
}

void example6() {
	final loopCount = 10000;
	
	final duration1 = Time.measure(() {
		intEach(
			callback: (position) {
				DateTime.parse("2019-06-04 15:05:25");
			},
			total: loopCount);
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
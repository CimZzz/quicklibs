part of 'time.dart';

/// 测量方法体执行时间
Duration _measure(void run()) {
	final start = DateTime.now();
	run();
	return DateTime.now().difference(start);
}
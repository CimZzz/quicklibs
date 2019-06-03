
part 'time_format.dart';
part 'time_measure.dart';

abstract class Time {
	
	/// 方法生成指定 formatStr、otherPlaceholder 的时间格式化方法
	/// 每次调用只需传 DateTime 参数即可生成时间字符串
	static TimeFormatter generateFormatMethod(String formatStr, {List<TimePlaceholder> otherPlaceholder}) =>
		_generateFormatMethod(formatStr, otherPlaceholder);
	
	/// 时间格式化
	/// 根据给定的格式化字符串来格式化当前时间
	static String format(DateTime dateTime, String formatStr, {List<TimePlaceholder> otherPlaceholder}) =>
		_format(dateTime, formatStr, otherPlaceholder);
	
	/// 方法生成指定 formatStr、otherPlaceholder 的时间字符串解析方法
	/// 每次调用只需传 String 参数即可生成 [DateTime] 对象
	/// 如果多次执行同样的格式化字符串，推荐使用此方法优化执行时间
	static TimeParser generateParseMethod(String formatStr, {List<TimePlaceholder> otherPlaceholder, bool isSafe = false}) =>
		_generateParseMethod(formatStr, otherPlaceholder, isSafe);
	
	
	/// 解析时间字符串，如果解析成功返回 [DateTime]
	static DateTime parse(String sourceStr, String formatStr, {List<TimePlaceholder> otherPlaceholder, bool isSafe = false})  =>
		_parse(sourceStr, formatStr, otherPlaceholder, isSafe);
	
	/// 测量方法体执行时间
	static Duration measure(void run()) =>
		_measure(run);
}
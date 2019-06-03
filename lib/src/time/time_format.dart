part of 'time.dart';

/// 时间格式化与时间解析器
/// y: 表示年份
/// M: 表示月份
/// d: 表示天
/// H: 表示小时(全时制)
/// m: 表示分钟
/// s: 表示秒
///
/// 时间格式化回调
/// 是 [TimePlaceholder] 的成员回调函数
typedef TimeFormatCallback = void Function(DateTime, int, StringBuffer);

/// 时间解析回调
typedef TimeParseCallback = void Function(TimeParseBuilder, String);

/// 定义时间格式化方法包装器
/// 可以通过 [TimeFormat.generateFormatMethod] 方法生成指定 formatStr、otherPlaceholder 的时间格式化方法
typedef TimeFormatter = String Function(DateTime);

/// 定义时间字符串解析方法包装器
/// 可以通过 [TimeFormat.generateParseMethod] 方法生成指定 formatStr、otherPlaceholder 的时间解析方法
typedef TimeParser = DateTime Function(String);

/// 时间格式化占位符
/// placeholder: 表示时间占位符，必须为 1 个字符，否则该 Time Place Holder 不会生效
///
class TimePlaceholder {
	const TimePlaceholder({
		String placeholder,
		TimeFormatCallback formatCallback,
		TimeParseCallback parseCallback
	}):
			assert(placeholder.length == 1),
			assert(placeholder != '\\'),
			assert(placeholder != '*'),
			assert(formatCallback != null),
			assert(parseCallback != null),
			this._placeholder = placeholder,
			this._formatCallback = formatCallback,
			this._parseCallback = parseCallback;
	
	final String _placeholder;
	final TimeFormatCallback _formatCallback;
	final TimeParseCallback _parseCallback;
	
	@override
	bool operator ==(other) {
		if(_placeholder.length != 1)
			return false;
		if(other is TimePlaceholder)
			return other._placeholder == this._placeholder;
		else if(other is String)
			return other == this._placeholder;
		else return identical(other, this);
	}
}

/// 时间解析构造器
/// 对指定字段进行赋值，之后统一生成一个 DateTime
class TimeParseBuilder {
	int year;
	int month;
	int day;
	int hour;
	int minute;
	int second;
	int millisecond;
	int microsecond;
	
	TimeParseBuilder() {
		_reset();
	}
	
	void _reset() {
		year = 1970;
		month = day = 1;
		hour = minute = second = millisecond = microsecond = 0;
	}
	
	DateTime _build() => DateTime.utc(
		year,
		month,
		day,
		hour,
		minute,
		second,
		millisecond,
		microsecond
	);
	
	@override
	String toString() {
		return "year: $year, month: $month, day: $day, hour: $hour, minute: $minute, second: $second, millisecond: $millisecond, microsecond: $microsecond";
	}
}

/// 时间拾取器
/// 用于解析时间字符串，标记字符串取值的下标及其长度
class _InnerTimePicker {
	const _InnerTimePicker({this.timePlaceholder, this.startIdx, this.length});
	final TimePlaceholder timePlaceholder;
	final int startIdx;
	final int length;
	
	void _parse(String sourceStr, TimeParseBuilder builder) {
		timePlaceholder._parseCallback(builder, sourceStr.substring(startIdx, startIdx + length));
	}
	
	@override
	bool operator ==(other) {
		if(other is _InnerTimePicker)
			return other.timePlaceholder == this.timePlaceholder;
		else if(other is TimePlaceholder)
			return other == this.timePlaceholder;
		else if(other is String)
			return other == this.timePlaceholder;
		else return identical(other, this);
	}
}

/// 占位符重复异常
/// 用于解析时间格式字符串时，具有同样占位符的 [TimePlaceholder] 出现了多次
class TimePlaceholderDuplicateError implements Exception {
	const TimePlaceholderDuplicateError(this.sourceStr, this.index, this.placeholderStr);
	final String sourceStr;
	final int index;
	final String placeholderStr;
	
	@override
	String toString() {
		return "placeholder $placeholderStr 重复，字符串: $sourceStr，起始位置: $index";
	}
}

class TimePlaceholderUnknownError implements Exception {
	const TimePlaceholderUnknownError(this.sourceStr, this.index, this.char);
	final String sourceStr;
	final int index;
	final String char;
	
	@override
	String toString() {
		return "未知的 placeholder $char，字符串: $sourceStr，起始位置: $index (一般占位符请使用\'*\')";
	}
}

/// #------------------------------------------------------------#
/// ##############################################################
/// 常量和一些通用方法
/// ##############################################################
/// #------------------------------------------------------------#


/// 年份占位符
/// 字符: 'y'
final _yearPlaceholder = TimePlaceholder(
	placeholder: 'y',
	formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
		int year = time.year;
		var reverseList = List.generate(numCount, (position) {
			final lastNum = year % 10;
			year ~/= 10;
			return "$lastNum";
		});
		reverseList.reversed.forEach((char) {
			writeBuffer.write(char);
		});
	},
	parseCallback: (builder, timeStr) {
		builder.year = int.parse(timeStr);
	}
);


/// 月份占位符
/// 字符: 'M'
final _monthPlaceholder = TimePlaceholder(
	placeholder: 'M',
	formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
		int month = time.month;
		var reverseList = List.generate(numCount, (position) {
			final lastNum = month % 10;
			month ~/= 10;
			return "$lastNum";
		});
		reverseList.reversed.forEach((char) {
			writeBuffer.write(char);
		});
	},
	parseCallback: (builder, timeStr) {
		builder.month = int.parse(timeStr);
	}
);


/// 天数占位符
/// 字符: 'd'
final _dayPlaceholder = TimePlaceholder(
	placeholder: 'd',
	formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
		int day = time.day;
		var reverseList = List.generate(numCount, (position) {
			final lastNum = day % 10;
			day ~/= 10;
			return "$lastNum";
		});
		reverseList.reversed.forEach((char) {
			writeBuffer.write(char);
		});
	},
	parseCallback: (builder, timeStr) {
		builder.day = int.parse(timeStr);
	}
);


/// 小时占位符
/// 字符: ''
final _hourPlaceholder = TimePlaceholder(
	placeholder: 'H',
	formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
		int hour = time.hour;
		var reverseList = List.generate(numCount, (position) {
			final lastNum = hour % 10;
			hour ~/= 10;
			return "$lastNum";
		});
		reverseList.reversed.forEach((char) {
			writeBuffer.write(char);
		});
	},
	parseCallback: (builder, timeStr) {
		builder.hour = int.parse(timeStr);
	}
);


/// 分钟占位符
/// 字符: 'm'
final _minutePlaceholder = TimePlaceholder(
	placeholder: 'm',
	formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
		int minute = time.minute;
		var reverseList = List.generate(numCount, (position) {
			final lastNum = minute % 10;
			minute ~/= 10;
			return "$lastNum";
		});
		reverseList.reversed.forEach((char) {
			writeBuffer.write(char);
		});
	},
	parseCallback: (builder, timeStr) {
		builder.minute = int.parse(timeStr);
	}
);


/// 秒占位符
/// 字符: 's'
final _secondPlaceholder = TimePlaceholder(
	placeholder: 's',
	formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
		int second = time.second;
		var reverseList = List.generate(numCount, (position) {
			final lastNum = second % 10;
			second ~/= 10;
			return "$lastNum";
		});
		reverseList.reversed.forEach((char) {
			writeBuffer.write(char);
		});
	},
	parseCallback: (builder, timeStr) {
		builder.second = int.parse(timeStr);
	}
);


/// 默认时间占位符Map
final Map<String, TimePlaceholder> _defaultPlaceholders = {
	_yearPlaceholder._placeholder: _yearPlaceholder,
	_monthPlaceholder._placeholder: _monthPlaceholder,
	_dayPlaceholder._placeholder: _dayPlaceholder,
	_hourPlaceholder._placeholder: _hourPlaceholder,
	_minutePlaceholder._placeholder: _minutePlaceholder,
	_secondPlaceholder._placeholder: _secondPlaceholder,
};

Map<String, TimePlaceholder> _listToMap(List<TimePlaceholder> otherPlaceholder) {
	if(otherPlaceholder == null)
		return null;
	
	final map = Map();
	otherPlaceholder.forEach((placeholder) => map[placeholder._placeholder] = placeholder);
	return map;
}

/// #------------------------------------------------------------#
/// ##############################################################
/// 时间格式化相关方法
/// ##############################################################
/// #------------------------------------------------------------#

/// 方法生成指定 formatStr、otherPlaceholder 的时间格式化方法
/// 每次调用只需传 DateTime 参数即可生成时间字符串
TimeFormatter _generateFormatMethod(String formatStr, List<TimePlaceholder> otherPlaceholder) {
	assert(formatStr != null);
	final map = _listToMap(otherPlaceholder);
	final buffer = StringBuffer();
	final writeBuffer = StringBuffer();
	return (DateTime dateTime) {
		buffer.clear();
		
		_doFormat(dateTime, formatStr, buffer, writeBuffer, map);
		
		return buffer.toString();
	};
}

/// 时间格式化
/// 根据给定的格式化字符串来格式化当前时间
String _format(DateTime dateTime, String formatStr, List<TimePlaceholder> otherPlaceholder) {
	assert(dateTime != null);
	assert(formatStr != null);
	final buffer = StringBuffer();
	final writerBuffer = StringBuffer();
	_doFormat(dateTime, formatStr, buffer, writerBuffer, _listToMap(otherPlaceholder));
	return buffer.toString();
}


/// 真正执行时间格式化逻辑的方法
void _doFormat(DateTime dateTime, String formatStr, StringBuffer buffer, StringBuffer writeBuffer, Map<String, TimePlaceholder> otherPlaceholder) {
	var count = formatStr.length;
	var isLastBackslash = false;
	
	TimePlaceholder lastPlaceholder;
	int placeholderCount = 0;
	
	void checkAndReset() {
		if(lastPlaceholder == null)
			return;
		
		if(placeholderCount != 0) {
			writeBuffer.clear();
			lastPlaceholder._formatCallback(dateTime, placeholderCount, writeBuffer);
			buffer.write(writeBuffer.toString());
		}
		
		lastPlaceholder = null;
		placeholderCount = 0;
	}
	
	
	for(int i = 0 ; i < count ; i ++) {
		String char = formatStr[i];
		if(char == '\\') {
			if(isLastBackslash) {
				isLastBackslash = false;
				buffer.write(char);
			}
			else {
				checkAndReset();
				isLastBackslash = true;
				continue;
			}
		}
		
		final placeholder = otherPlaceholder != null ? otherPlaceholder[char] ?? _defaultPlaceholders[char] : _defaultPlaceholders[char];
		
		if(placeholder != null) {
			if (isLastBackslash) {
				isLastBackslash = false;
				buffer.write(char);
			}
			else {
				if (lastPlaceholder != null) {
					if (placeholder != lastPlaceholder) {
						checkAndReset();
						lastPlaceholder = placeholder;
						placeholderCount = 1;
					}
					else
						placeholderCount ++;
				}
				else {
					lastPlaceholder = placeholder;
					placeholderCount = 1;
				}
			}
			continue;
		}
		
		
		if(isLastBackslash) {
			isLastBackslash = false;
			buffer.write('\\');
			buffer.write(char);
		}
		else {
			checkAndReset();
			buffer.write(char);
		}
	}
	
	checkAndReset();
}


/// #------------------------------------------------------------#
/// ##############################################################
/// 时间解析相关方法
/// ##############################################################
/// #------------------------------------------------------------#

/// 方法生成指定 formatStr、otherPlaceholder 的时间字符串解析方法
/// 每次调用只需传 String 参数即可生成 [DateTime] 对象
/// 如果多次执行同样的格式化字符串，推荐使用此方法优化执行时间
TimeParser _generateParseMethod(String formatStr, List<TimePlaceholder> otherPlaceholder, bool isSafe) {
	assert(formatStr != null);
	final builder = TimeParseBuilder();
	final innerTimePickers = _parseTimePicker(formatStr, _listToMap(otherPlaceholder));
	return (sourceStr) {
		if(innerTimePickers == null)
			return null;
		builder._reset();
		if(isSafe) {
			try {
				return _doParse(sourceStr, TimeParseBuilder(), innerTimePickers);
			}
			catch (e) {
				return null;
			}
		}
		else return _doParse(sourceStr, TimeParseBuilder(), innerTimePickers);
	};
}

/// 解析时间字符串，如果解析成功返回 [DateTime]
DateTime _parse(String sourceStr, String formatStr, List<TimePlaceholder> otherPlaceholder, bool isSafe) {
	assert(formatStr != null);
	if(sourceStr == null)
		return null;
	if(sourceStr.length != formatStr.length)
		return null;
	
	final innerTimePickers = _parseTimePicker(formatStr, _listToMap(otherPlaceholder));
	if(innerTimePickers == null)
		return null;
	
	if(isSafe) {
		try {
			return _doParse(sourceStr, TimeParseBuilder(), innerTimePickers);
		}
		catch (e) {
			return null;
		}
	}
	else return _doParse(sourceStr, TimeParseBuilder(), innerTimePickers);
}


/// 生成时间拾取器的 set
Set<_InnerTimePicker> _parseTimePicker(String formatStr, Map<String, TimePlaceholder> otherPlaceholder) {
	final Set<_InnerTimePicker> set = Set<_InnerTimePicker>();
	int loopCount = formatStr.length;
	
	TimePlaceholder lastPlaceholder;
	int placeholderStartIdx = 0;
	int placeholderCount = 0;
	
	void reset() {
		if(lastPlaceholder == null)
			return;
		
		if(set.contains(lastPlaceholder))
			throw TimePlaceholderDuplicateError(formatStr, placeholderStartIdx, lastPlaceholder._placeholder);
		
		set.add(_InnerTimePicker(
			timePlaceholder: lastPlaceholder,
			startIdx: placeholderStartIdx,
			length: placeholderCount
		));
		
		lastPlaceholder = null;
	}
	
	for(var i = 0 ; i < loopCount ; i ++) {
		String char = formatStr[i];
		
		final placeholder = otherPlaceholder != null ? otherPlaceholder[char] ?? _defaultPlaceholders[char] : _defaultPlaceholders[char];
		if(placeholder != null) {
			if(placeholder != lastPlaceholder) {
				reset();
				lastPlaceholder = placeholder;
				placeholderStartIdx = i;
				placeholderCount = 1;
			}
			else placeholderCount ++;
			continue;
		}
		
		if(char != '*') {
			throw TimePlaceholderUnknownError(formatStr, i, char);
		}
	}
	
	
	reset();
	
	return set.length == 0 ? null : set;
}

/// 真正执行时间字符串解析逻辑的方法
DateTime _doParse(String sourceStr, TimeParseBuilder builder, Set<_InnerTimePicker> innerTimePickers) {
	for (var timePicker in innerTimePickers)
		timePicker._parse(sourceStr, builder);
	
	print(builder);
	return builder._build();
}
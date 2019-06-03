
/// 时间格式化回调
/// 是 [TimePlaceHolder] 的成员回调函数
typedef TimeFormatCallback = void Function(DateTime, int, StringBuffer writeBuffer);

/// 时间解析回调
typedef TimeParseCallback = int Function(String);

/// 时间格式化占位符
/// placeHolder: 表示时间占位符，必须为 1 个字符，否则该 Time Place Holder 不会生效
///
class TimePlaceHolder {
	const TimePlaceHolder({
		String placeHolder,
		TimeFormatCallback formatCallback,
		TimeParseCallback parseCallback
	}):
		assert(placeHolder != 1),
		assert(placeHolder.length == 1),
		assert(formatCallback == null),
		assert(parseCallback == null),
		this._placeHolder = placeHolder,
		this._formatCallback = formatCallback,
		this._parseCallback = parseCallback;

	final String _placeHolder;
	final TimeFormatCallback _formatCallback;
	final TimeParseCallback _parseCallback;
	
	@override
	bool operator ==(other) {
		if(_placeHolder.length != 1)
			return false;
		if(other is TimePlaceHolder)
			return other._placeHolder == this._placeHolder;
		else if(other is String)
			return other == this._placeHolder;
		else return identical(other, this);
	}
}

/// 定义时间格式化方法包装器
/// 可以通过 [generateTimeFormat] 方法生成指定 formatStr、otherPlaceHolder 的时间解析方法
typedef TimeFormatMethod = String Function(DateTime);

/// 时间格式化与
abstract class TimeFormat {
	/// #------------------------------------------------------------#
	/// ##############################################################
	/// 常量和一些通用方法
	/// ##############################################################
	/// #------------------------------------------------------------#
	
	/// 年份占位符
	/// 字符: 'y'
	static final _yearPlaceHolder = TimePlaceHolder(
		placeHolder: 'y',
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
		parseCallback: (timeStr) {
//			return int.parse(timeStr) * ;
		}
	);
	
	
//	/// 月份占位符
//	/// 字符: 'M'
//	static final _monthPlaceHolder = TimePlaceHolder(
//		placeHolder: 'M',
//		formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
//			int month = time.month;
//			var reverseList = List.generate(numCount, (position) {
//				final lastNum = month % 10;
//				month ~/= 10;
//				return "$lastNum";
//			});
//			reverseList.reversed.forEach((char) {
//				writeBuffer.write(char);
//			});
//		}
//	);
//
//
//	/// 天数占位符
//	/// 字符: 'd'
//	static final _dayPlaceHolder = TimePlaceHolder(
//		placeHolder: 'd',
//		formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
//			int day = time.day;
//			var reverseList = List.generate(numCount, (position) {
//				final lastNum = day % 10;
//				day ~/= 10;
//				return "$lastNum";
//			});
//			reverseList.reversed.forEach((char) {
//				writeBuffer.write(char);
//			});
//		}
//	);
//
//
//	/// 小时占位符
//	/// 字符: ''
//	static final _hourPlaceHolder = TimePlaceHolder(
//		placeHolder: 'H',
//		formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
//			int hour = time.hour;
//			var reverseList = List.generate(numCount, (position) {
//				final lastNum = hour % 10;
//				hour ~/= 10;
//				return "$lastNum";
//			});
//			reverseList.reversed.forEach((char) {
//				writeBuffer.write(char);
//			});
//		}
//	);
//
//
//	/// 分钟占位符
//	/// 字符: 'm'
//	static final _minutePlaceHolder = TimePlaceHolder(
//		placeHolder: 'm',
//		formatCallback: (DateTime time, int numCount, StringBuffer writeBuffer)  {
//			int minute = time.minute;
//			var reverseList = List.generate(numCount, (position) {
//				final lastNum = minute % 10;
//				minute ~/= 10;
//				return "$lastNum";
//			});
//			reverseList.reversed.forEach((char) {
//				writeBuffer.write(char);
//			});
//		}
//	);
	
	
	/// 秒占位符
	/// 字符: 's'
	static final _secondPlaceHolder = TimePlaceHolder(
		placeHolder: 's',
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
		}
	);
	
	
	/// 默认时间占位符Map
	static final Map<String, TimePlaceHolder> _defaultPlaceHolders = {
		_yearPlaceHolder._placeHolder: _yearPlaceHolder,
//		_monthPlaceHolder._placeHolder: _monthPlaceHolder,
//		_dayPlaceHolder._placeHolder: _dayPlaceHolder,
//		_hourPlaceHolder._placeHolder: _hourPlaceHolder,
//		_minutePlaceHolder._placeHolder: _minutePlaceHolder,
//		_secondPlaceHolder._placeHolder: _secondPlaceHolder,
	};
	
	static Map<String, TimePlaceHolder> _listToMap(List<TimePlaceHolder> otherPlaceHolder) {
		if(otherPlaceHolder == null)
			return null;
		
		final map = Map();
		otherPlaceHolder.forEach((placeHolder) => map[placeHolder._placeHolder] = placeHolder);
		return map;
	}
	
	/// #------------------------------------------------------------#
	/// ##############################################################
	/// 时间格式化相关方法
	/// ##############################################################
	/// #------------------------------------------------------------#
	
	/// 方法生成指定 formatStr、otherPlaceHolder 的时间格式化方法
	/// 每次调用只需传 DateTime 参数即可生成时间字符串
	TimeFormatMethod generateMethod(String formatStr, [List<TimePlaceHolder> otherPlaceHolder, StringBuffer buffer, StringBuffer writeBuffer]) {
		final map = _listToMap(otherPlaceHolder);
		return (DateTime dateTime) {
			if(buffer != null)
				buffer.clear();
			
			final tempBuffer = buffer ?? StringBuffer();
			final tempWriteBuffer = writeBuffer ?? StringBuffer();
			
			_doFormat(dateTime, formatStr, tempBuffer, tempWriteBuffer, map);
			
			return buffer.toString();
		};
	}
	
	/// 时间格式化
	/// 根据给定的格式化字符串来格式化当前时间
	/// y: 表示年份
	/// M: 表示月份
	/// d: 表示天
	/// H: 表示小时(全时制)
	/// m: 表示分钟
	/// s: 表示秒
	static String format(DateTime dateTime, String formatStr, [List<TimePlaceHolder> otherPlaceHolder]) {
		assert(dateTime != null);
		assert(formatStr != null);
		final buffer = StringBuffer();
		final writerBuffer = StringBuffer();
		_doFormat(dateTime, formatStr, buffer, writerBuffer, _listToMap(otherPlaceHolder));
		return buffer.toString();
	}
	
	
	/// 真正执行时间格式化逻辑的方法
	static void _doFormat(DateTime dateTime, String formatStr, StringBuffer buffer, StringBuffer writeBuffer, Map<String, TimePlaceHolder> otherPlaceHolder) {
		var count = formatStr.length;
		var isLastBackslash = false;
		
		TimePlaceHolder lastPlaceHolder;
		int placeHolderCount = 0;
		
		void checkAndReset() {
			if(lastPlaceHolder == null)
				return;
			
			if(placeHolderCount != 0) {
				writeBuffer.clear();
				lastPlaceHolder._formatCallback(dateTime, placeHolderCount, writeBuffer);
				buffer.write(writeBuffer.toString());
			}
			
			lastPlaceHolder = null;
			placeHolderCount = 0;
		}
		
		
		
		bool checkPlaceHolder(TimePlaceHolder timePlaceHolder, String char) {
			if(timePlaceHolder == null)
				return false;
			
			if(timePlaceHolder == char) {
				if(isLastBackslash) {
					isLastBackslash = false;
					buffer.write(char);
				}
				else {
					if(lastPlaceHolder != null) {
						if(timePlaceHolder != lastPlaceHolder) {
							checkAndReset();
							lastPlaceHolder = timePlaceHolder;
							placeHolderCount = 1;
						}
						else placeHolderCount ++;
					}
					else {
						lastPlaceHolder = timePlaceHolder;
						placeHolderCount = 1;
					}
				}
				
				return true;
			}
			else return false;
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
			
			if(checkPlaceHolder(_defaultPlaceHolders[char], char))
				continue;
			
			if(checkPlaceHolder(_defaultPlaceHolders[char], char))
				continue;
			
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

	///
	DateTime parse(String sourceStr, String formatStr, [List<TimePlaceHolder> otherPlaceHolder]) {
		assert(formatStr != null);
		if(sourceStr == null)
			return null;
		if(sourceStr.length != formatStr.length)
			return null;
		
		
	}
}








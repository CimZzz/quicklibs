import 'package:quicklibs/src/converts/convert_list.dart';

typedef EachBeginCallback<T> = T Function();
typedef EachCallback<T> = Function(T elem);
typedef EachJudgeCallback<T> = bool Function(T obj);
typedef EachChangeCallback<T> = T Function(T obj);
typedef EachOverCallback = dynamic Function(dynamic obj);
typedef EachOverAsCallback<T> = T Function(dynamic obj);

int _defaultIncrementChangeCallback(int obj) => obj + 1;
int _defaultReduceChangeCallback(int obj) => obj - 1;


/// 基础循环逻辑函数
/// beginCallback 为一次循环回调闭包，只在循环开始时执行一次（可选）
/// changeCallback 为末尾循环体回调闭包，每次循环体最后执行
/// judgeCallback 为判断循环终止回调闭包，当返回 false 时循环终止
/// callback 为循环体回调闭包，每次循环均会执行（可选）
/// isNonValue 为无返回值开关，默认每次循环无返回值，当出现返回值时中断循环
dynamic _each<T, E>({
	EachBeginCallback<T> beginCallback,
	EachChangeCallback<T> changeCallback,
	EachJudgeCallback<T> judgeCallback,
	EachCallback<T> callback,
	bool isNonValue = false
}) {
	List<E> list;
	T obj = beginCallback != null ? beginCallback() : null;
	while(judgeCallback(obj)) {
		if(!isNonValue) {
			final val = callback != null ? callback(obj) : callback;
			if (val != null) {
				if (val is EachResult) {
					return val;
				}
				else {
					if(val is E) {
						list ??= List();
						list.add(val);
					}
				}
			}
		}
		else if(callback != null) {
			if(callback(obj) != null)
				return null;
		}
		obj = changeCallback(obj);
	}
	return list;
}

/// 循环结果类
/// 如果在循环中返回的是此类，则直接终止循环
/// 如果在此类内部执行 then 函数时返回此类，则会忽略后续全部 then 函数
class EachResult {
	EachResult(dynamic value): this._value = value;
	dynamic _value;
	bool isEnd = false;
	
	EachResult then(EachOverCallback overCallback) {
		if(isEnd)
			return this;
		assert(overCallback != null);
		final newValue = overCallback(this._value);
		if(newValue is EachResult) {
			isEnd = true;
			this._value = newValue._value;
		}
		else this._value = newValue;
		return this;
	}
	
	
	T as<T>(EachOverAsCallback<T> overCallback) {
		if(isEnd)
			return this._value is T ? this._value : null;
		isEnd = true;
		final newValue = overCallback(this._value);
		assert(newValue is! EachResult);
		this._value = newValue;
		return newValue;
	}
	
	
	dynamic end() {
		isEnd = true;
		return this._value;
	}
}

/// 循环类构造器
/// 处理循环主要逻辑
/// 使用前首先需要先配置循环所需闭包函数，其中
/// beginCallback 为一次循环回调闭包，只在循环开始时执行一次（可选）
/// changeCallback 为末尾循环体回调闭包，每次循环体最后执行
/// judgeCallback 为判断循环终止回调闭包，当返回 false 时循环终止
/// callback 为循环体回调闭包，每次循环均会执行（可选）
///
/// 配置完毕后通过 loop / loopOnly 来执行循环
/// 两者区别:
/// loopOnly: 循环结束后无返回
/// loop: 循环结束后返回 EachResult 执行循环后的逻辑
class EachBuilder<T> {
	EachBeginCallback<T> _beginCallback;
	EachChangeCallback<T> _changeCallback;
	EachJudgeCallback<T> _judgeCallback;
	EachCallback<T> _callback;
	
	
	EachBuilder<T> begin(EachBeginCallback<T> beginCallback) {
		this._beginCallback = beginCallback;
		return this;
	}
	
	EachBuilder<T> change(EachChangeCallback<T> changeCallback) {
		this._changeCallback = changeCallback;
		return this;
	}
	
	EachBuilder<T> judge(EachJudgeCallback<T> judgeCallback) {
		this._judgeCallback = judgeCallback;
		return this;
	}
	
	EachBuilder<T> call(EachCallback<T> callback) {
		this._callback = callback;
		return this;
	}
	
	EachBuilder<T> configAll({
		EachBeginCallback<T> beginCallback,
		EachChangeCallback<T> changeCallback,
		EachJudgeCallback<T> judgeCallback,
		EachCallback<T> callback
	}) {
		if(beginCallback != null)
			this._beginCallback = beginCallback;
		if(changeCallback != null)
			this._changeCallback = changeCallback;
		if(judgeCallback != null)
			this._judgeCallback = judgeCallback;
		if(callback != null)
			this._callback = callback;
		return this;
	}
	
	void loopOnly() {
		assert(this._changeCallback != null);
		assert(this._judgeCallback != null);
		
		_each<T, dynamic>(
			beginCallback: this._beginCallback,
			changeCallback: this._changeCallback,
			judgeCallback: this._judgeCallback,
			callback: this._callback,
			isNonValue: true
		);
	}
	
	EachResult loop() {
		assert(this._changeCallback != null);
		assert(this._judgeCallback != null);
		
		final value = _each<T, dynamic>(
			beginCallback: this._beginCallback,
			changeCallback: this._changeCallback,
			judgeCallback: this._judgeCallback,
			callback: this._callback
		);
		
		if(value is EachResult)
			return value;
		else return EachResult(value);
	}
	
	dynamic loopForResult() {
		return loop().end();
	}
	
	List<E> loopForList<E>() {
		assert(this._changeCallback != null);
		assert(this._judgeCallback != null);
		
		var value = _each<T, E>(
			beginCallback: this._beginCallback,
			changeCallback: this._changeCallback,
			judgeCallback: this._judgeCallback,
			callback: this._callback
		);
		
		if(value is EachResult)
			value = value._value;
		
		return convertTypeList<E>(value, needPicker: true);
	}
}

/// 快捷生成整数循环迭代器的方法，返回最终结果
/// 通过 [intEachBuilder] 生成整数循环构造器，通过返回的 EachResult 获得返回值
dynamic intEach({
		int start = 0,
		int end = 0,
		int total = 0,
		EachCallback<int> callback,
		EachChangeCallback<int> changeCallback
	}) {
	final result = intEachBuilder(
		start: start,
		end: end,
		total: total,
		callback: callback,
		changeCallback: changeCallback
	);
	
	if(result == null)
		return null;
	
	return result.loopForResult();
}

/// 快捷生成整数循环迭代器的方法，返回 EachBuilder
EachBuilder<int> intEachBuilder({
		int start = 0,
		int end = 0,
		int total = 0,
		EachCallback<int> callback,
		EachChangeCallback<int> changeCallback
	}) {
	if(total == 0) {
		if(start == end)
			return null;
	}
	
	final startIdx = start;
	final endIdx = total == 0 ? end : startIdx + total;
	final _isAdd = startIdx < endIdx;
	EachChangeCallback<int> _changeCallback;
	if(changeCallback == null) {
		_changeCallback = _isAdd ? _defaultIncrementChangeCallback : _defaultReduceChangeCallback;
	}
	else {
		_changeCallback = changeCallback;
		var testNum = 1;
		var _isTestAdd = _changeCallback(testNum) > testNum;
		
		if(_isAdd != _isTestAdd)
			return null;
	}
	
	return EachBuilder<int>()
		.configAll(
		beginCallback: () => startIdx,
		changeCallback: _changeCallback,
		judgeCallback: (int current) => _isAdd ? current < endIdx : current > endIdx,
		callback: callback,
	);
}



/// 快捷生成列表循环迭代器的方法，返回最终结果
/// 通过 [listEachBuilder] 生成整数循环构造器，通过返回的 EachResult 获得返回值
dynamic listEach<T>(List<T> list,{
	EachCallback<T> callback
}) {
	final result = listEachBuilder(list, callback: callback);
	
	if(result == null)
		return null;
	
	return result.loopForResult();
}

/// 快捷生成列表循环迭代器的方法，返回 EachResult
EachBuilder<int> listEachBuilder<T>(List<T> list,{
	EachCallback<T> callback
}) {
	if(list == null)
		return null;
	
	int count = list.length;
	
	return intEachBuilder(
		total: count,
		callback: (position) {
			return callback(list[position]);
		}
	);
}
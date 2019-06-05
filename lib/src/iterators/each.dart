

typedef EachBeginCallback<T> = T Function();
typedef EachCallback<T> = Function(T elem);
typedef EachJudgeCallback<T> = bool Function(T obj);
typedef EachChangeCallback<T> = T Function(T obj);
typedef EachOverCallback = dynamic Function(dynamic obj);

int _defaultIncrementChangeCallback(int obj) => obj + 1;
int _defaultReduceChangeCallback(int obj) => obj - 1;


/// 基础循环逻辑函数
/// beginCallback 为一次循环回调闭包，只在循环开始时执行一次（可选）
/// changeCallback 为末尾循环体回调闭包，每次循环体最后执行
/// judgeCallback 为判断循环终止回调闭包，当返回 false 时循环终止
/// callback 为循环体回调闭包，每次循环均会执行（可选）
/// isNonValue 为无返回值开关，默认每次循环无返回值，当出现返回值时中断循环
dynamic _each<T>({
	EachBeginCallback<T> beginCallback,
	EachChangeCallback<T> changeCallback,
	EachJudgeCallback<T> judgeCallback,
	EachCallback<T> callback,
	bool isNonValue = false
}) {
	List list;
	T obj = beginCallback != null ? beginCallback() : null;
	while(judgeCallback(obj)) {
		if(!isNonValue) {
			final val = callback != null ? callback(obj) : callback;
			if (val != null) {
				if (val is EachResult) {
					return val;
				}
				else {
					list ??= List();
					list.add(val);
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
	
	
	dynamic finish(EachOverCallback overCallback) {
		return then(overCallback).end();
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
		
		_each<T>(
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
		
		final value = _each<T>(
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
}

/// 整数循环函数
/// 快捷生成整数循环函数的方法
/// 通过 [intEachBuilder] 生成整数循环构造器，通过构造器执行循环获得返回值
dynamic intEach(
	EachCallback<int> callback,{
		int start = 0,
		int end = 0,
		int total = 0,
		EachChangeCallback<int> changeCallback
	}) {
	final builder = intEachBuilder(callback,
		start: start,
		end: end,
		total: total,
		changeCallback: changeCallback
	);
	
	if(builder == null)
		return null;
	
	return builder.loopForResult();
}

/// 整数循环函数构造器
EachBuilder<int> intEachBuilder(
	EachCallback<int> callback,{
		int start = 0,
		int end = 0,
		int total = 0,
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
		judgeCallback: (int current) => _isAdd ? current <= endIdx : current >= endIdx,
		callback: callback,
	);
}




typedef EachBeginCallback<T> = T Function();
typedef EachCallback<T> = Function(T elem);
typedef EachOverCallback<T> = bool Function(T obj);
typedef EachChangeCallback<T> = T Function(T obj);

int _defaultIncrementChangeCallback(int obj) => obj + 1;
int _defaultReduceChangeCallback(int obj) => obj - 1;


/// 简易循环函数
/// [callback] 循环回调函数，当有返回值时中断循环
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

/// 整数循环函数
/// 简化常规自增/自减循环
/// [callback] 循环回调函数，当有返回值时中断循环
dynamic intEach(
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
	
	return each (
		beginCallback: () => startIdx,
		changeCallback: _changeCallback,
		overCallback: (int current) => _isAdd ? current >= endIdx : current <= endIdx,
		callback: callback
	);
}
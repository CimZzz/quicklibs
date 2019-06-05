

/// 将对象转换为具体类型列表
/// 如果 needPicker 为 false 时，只有 obj 是 List<T> 类型才会返回具体值，否则一律返回 null
/// 如果 needPicker 为 true 时，分多种情况拾取指定类型的对象
/// 1. obj 是 Iterable 的子类，遍历迭代器，将所有指定类型的对象放入新的列表中，返回新的列表
/// 2. obj 是指定类型对象，则将对象包装到一个新的列表中，返回新的列表
List<T> convertTypeList<T>(dynamic obj, {bool needPicker = false}) {
	if(obj is List<T>)
		return obj;
	else if(!needPicker)
		return null;
	
	if(obj is Iterable) {
		List<T> list;
		obj.forEach((item) {
			if(item is T) {
				list ??= List<T>();
				list.add(item);
			}
		});
		
		return list;
	}
	
	if(obj is T)
		return [obj];
	
	return null;
}
/// 转换对象为指定类型
/// 如果对象为 null 或者对象类型不匹配则返回 null
T castTo<T>(dynamic obj) {
	if(obj == null || obj is! T) {
		return null;
	}

	return obj;
}
import 'package:quicklibs/quicklibs.dart';
import 'package:quicklibs/src/converts/convert_obj.dart';

void main() {
	convert3();
}

void convert1() {
	final list = [1, "2", 5];
	print(convertTypeList<String>(list, needPicker: false));
}

void convert2() {
	final list = [1, "2", 5];
	print(convertTypeList<String>(list, needPicker: true));
}

/// 转换对象
void convert3() {
	dynamic number = 123;
	print(castTo<String>(number));
	print(castTo<int>(number));
}
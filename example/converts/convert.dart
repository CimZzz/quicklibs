import 'package:quicklibs/quicklibs.dart';

void main() {

}

void convert1() {
	final list = [1, "2", 5];
	print(convertTypeList<String>(list, needPicker: false));
}

void convert2() {
	final list = [1, "2", 5];
	print(convertTypeList<String>(list, needPicker: true));
}
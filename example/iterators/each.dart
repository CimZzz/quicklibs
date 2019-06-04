import 'package:quicklibs/quicklibs.dart';

void main() {
	loop4();
}

loop1() {
	var i = 0;
	intEach((position) {
		//do something
		i += position;
	}, total: 100);
	
	print(i);
}

loop2() {
	var i = 0;
	intEach((position) {
		//do something
		i += position;
	}, start: 0, end: 100);
	
	print(i);
}

loop3() {
	intEach((position) {
		//do something
		print("curPosition: $position");
	}, total: 100, changeCallback: (position) => position == 0 ? 1 : position * 3);
}

loop4() {
	var i = 0;
	var j = intEach((position) {
		if(position > 50)
			return i;
		i += position;
	}, total: 100);
	
	print("i: $i, j: $j");
}
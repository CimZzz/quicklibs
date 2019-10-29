import 'package:quicklibs/quicklibs.dart';



void main() async {
    Scope.rootScope.registerBroadcast("abc", (data) {
        print("receiver $data");
    });
}

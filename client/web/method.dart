import 'app.dart';
import 'member.dart';
import 'package:polymer/polymer.dart';

@CustomTag("dartdoc-method")
class DartdocMethod extends MethodElement {
  DartdocMethod() {
    new PathObserver(this, "!item.isConstructor").bindSync(
        (_) {
          if (!item.isConstructor) {
            createType(item.type, 'dartdoc-method', 'type');
          }
        });
  }
}
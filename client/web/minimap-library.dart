library minimap_library;

import 'package:dartdoc_viewer/item.dart';
import 'package:polymer/polymer.dart';
import 'app.dart' as app;
import 'member.dart';

/// An element in a page's minimap displayed on the right of the page.
@CustomTag("dartdoc-minimap-library")
class MinimapElementLibrary extends MemberElement {
  MinimapElementLibrary() {
    new PathObserver(this, "viewer.currentPage").bindSync(
      (_) {
        notifyProperty(this, #operatorItems);
        notifyProperty(this, #variableItems);
        notifyProperty(this, #functionItems);
        notifyProperty(this, #classItems);
        notifyProperty(this, #typedefItems);
        notifyProperty(this, #errorItems);
        notifyProperty(this, #name);
        notifyProperty(this, #decoratedName);
        notifyProperty(this, #linkHref);
      });
  }

  get item => super.item;
  set item(x) => super.item = x;

  get viewer  => app.viewer;
  @observable get operatorItems => check(() => page.operators.content);
  @observable get variableItems => check(() => page.variables.content);
  @observable get functionItems => check(() => page.functions.content);
  @observable get classItems => check(() => page.classes.content);
  @observable get typedefItems => check(() => page.typedefs.content);
  @observable get errorItems => check(() => page.errors.content);

  get page => viewer.currentPage;
  check(Function f) => page is Library ? f() : [];
  @observable get linkHref => check(() => page.linkHref);
  @observable get name => check(() => page.name);

  @observable decoratedName(thing) =>
      thing == null ? null : thing.decoratedName;

  hideShow(event, detail, target) {
//    shadowRoot.query("#class-minimap").xtag.hideShow();
    var list = shadowRoot.query(target.hash);
    if (list.classes.contains("in")) {
      list.classes.remove("in");
    } else {
      list.classes.add("in");
    }
//    shadowRoot.query("#classes").classes.add("in");
  }

}
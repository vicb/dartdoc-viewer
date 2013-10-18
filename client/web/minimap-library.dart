library minimap_library;

import 'package:dartdoc_viewer/item.dart';
import 'package:polymer/polymer.dart';
import 'app.dart' as app;
import 'member.dart';
import 'dart:html';

/// An element in a page's minimap displayed on the right of the page.
@CustomTag("dartdoc-minimap-library")
class MinimapElementLibrary extends MemberElement {
  MinimapElementLibrary.created() : super.created();

  get observables => concat(super.observables,
    const [#operatorItems, #variableItems, #functionItems,
    #classItems, #typedefItems, #errorItems, #operatorItemsIsNotEmpty,
    #variableItemsIsNotEmpty, #functionItemsIsNotEmpty, #classItemsIsNotEmpty,
    #typedefItemsIsNotEmpty, #errorItemsIsNotEmpty, #name, #decoratedName,
    #linkHref, #currentLocation, #idName]);

  wrongClass(newItem) => newItem is! Library;

  get defaultItem => new Library.forPlaceholder({
    "name" : 'loading',
    "preview" : 'loading',
  });

  @observable get operatorItems => contents(item.operators);
  @observable get variableItems => contents(item.variables);
  @observable get functionItems => contents(item.functions);
  @observable get classItems => contents(item.classes);
  @observable get typedefItems => contents(item.typedefs);
  @observable get errorItems => contents(item.errors);
  @observable get operatorItemsIsNotEmpty => operatorItems.isNotEmpty;
  @observable get variableItemsIsNotEmpty => variableItems.isNotEmpty;
  @observable get functionItemsIsNotEmpty => functionItems.isNotEmpty;
  @observable get classItemsIsNotEmpty => classItems.isNotEmpty;
  @observable get typedefItemsIsNotEmpty => typedefItems.isNotEmpty;
  @observable get errorItemsIsNotEmpty => errorItems.isNotEmpty;

  contents(thing) => thing == null ? [] : thing.content;

  @observable get linkHref => item.linkHref;
  @observable get name => item.name;
  @observable get currentLocation => window.location.toString();

  get item => super.item;
  set item(newItem) => super.item = newItem;

  @observable decoratedName(thing) =>
      thing == null ? null : thing.decoratedName;

  hideShow(event, detail, target) {
    var list = shadowRoot.query("#minimap-" + target.hash.split("#").last);
    if (list.classes.contains("in")) {
      list.classes.remove("in");
    } else {
      list.classes.add("in");
    }
  }
}
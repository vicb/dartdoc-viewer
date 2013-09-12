
import 'package:dartdoc_viewer/item.dart';
import 'package:polymer/polymer.dart';
import 'app.dart';

/// An element in a page's minimap displayed on the right of the page.
@CustomTag("dartdoc-minimap")
class MinimapElement extends PolymerElement {
  @observable List<Item> items;

  /// Creates a proper href String for an [Item].
  String link(item) {
   var hash = item.name == '' ? item.decoratedName : item.name;
   return '${viewer.currentPage.linkHref}#${viewer.toHash(hash)}';
  }

  bool get applyAuthorStyles => true;
}
import 'dart:async';

import 'package:dartdoc_viewer/item.dart';
import 'package:polymer/polymer.dart';

import 'app.dart';
import 'member.dart';

import "dart:html";
import "dart:collection";

@CustomTag("dartdoc-library")
class LibraryElement extends MemberElement {
  LibraryElement() {
    item = new Library.forPlaceholder({
      "name" : 'loading',
      "preview" : 'loading',
    });
//    new PathObserver(this, "item").bindSync(
//        (_) {
//          notifyProperty(this, #addComment);
//        });
  }

  Category get variables => item.variables;

  Category get operators => item.operators;

  Category get functions => item.functions;

  Category get clazzes => item.classes;

  Category get typedefs => item.typedefs;

  Category get errors => item.errors;
}
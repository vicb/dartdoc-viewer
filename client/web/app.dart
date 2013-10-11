/**
 * This application displays documentation generated by the docgen tool
 * found at dart-repo/dart/pkg/docgen.
 *
 * The Yaml file outputted by the docgen tool will be read in to
 * generate [Page] and [Category] and [CompositeContainer].
 * Pages, Categories and CategoryItems are used to format and layout the page.
 */
// TODO(janicejl): Add a link to the dart docgen landing page in future.
library dartdoc_viewer;

import 'dart:async';
import 'dart:html';
import 'dart:convert';

import 'package:dartdoc_viewer/data.dart';
import 'package:dartdoc_viewer/item.dart';
import 'package:dartdoc_viewer/read_yaml.dart';
import 'package:dartdoc_viewer/search.dart';
import 'package:polymer/polymer.dart';
import 'index.dart';

// TODO(janicejl): JSON path should not be hardcoded.
// Path to the JSON file being read in. This file will always be in JSON
// format and contains the format of the rest of the files.
String sourcePath = '../../docs/library_list.json';

/// This is the cut off point between mobile and desktop in pixels.
// TODO(janicejl): Use pixel desity rather than how many pixels. Look at:
// http://www.mobilexweb.com/blog/ipad-mini-detection-for-html5-user-agent
const int desktopSizeBoundary = 1006;

/// The [Viewer] object being displayed.
  Viewer viewer = new Viewer._();


  IndexElement _dartdocMain;
  IndexElement dartdocMain =
      _dartdocMain == null ? _dartdocMain = query("#dartdoc-main").xtag : null;

/// The Dartdoc Viewer application state.
class Viewer extends ObservableBase {

  @observable bool isDesktop = window.innerWidth > desktopSizeBoundary;

  Future finished;

  /// The homepage from which every [Item] can be reached.
  @observable Home homePage;

  /// The current page being shown. An Item.
  /// TODO(alanknight): Restore the type declaration here and structure the code
  /// so we can avoid the warnings from casting to subclasses.
  @observable var currentPage;

  /// State for whether or not the library list panel should be shown.
  bool _isPanel = true;
  @observable bool get isPanel => isDesktop && _isPanel;
  set isPanel(x) => _isPanel = x;

  /// State for whether or not the minimap panel should be shown.
  bool _isMinimap = true;
  @observable bool get isMinimap => isDesktop && _isMinimap;
  set isMinimap(x) => _isMinimap = x;

  /// State for whether or not inherited members should be shown.
  @observable bool isInherited = true;

  /// The current element on the current page being shown (e.g. #dartdoc-top).
  String _hash;

  // Private constructor for singleton instantiation.
  Viewer._() {
    var manifest = retrieveFileContents(sourcePath);
    finished = manifest.then((response) {
      var libraries = JSON.decode(response);
      isYaml = libraries['filetype'] == 'yaml';
      homePage = new Home(libraries);
    });

    new PathObserver(this, "currentPage").bindSync(
      (_) {
        notifyProperty(this, #breadcrumbs);
      });
    new PathObserver(this, "isDesktop").bindSync(
      (_) {
        notifyProperty(this, #isMinimap);
        notifyProperty(this, #isPanel);
      });
  }

  /// Creates a valid hash ID for anchor tags.
  String toHash(String hash) {
    return 'id_' + Uri.encodeComponent(hash).replaceAll('%', '-');
  }

  /// The title of the current page.
  String get title => currentPage == null ? '' : currentPage.decoratedName;

  /// Creates a list of [Item] objects describing the path to [currentPage].
  @observable List<Item> get breadcrumbs => [homePage]
    ..addAll(currentPage == null ? [] : currentPage.path);

  /// Scrolls the screen to the correct member if necessary.
  void _scrollScreen(String hash) {
    if (hash == null || hash == '') {
      Timer.run(() {
        window.scrollTo(0, 0);
      });
    } else {
      Timer.run(() {
        // All ids are created using getIdName to avoid creating an invalid
        // HTML id from an operator or setter.
        hash = hash.substring(1, hash.length);
        var root = document.query("#dartdoc-main");
        var e = queryEverywhere(root, hash);
//        var e = document.query('#$hash');

        if (e != null) {
          // Find the parent category element to make sure it is open.
//          var category = e.parent;
//          while (category != null &&
//              !category.classes.contains('accordion-body')) {
//            category = category.parent;
//          }
//          // Open the category if it is not open.
//          if (category != null && !category.classes.contains('in')) {
//            category.classes.add('in');
//            category.attributes['style'] = 'height: auto;';
//          }
          e.scrollIntoView(ScrollAlignment.TOP);

          // The navigation bar at the top of the page is 60px wide,
          // so scroll down 60px once the browser scrolls to the member.
          window.scrollBy(0, -60);
        }
      });
    }
  }

  /// Query for an element by id in the main element and in all the shadow
  /// roots. If it's not found, return null.
  Element queryEverywhere(Element parent, String id) {
    if (parent.id == id) return parent;
    var shadowChildren =
        parent.shadowRoot != null ? parent.shadowRoot.children : const [];
    var allChildren = [parent.children, shadowChildren]
        .expand((x) => x);
    for (var e in allChildren) {
      var found = queryEverywhere(e, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Updates [currentPage] to be [page].
  void _updatePage(Item page, String hash) {
    if (page != null) {
      // Since currentPage is observable, if it changes the page reloads.
      // This avoids reloading the page when it isn't necessary.
      if (page != currentPage) currentPage = page;
      _hash = hash;
      _scrollScreen(hash);
    }
  }

  /// Loads the [className] class and updates the current page to the
  /// class's member described by [location].
  Future _updateToClassMember(Class clazz, String location, String hash) {
    var variable = location.split('.').last;
    if (!clazz.isLoaded) {
      return clazz.load().then((_) {
        var destination = pageIndex[location];
        if (destination != null)  {
          _updatePage(destination, hash);
        } else {
          // If the destination is null, then it is a variable in this class.
          _updatePage(clazz, '#${toHash(variable)}');
        }
        return true;
      });
    } else {
      // It is a variable in this class.
      _updatePage(clazz, '#${toHash(variable)}');
    }
    return new Future.value(false);
  }

  /// Loads the [libraryName] [Library] and [className] [Class] if necessary
  /// and updates the current page to the member described by [location]
  /// once the correct member is found and loaded.
  Future _loadAndUpdatePage(String libraryName, String className,
                           String location, String hash) {
    var destination = pageIndex[location];
    if (destination == null) {
      var library = homePage.itemNamed(libraryName);
      if (library == null) return new Future.value(false);
      if (!library.isLoaded) {
        return library.load().then((_) =>
          _loadAndUpdatePage(libraryName, className, location, hash));
      } else {
        var clazz = pageIndex[className];
        if (clazz != null) {
          // The location is a member of a class.
          return _updateToClassMember(clazz, location, hash);
        } else {
          // The location is of a top-level variable in a library.
          var variable = location.split('.').last;
          _updatePage(library, '#$variable');
          return new Future.value(true);
        }
      }
    } else {
      if (destination is Class && !destination.isLoaded) {
        return destination.load().then((_) {
          _updatePage(destination, hash);
          return true;
        });
      } else {
        _updatePage(destination, hash);
        return new Future.value(true);
      }
    }
  }

  /// Looks for the correct [Item] described by [location]. If it is found,
  /// [currentPage] is updated and state is not pushed to the history api.
  /// Returns a [Future] to determine if a link was found or not.
  /// [location] is a [String] path to the location (either a qualified name
  /// or a url path).
  Future _handleLinkWithoutState(String location) {
    if (location == null || location == '') return new Future.value(false);
    // An extra '/' at the end of the url must be removed.
    if (location.endsWith('/'))
      location = location.substring(0, location.length - 1);
    if (location == 'home') {
      _updatePage(homePage, null);
      return new Future.value(true);
    }
    // Converts to a qualified name from a url path.
    location = location.replaceAll('/', '.');
    var hashIndex = location.indexOf('#');
    var variableHash;
    var locationWithoutHash = location;
    if (hashIndex != -1) {
      variableHash = location.substring(hashIndex, location.length);
      locationWithoutHash = location.substring(0, hashIndex);
    }
    var members = locationWithoutHash.split('.');
    var libraryName = members.first;
    // Allow references to be of the form #dart:core and convert them.
    libraryName = libraryName.replaceAll(':', '-');
    // Since library names can contain '.' characters, the library part
    // of the input contains '-' characters replacing the '.' characters
    // in the original qualified name to make finding a library easier. These
    // must be changed back to '.' characters to be true qualified names.
    var className = members.length <= 1 ? null :
      '${libraryName.replaceAll('-', '.')}.${members[1]}';
    locationWithoutHash = locationWithoutHash.replaceAll('-', '.');
    return _loadAndUpdatePage(libraryName, className,
        locationWithoutHash, variableHash);
  }

  /// Looks for the correct [Item] described by [location]. If it is found,
  /// [currentPage] is updated and state is pushed to the history api.
  void handleLink(String location) {
    _handleLinkWithoutState(location).then((response) {
      if (response) _updateState(currentPage);
    });
  }

  /// Updates [currentPage] to [page] and pushes state for navigation.
  void changePage(Item page) {
    if (page is LazyItem && !((page as LazyItem).isLoaded)) {
      (page as LazyItem).load().then((_) {
        _updatePage(page, null);
        _updateState(page);
      });
    } else {
      _updatePage(page, null);
      _updateState(page);
    }
  }

  /// Pushes state to history for navigation in the browser.
  void _updateState(Item page) {
    String url = '#home';
    for (var member in page.path) {
      url = url == '#home' ? '#${libraryNames[member.name]}' :
        '$url/${member.name}';
    }
    if (_hash != null) url = '$url$_hash';
    window.history.pushState(url, url.replaceAll('/', '->'), url);
  }

  /// Toggles the library panel
  void togglePanel() {
    isPanel = !_isPanel;
    notifyProperty(this, #isPanel);
  }

  /// Toggles the minimap panel
  void toggleMinimap() {
    isMinimap = !_isMinimap;
    notifyProperty(this, #isMinimap);
  }

  /// Toggles showing inherited members.
  void toggleInherited() {
    isInherited = !isInherited;
  }
}

/// The path of this app on startup.
String _pathname;

/// The latest url reached by a popState event.
String location;

/// Listens for browser navigation and acts accordingly.
void startHistory() {
  location = window.location.hash.replaceFirst('#', '');
  window.onPopState.listen(navigate);
}

void navigate(event) {
  location = window.location.hash.replaceFirst('#', '');
  if (viewer.homePage != null) {
    if (location != '') viewer._handleLinkWithoutState(location);
    else viewer._handleLinkWithoutState('home');
  }
}

/// Handles browser navigation.
main() {
  _pathname = window.location.pathname;

  window.onResize.listen((event) {
    viewer.isDesktop = window.innerWidth > desktopSizeBoundary;
  });

  // Handle clicks and redirect.
  window.onClick.listen((Event e) {
    if (e.target is AnchorElement) {
      var anchor = e.target;
      if (anchor.host == window.location.host
          && anchor.pathname == _pathname && !e.ctrlKey) {
        e.preventDefault();
        var location = anchor.hash.substring(1, anchor.hash.length);
        viewer.handleLink(location);
      }
    }
  });

  startHistory();
  // If a user navigates to a page other than the homepage, the viewer
  // must first load fully before navigating to the specified page.
  viewer.finished.then((_) {
    if (location != null && location != '') {
      viewer._handleLinkWithoutState(location);
    } else {
      viewer.currentPage = viewer.homePage;
    }
    retrieveFileContents('../../docs/index.txt').then((String list) {
      var elements = list.split('\n');
      elements.forEach((element) {
        var splitName = element.split(' ');
        index[splitName[0]] = splitName[1];
      });
    });
  });
}
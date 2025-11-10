import 'package:flutter/widgets.dart';

/// A simple ChangeNotifier that holds the current route name.
class NavigationProvider extends ChangeNotifier {
  String _currentRoute = '/';

  String get currentRoute => _currentRoute;

  void setCurrentRoute(String route) {
    if (route == _currentRoute) return;
    _currentRoute = route;
    notifyListeners();
  }
}

/// A NavigatorObserver that updates the provided [NavigationProvider]
/// whenever a route is pushed/popped.
class NavigationObserver extends NavigatorObserver {
  final NavigationProvider navigationProvider;

  NavigationObserver(this.navigationProvider);

  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) {
      navigationProvider.setCurrentRoute(name);
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }
}

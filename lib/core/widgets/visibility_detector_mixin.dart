import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Mixin que proporciona detecció de visibilitat per a widgets amb reproductors de vídeo.
///
/// Gestiona automàticament l'estat de visibilitat del widget a la pantalla
/// i proporciona callbacks per respondre als canvis de visibilitat.
///
/// Ús:
/// ```dart
/// class _MyVideoState extends State<MyVideo>
///     with VisibilityDetectorMixin {
///
///   @override
///   void onVisibilityChanged(bool isVisible) {
///     if (isVisible) {
///       _controller?.play();
///     } else {
///       _controller?.pause();
///     }
///   }
/// }
/// ```
mixin VisibilityDetectorMixin<T extends StatefulWidget> on State<T> {
  bool _isVisible = true;
  bool _isDisposed = false;

  /// Indica si el widget és actualment visible a la pantalla
  bool get isWidgetVisible => _isVisible;

  /// Indica si el widget ha estat disposed
  bool get isDisposed => _isDisposed;

  /// Callback que s'executa quan canvia la visibilitat del widget
  ///
  /// Implementa aquest mètode per respondre als canvis de visibilitat
  void onVisibilityChanged(bool isVisible);

  /// Configuració opcional: marge de visibilitat (en píxels)
  ///
  /// Si el widget està dins d'aquest marge fora de la pantalla,
  /// encara es considera "visible" (útil per pre-carregar)
  double get visibilityMargin => 0.0;

  /// Configuració opcional: retard abans de comprovar visibilitat
  ///
  /// Útil per evitar comprovacions excessives durant animacions
  Duration get visibilityCheckDelay => const Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    // Comprova visibilitat inicial després de la construcció
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _checkVisibility();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Integra el detector de visibilitat amb el widget
  ///
  /// Empaqueta el child amb un NotificationListener per detectar scrolls
  Widget buildWithVisibilityDetection(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // Només comprova visibilitat en estats rellevants del scroll
        if (scrollNotification is ScrollUpdateNotification ||
            scrollNotification is ScrollEndNotification) {
          _scheduleVisibilityCheck();
        }
        return false; // Permet que la notificació continuï propagant-se
      },
      child: child,
    );
  }

  /// Programa una comprovació de visibilitat amb retard
  void _scheduleVisibilityCheck() {
    if (!_isDisposed && mounted) {
      Future.delayed(visibilityCheckDelay, () {
        if (!_isDisposed && mounted) {
          _checkVisibility();
        }
      });
    }
  }

  /// Comprova si el widget és visible a la pantalla
  void _checkVisibility() {
    if (_isDisposed || !mounted) return;

    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenHeight = MediaQuery.of(context).size.height;

      // Calcula si el widget és visible (amb marge opcional)
      final isCurrentlyVisible =
          position.dy < screenHeight + visibilityMargin &&
          position.dy + size.height > -visibilityMargin;

      // Només notifica si hi ha un canvi real
      if (_isVisible != isCurrentlyVisible) {
        _isVisible = isCurrentlyVisible;

        debugPrint(
          '${T.toString()} visibility changed: $_isVisible '
          '(y: ${position.dy.toStringAsFixed(1)}, h: ${size.height.toStringAsFixed(1)})',
        );

        // Crida el callback implementat per l'usuari
        onVisibilityChanged(_isVisible);
      }
    } catch (e) {
      debugPrint('Error checking visibility for ${T.toString()}: $e');
    }
  }

  /// Força una comprovació manual de visibilitat
  ///
  /// Útil quan saps que el layout ha canviat però no hi ha scroll
  void forceVisibilityCheck() {
    _checkVisibility();
  }
}

/// Mixin que combina detecció de visibilitat amb gestió del lifecycle de l'app
///
/// Proporciona callbacks addicionals per quan l'app passa a segon pla
mixin VisibilityAndLifecycleDetectorMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver
    implements VisibilityDetectorMixin<T> {
  @override
  bool _isVisible = true;

  @override
  bool _isDisposed = false;

  @override
  bool get isWidgetVisible => _isVisible;

  @override
  bool get isDisposed => _isDisposed;

  @override
  double get visibilityMargin => 0.0;

  @override
  Duration get visibilityCheckDelay => const Duration(milliseconds: 100);

  /// Callback per quan l'app passa a primer pla
  void onAppResumed();

  /// Callback per quan l'app passa a segon pla
  void onAppPaused();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _checkVisibility();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.resumed:
        onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        onAppPaused();
        break;
    }
  }

  @override
  Widget buildWithVisibilityDetection(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollUpdateNotification ||
            scrollNotification is ScrollEndNotification) {
          _scheduleVisibilityCheck();
        }
        return false;
      },
      child: child,
    );
  }

  @override
  void _scheduleVisibilityCheck() {
    if (!_isDisposed && mounted) {
      Future.delayed(visibilityCheckDelay, () {
        if (!_isDisposed && mounted) {
          _checkVisibility();
        }
      });
    }
  }

  @override
  void _checkVisibility() {
    if (_isDisposed || !mounted) return;

    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenHeight = MediaQuery.of(context).size.height;

      final isCurrentlyVisible =
          position.dy < screenHeight + visibilityMargin &&
          position.dy + size.height > -visibilityMargin;

      if (_isVisible != isCurrentlyVisible) {
        _isVisible = isCurrentlyVisible;

        debugPrint(
          '${T.toString()} visibility changed: $_isVisible '
          '(y: ${position.dy.toStringAsFixed(1)}, h: ${size.height.toStringAsFixed(1)})',
        );

        onVisibilityChanged(_isVisible);
      }
    } catch (e) {
      debugPrint('Error checking visibility for ${T.toString()}: $e');
    }
  }

  @override
  void forceVisibilityCheck() {
    _checkVisibility();
  }
}

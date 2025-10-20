import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Error handler widget to catch and display errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  kDebugMode ? _error.toString() : 'Please restart the app',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
      });
      return const SizedBox.shrink();
    };
  }
}

/// Setup global error handling
void setupErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Flutter Error Caught:');
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace:');
    debugPrint(details.stack.toString());
    debugPrint('═══════════════════════════════════════════');
  };

  // Handle errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Platform Error Caught:');
    debugPrint('Error: $error');
    debugPrint('Stack trace:');
    debugPrint(stack.toString());
    debugPrint('═══════════════════════════════════════════');
    return true;
  };
}

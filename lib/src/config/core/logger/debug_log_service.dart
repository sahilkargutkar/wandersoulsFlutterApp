import 'dart:developer' as developer;
import 'package:logger/logger.dart';
import 'log_service.dart';

class DebugLogService implements LogService {
  DebugLogService({Logger? logger}) {
    _logger = logger ??
        Logger(
          printer: PrefixPrinter(
            PrettyPrinter(
              methodCount: 0,
              errorMethodCount: 500,
              lineLength: 100,
              colors: true,
              printEmojis: true,
            ),
          ),
          output: _MyConsoleOutput(),
        );
  }

  late final Logger _logger;

  @override
  void e(String message, dynamic e, StackTrace? stack) {
    _logger.e(message, time: DateTime.now(), error: e, stackTrace: stack);
  }

  @override
  void i(String message) {
    _logger.i(message);
  }

  @override
  void w(String message, [dynamic e, StackTrace? stack]) {
    _logger.w(message, time: DateTime.now(), error: e, stackTrace: stack);
  }
}

class _MyConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    event.lines.forEach(developer.log);
  }
}

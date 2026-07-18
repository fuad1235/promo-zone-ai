import 'dart:async';
import 'dart:io';

class NetworkStatusService {
  NetworkStatusService() {
    _emitCheck();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _emitCheck());
  }

  final _controller = StreamController<bool>.broadcast();
  Timer? _timer;
  bool _isOnline = true;

  Stream<bool> get stream async* {
    yield _isOnline;
    yield* _controller.stream;
  }

  bool get isOnline => _isOnline;

  Future<void> forceCheck() => _emitCheck();

  Future<void> _emitCheck() async {
    final online = await _probeConnection();
    if (online == _isOnline) return;
    _isOnline = online;
    _controller.add(online);
  }

  Future<bool> _probeConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return true;
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

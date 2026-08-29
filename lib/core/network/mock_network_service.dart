import 'dart:async';

enum NetworkCondition {
  stable,
  lowBandwidth,
  disconnected,
}

class MockNetworkService {
  NetworkCondition _condition = NetworkCondition.stable;
  
  NetworkCondition get condition => _condition;

  void setCondition(NetworkCondition condition) {
    _condition = condition;
  }

  /// Simulates uploading a batch with progress callbacks and potential failure
  Stream<double> uploadBatchStream({
    required String batchId,
    required int totalBytes,
    required bool simulateFailure,
  }) async* {
    if (_condition == NetworkCondition.disconnected) {
      throw Exception('NO_INTERNET: Cannot start upload while disconnected');
    }

    final double stepSize = _condition == NetworkCondition.lowBandwidth ? 0.05 : 0.15;
    final int delayMs = _condition == NetworkCondition.lowBandwidth ? 800 : 250;
    
    double progress = 0.0;
    
    while (progress < 1.0) {
      await Future.delayed(Duration(milliseconds: delayMs));

      if (_condition == NetworkCondition.disconnected) {
        throw Exception('INTERRUPTED: Network connection lost during upload');
      }

      // If simulateFailure is enabled, fail randomly or at 60% progress under low bandwidth
      if (simulateFailure && progress > 0.5) {
        throw Exception('LOW_BANDWIDTH_TIMEOUT: Server connection timed out');
      }

      progress += stepSize;
      if (progress > 1.0) progress = 1.0;
      
      yield progress;
    }
  }
}

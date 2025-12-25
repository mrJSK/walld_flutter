/// Shared singleton to track app warm-up and performance state
class PerformanceState {
  PerformanceState._();
  static final PerformanceState instance = PerformanceState._();

  /// Set to true when WorkspaceShell has warmed up and is stable
  bool isWarmupStable = false;
  
  /// Optional: track current FPS for logging
  double? currentFps;
  
  /// Reset state (e.g., on hot reload)
  void reset() {
    isWarmupStable = false;
    currentFps = null;
  }
}

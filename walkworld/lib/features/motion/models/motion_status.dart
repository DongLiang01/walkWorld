/// 描述 Flutter 侧一次运动会话的生命周期状态。
enum MotionStatus {
  /// 运动尚未开始。
  idle,

  /// 运动准备中，通常用于权限检查或原生初始化。
  preparing,

  /// 运动进行中，正在持续记录运动数据。
  running,

  /// 运动已暂停。
  paused,

  /// 运动已结束，并且已经生成最终结果。
  finished,

  /// 运动流程进入错误状态。
  error,
}

extension MotionStatusX on MotionStatus {
  /// 将枚举值转换为 Flutter 与 iOS 通信使用的字符串。
  String get value => switch (this) {
        MotionStatus.idle => 'idle',
        MotionStatus.preparing => 'preparing',
        MotionStatus.running => 'running',
        MotionStatus.paused => 'paused',
        MotionStatus.finished => 'finished',
        MotionStatus.error => 'error',
      };

  /// 从原生通道返回的字符串恢复为状态枚举。
  static MotionStatus fromValue(String value) => switch (value) {
        'idle' => MotionStatus.idle,
        'preparing' => MotionStatus.preparing,
        'running' => MotionStatus.running,
        'paused' => MotionStatus.paused,
        'finished' => MotionStatus.finished,
        'error' => MotionStatus.error,
        _ => MotionStatus.error,
      };
}

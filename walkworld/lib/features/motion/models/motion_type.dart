/// 运动类型枚举，对应当前支持的三种运动方式。
enum MotionType {
  /// 徒步 — 轻松步行，低强度有氧，适合休闲
  hiking,

  /// 跑步 — 有氧运动，提升心肺，消耗热量
  running,

  /// 骑行 — 低冲击骑行，高效燃脂减脂
  cycling,
}

extension MotionTypeExt on MotionType {
  String get label => switch (this) {
    MotionType.hiking => '徒步',
    MotionType.running => '跑步',
    MotionType.cycling => '骑行',
  };

  String get description => switch (this) {
    MotionType.hiking => '轻松步行，低强度有氧，适合休闲',
    MotionType.running => '有氧运动，提升心肺，消耗热量',
    MotionType.cycling => '低冲击骑行，高效燃脂减脂',
  };

  /// 传给原生侧和数据库保存的标准字符串。
  String get channelValue => switch (this) {
    MotionType.hiking => 'hiking',
    MotionType.running => 'running',
    MotionType.cycling => 'cycling',
  };
}

MotionType motionTypeFromValue(String? value) {
  return switch (value) {
    'running' => MotionType.running,
    'cycling' => MotionType.cycling,
    _ => MotionType.hiking,
  };
}

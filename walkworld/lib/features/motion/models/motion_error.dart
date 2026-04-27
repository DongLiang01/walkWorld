/// 表示运动模块中的原生错误或流程错误。
class MotionError {
  const MotionError({
    required this.code,
    required this.message,
    this.detail,
  });

  /// 稳定的错误码，用于界面处理和问题排查。
  final String code;

  /// 面向人的错误说明。
  final String message;

  /// 原生侧返回的附加错误信息，可选。
  final String? detail;

  MotionError copyWith({
    String? code,
    String? message,
    String? detail,
  }) {
    return MotionError(
      code: code ?? this.code,
      message: message ?? this.message,
      detail: detail ?? this.detail,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'code': code,
      'message': message,
      'detail': detail,
    };
  }

  factory MotionError.fromMap(Map<Object?, Object?> map) {
    return MotionError(
      code: map['code'] as String? ?? 'unknown_error',
      message: map['message'] as String? ?? '未知运动错误。',
      detail: map['detail'] as String?,
    );
  }
}

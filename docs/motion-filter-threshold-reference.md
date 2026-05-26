# 运动轨迹过滤参数参考

当前 iOS 原生会按运动类型使用不同的轨迹过滤参数。下面整理三类运动的当前值与建议值，当前建议值采用“徒步比跑步更严格、跑步比骑行更严格”的分层优先方案。

## 参数对照

### 徒步 `hiking`

| 参数 | 当前值 | 建议值 | 备注 |
| --- | --- | --- | --- |
| `maxAcceptedHorizontalAccuracy` | `15` | `15` | 保持比跑步更严格，同时比旧值略放宽 |
| `minMovementDistanceMeters` | `1.2` | `1.2` | 适配徒步小步幅，减少低速不记点 |
| `maxAcceptedDerivedSpeedMps` | `6` | `6` | 当前值基本合理，先不动 |
| `minIntervalForJumpDetectionSeconds` | `0.5` | `0.5` | 当前值基本合理，先不动 |
| `directionCheckWindowSeconds` | `3.0` | `3.0` | 当前值基本合理，先不动 |
| `maxDirectionChangeForSlowMoveDegrees` | `150` | `150` | 稍微放宽低速转向容忍 |
| `slowMoveSpeedThresholdMps` | `1.5` | `1.5` | 扩大低速判定范围，避免徒步点被过早误杀 |

### 跑步 `running`

| 参数 | 当前值 | 建议值 | 备注 |
| --- | --- | --- | --- |
| `maxAcceptedHorizontalAccuracy` | `17` | `17` | 位于徒步与骑行之间，保持分层关系 |
| `minMovementDistanceMeters` | `2.0` | `2.0` | 当前值基本合理，先不动 |
| `maxAcceptedDerivedSpeedMps` | `8` | `8` | 当前值基本合理，先不动 |
| `minIntervalForJumpDetectionSeconds` | `0.5` | `0.5` | 当前值基本合理，先不动 |
| `directionCheckWindowSeconds` | `3.0` | `3.0` | 当前值基本合理，先不动 |
| `maxDirectionChangeForSlowMoveDegrees` | `120` | `120` | 当前值基本合理，先不动 |
| `slowMoveSpeedThresholdMps` | `2.0` | `2.0` | 当前值基本合理，先不动 |

### 骑行 `cycling`

| 参数 | 当前值 | 建议值 | 备注 |
| --- | --- | --- | --- |
| `maxAcceptedHorizontalAccuracy` | `20` | `20` | 当前表现正常，先作为对照组保留 |
| `minMovementDistanceMeters` | `3.0` | `3.0` | 当前表现正常，先作为对照组保留 |
| `maxAcceptedDerivedSpeedMps` | `14` | `14` | 当前表现正常，先作为对照组保留 |
| `minIntervalForJumpDetectionSeconds` | `0.5` | `0.5` | 当前表现正常，先作为对照组保留 |
| `directionCheckWindowSeconds` | `2.0` | `2.0` | 当前表现正常，先作为对照组保留 |
| `maxDirectionChangeForSlowMoveDegrees` | `150` | `150` | 当前表现正常，先作为对照组保留 |
| `slowMoveSpeedThresholdMps` | `5.0` | `5.0` | 当前表现正常，先作为对照组保留 |

## 参数释义

| 参数 | 含义 |
| --- | --- |
| `maxAcceptedHorizontalAccuracy` | 定位点允许的最差水平精度，超出直接丢弃 |
| `minMovementDistanceMeters` | 与上一个有效点之间的最小有效移动距离 |
| `maxAcceptedDerivedSpeedMps` | 两点推算速度上限，超出视为跳点 |
| `minIntervalForJumpDetectionSeconds` | 两点时间间隔小于该值时，不做跳点速度判定 |
| `directionCheckWindowSeconds` | 方向角异常检测使用的时间窗口 |
| `maxDirectionChangeForSlowMoveDegrees` | 低速时允许的最大方向突变角度 |
| `slowMoveSpeedThresholdMps` | 低于该速度时，才启用方向角异常过滤 |

## 结论

这版参数优先满足“徒步 < 跑步 < 骑行”的精度分层逻辑。后续调参时，优先观察“距离是否连续增长”和“地图是否连续成线”。

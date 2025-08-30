import 'package:casi/features/survey/domain/entities/input_config.dart';

class InputConfigModel extends InputConfig {
  const InputConfigModel({
    required super.id,
    required super.type,
    required super.label,
    super.min,
    super.max,
    super.options,
    super.maxLength,
    super.showIf,
    super.lockIf,
  });

  factory InputConfigModel.fromMap(Map<String, dynamic> m) {
    return InputConfigModel(
      id: m['id']?.toString() ?? '',
      type: (m['type']?.toString() ?? '').toLowerCase(),
      label: m['label']?.toString() ?? '',
      min: (m['min'] is num) ? (m['min'] as num).toInt() : null,
      max: (m['max'] is num) ? (m['max'] as num).toInt() : null,
      options: (m['options'] as List?)?.map((e) => e.toString()).toList(),
      maxLength: (m['maxLength'] is num)
          ? (m['maxLength'] as num).toInt()
          : null,
      showIf: (m['showIf'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)),
      lockIf: (m['lockIf'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
}

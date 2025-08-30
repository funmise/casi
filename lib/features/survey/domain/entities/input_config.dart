class InputConfig {
  final String id;
  final String type; // "boolean"|"int"|"enum"|"multiline"
  final String label;

  final int? min;
  final int? max;
  final int? maxLength;
  final List<String>? options;

  final Map<String, dynamic>? showIf; // { fieldId : value }
  final Map<String, dynamic>? lockIf; // { fieldId : value }

  const InputConfig({
    required this.id,
    required this.type,
    required this.label,
    this.min,
    this.max,
    this.maxLength,
    this.options,
    this.showIf,
    this.lockIf,
  });
}

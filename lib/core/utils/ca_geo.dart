// ca_geo.dart
const Map<String, String> kProvinceCodeToName = {
  'AB': 'Alberta',
  'BC': 'British Columbia',
  'MB': 'Manitoba',
  'NB': 'New Brunswick',
  'NL': 'Newfoundland and Labrador',
  'NS': 'Nova Scotia',
  'NT': 'Northwest Territories',
  'NU': 'Nunavut',
  'ON': 'Ontario',
  'PE': 'Prince Edward Island',
  'QC': 'Quebec',
  'SK': 'Saskatchewan',
  'YT': 'Yukon',
};

String? codeForProvinceName(String? name) {
  if (name == null) return null;
  for (final e in kProvinceCodeToName.entries) {
    if (e.value.toLowerCase() == name.toLowerCase()) return e.key;
  }
  return null;
}

String nameForProvinceCode(String? code) =>
    kProvinceCodeToName[code] ?? (code ?? '');

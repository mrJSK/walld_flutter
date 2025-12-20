import 'dart:convert';

class FormSchemaMeta {
  String formId;
  String name;
  String description;
  String rawJsonSchema; // pretty JSON string for the schema part only

  FormSchemaMeta({
    required this.formId,
    required this.name,
    required this.description,
    required this.rawJsonSchema,
  });

  factory FormSchemaMeta.fromFirestore(
      String id, Map<String, dynamic> map) {
    final schema = map['schema'] ?? {};
    return FormSchemaMeta(
      formId: id,
      name: map['name'] ?? id,
      description: map['description'] ?? '',
      rawJsonSchema:
          const JsonEncoder.withIndent('  ').convert(schema),
    );
  }

  Map<String, dynamic> toFirestore() {
    dynamic decoded;
    try {
      decoded = jsonDecode(rawJsonSchema);
    } catch (_) {
      decoded = {};
    }
    return {
      'name': name,
      'description': description,
      'schema': decoded,
    };
  }

  static String defaultUserRegistrationSchema() {
    return const JsonEncoder.withIndent('  ').convert({
      'formId': 'user_registration',
      'version': 1,
      'fields': [
        {
          'id': 'fullName',
          'type': 'text',
          'label': 'Full Name',
          'required': true,
        },
        {
          'id': 'email',
          'type': 'email',
          'label': 'Email Address',
          'required': true,
        },
      ],
    });
  }
}

import 'dart:convert';

/* High-level form definition */

class FormSchemaMeta {
  String formId;
  String name;
  String description;
  List<FormFieldMeta> fields;

  FormSchemaMeta({
    required this.formId,
    required this.name,
    required this.description,
    required this.fields,
  });

  factory FormSchemaMeta.fromFirestore(
      String id, Map<String, dynamic> map) {
    final schema = map['schema'] ?? {};
    final fieldsJson = (schema['fields'] ?? []) as List<dynamic>;

    return FormSchemaMeta(
      formId: id,
      name: map['name'] ?? id,
      description: map['description'] ?? '',
      fields: fieldsJson
          .map((e) => FormFieldMeta.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final schema = {
      'formId': formId,
      'version': 1,
      'fields': fields.map((f) => f.toMap()).toList(),
    };

    return {
      'name': name,
      'description': description,
      'schema': schema,
    };
  }

  static FormSchemaMeta defaultUserRegistration() {
    return FormSchemaMeta(
      formId: 'user_registration',
      name: 'User Registration Form',
      description: 'New user signup with designation + department',
      fields: [
        FormFieldMeta(
          id: 'fullName',
          type: 'text',
          label: 'Full Name',
          required: true,
          validation: r'^[a-zA-Z\s]{3,50}$',
        ),
        FormFieldMeta(
          id: 'email',
          type: 'email',
          label: 'Email Address',
          required: true,
          validation: r'^[^@]+@[^@]+\.[^@]+$',
        ),
      ],
    );
  }
}

/* Per-field metadata */

class FormFieldMeta {
  String id;
  String type;              // text, email, dropdown, checkbox, date, etc.
  String label;
  bool required;
  List<String> options;     // for static dropdowns

  // Dynamic data source (for designation / department pickers, etc.)
  String? dataSource;       // e.g. "firestore"
  String? collection;       // collection path under tenant (e.g. "designations")
  String? displayField;     // field used for display text
  String? valueField;       // field used as stored value

  // Schema-driven validation (regex)
  String? validation;

  FormFieldMeta({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    List<String>? options,
    this.dataSource,
    this.collection,
    this.displayField,
    this.valueField,
    this.validation,
  }) : options = options ?? [];

  factory FormFieldMeta.fromMap(Map<String, dynamic> map) {
    return FormFieldMeta(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      label: map['label'] ?? '',
      required: map['required'] ?? false,
      options: List<String>.from(map['options'] ?? const []),
      dataSource: map['dataSource'],
      collection: map['collection'],
      displayField: map['displayField'],
      valueField: map['valueField'],
      validation: map['validation'],
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'id': id,
      'type': type,
      'label': label,
      'required': required,
    };
    if (options.isNotEmpty) data['options'] = options;
    if (dataSource != null) data['dataSource'] = dataSource;
    if (collection != null) data['collection'] = collection;
    if (displayField != null) data['displayField'] = displayField;
    if (valueField != null) data['valueField'] = valueField;
    if (validation != null) data['validation'] = validation;
    return data;
  }
}

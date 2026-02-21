/// Represents a sub-event within a main event (e.g., Haldi, Sangeet, Reception)
class SubEvent {
  /// Unique identifier
  final String id;
  
  /// Name of the sub-event (e.g., "Haldi", "Sangeet", "Barat", "Reception")
  final String name;
  
  /// Date of this sub-event
  final DateTime date;
  
  /// Charges for this sub-event
  final double charges;
  
  /// Optional notes for this sub-event
  final String? notes;
  
  const SubEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.charges,
    this.notes,
  });
  
  /// Create a copy with updated fields
  SubEvent copyWith({
    String? id,
    String? name,
    DateTime? date,
    double? charges,
    String? notes,
  }) {
    return SubEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      charges: charges ?? this.charges,
      notes: notes ?? this.notes,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'charges': charges,
      'notes': notes,
    };
  }
  
  /// Create from JSON
  factory SubEvent.fromJson(Map<String, dynamic> json) {
    return SubEvent(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      charges: (json['charges'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }
  
  /// Create an empty sub-event
  factory SubEvent.empty() {
    return SubEvent(
      id: '',
      name: '',
      date: DateTime.now(),
      charges: 0.0,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubEvent && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

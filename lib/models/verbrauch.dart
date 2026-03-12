import 'package:equatable/equatable.dart';

class Verbrauch extends Equatable {
  final String id;
  final String filamentId;
  final int verbrauchtGramm;
  final DateTime datum;
  final String? projektName;
  final String userId;

  const Verbrauch({
    required this.id,
    required this.filamentId,
    required this.verbrauchtGramm,
    required this.datum,
    this.projektName,
    required this.userId,
  });

  Verbrauch copyWith({
    String? id,
    String? filamentId,
    int? verbrauchtGramm,
    DateTime? datum,
    String? projektName,
    String? userId,
  }) {
    return Verbrauch(
      id: id ?? this.id,
      filamentId: filamentId ?? this.filamentId,
      verbrauchtGramm: verbrauchtGramm ?? this.verbrauchtGramm,
      datum: datum ?? this.datum,
      projektName: projektName ?? this.projektName,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filament_id': filamentId,
      'verbraucht_gramm': verbrauchtGramm,
      'datum': datum.toIso8601String(),
      'projekt_name': projektName,
      'user_id': userId,
    };
  }

  factory Verbrauch.fromMap(Map<String, dynamic> map) {
    return Verbrauch(
      id: map['id']?.toString() ?? '',
      filamentId: map['filament_id']?.toString() ?? '',
      verbrauchtGramm: map['verbraucht_gramm'] ?? 0,
      datum: map['datum'] != null ? DateTime.tryParse(map['datum'].toString()) ?? DateTime.now() : DateTime.now(),
      projektName: map['projekt_name']?.toString(),
      userId: map['user_id']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        filamentId,
        verbrauchtGramm,
        datum,
        projektName,
        userId,
      ];
}

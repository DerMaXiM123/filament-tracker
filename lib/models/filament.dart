import 'package:equatable/equatable.dart';

class Filament extends Equatable {
  final String id;
  final String marke;
  final String typ;
  final String farbe;
  final int gewichtGramm;
  final int restgewichtGramm;
  final double preis;
  final DateTime gekauftAm;
  final String? herkunftsland;
  final String? bemerkung;
  final String userId;

  const Filament({
    required this.id,
    required this.marke,
    required this.typ,
    required this.farbe,
    required this.gewichtGramm,
    required this.restgewichtGramm,
    required this.preis,
    required this.gekauftAm,
    this.herkunftsland,
    this.bemerkung,
    required this.userId,
  });

  double get prozentVerbleibend =>
      gewichtGramm > 0 ? (restgewichtGramm / gewichtGramm) * 100 : 0;

  bool get isLowStock => prozentVerbleibend < 20;

  Filament copyWith({
    String? id,
    String? marke,
    String? typ,
    String? farbe,
    int? gewichtGramm,
    int? restgewichtGramm,
    double? preis,
    DateTime? gekauftAm,
    String? herkunftsland,
    String? bemerkung,
    String? userId,
  }) {
    return Filament(
      id: id ?? this.id,
      marke: marke ?? this.marke,
      typ: typ ?? this.typ,
      farbe: farbe ?? this.farbe,
      gewichtGramm: gewichtGramm ?? this.gewichtGramm,
      restgewichtGramm: restgewichtGramm ?? this.restgewichtGramm,
      preis: preis ?? this.preis,
      gekauftAm: gekauftAm ?? this.gekauftAm,
      herkunftsland: herkunftsland ?? this.herkunftsland,
      bemerkung: bemerkung ?? this.bemerkung,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'marke': marke,
      'typ': typ,
      'farbe': farbe,
      'gewicht_gramm': gewichtGramm,
      'restgewicht_gramm': restgewichtGramm,
      'preis': preis,
      'gekauft_am': gekauftAm.toIso8601String(),
      'herkunftsland': herkunftsland,
      'bemerkung': bemerkung,
      'user_id': userId,
    };
  }

  factory Filament.fromMap(Map<String, dynamic> map) {
    return Filament(
      id: map['id']?.toString() ?? '',
      marke: map['marke']?.toString() ?? '',
      typ: map['typ']?.toString() ?? '',
      farbe: map['farbe']?.toString() ?? '',
      gewichtGramm: map['gewicht_gramm'] ?? 0,
      restgewichtGramm: map['restgewicht_gramm'] ?? 0,
      preis: (map['preis'] ?? 0).toDouble(),
      gekauftAm: map['gekauft_am'] != null ? DateTime.tryParse(map['gekauft_am'].toString()) ?? DateTime.now() : DateTime.now(),
      herkunftsland: map['herkunftsland']?.toString(),
      bemerkung: map['bemerkung']?.toString(),
      userId: map['user_id']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        marke,
        typ,
        farbe,
        gewichtGramm,
        restgewichtGramm,
        preis,
        gekauftAm,
        herkunftsland,
        bemerkung,
        userId,
      ];
}

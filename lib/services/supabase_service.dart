import 'package:supabase/supabase.dart' as sb;
import '../models/filament.dart';
import '../models/verbrauch.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late sb.SupabaseClient _client;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  sb.SupabaseClient get client => _client;

  Future<void> initialize(String url, String anonKey) async {
    _client = sb.SupabaseClient(url, anonKey);
    _isInitialized = true;
  }

  // Auth
  Future<sb.AuthResponse> signUp(String email, String password) async {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized');
    }
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<sb.AuthResponse> signIn(String email, String password) async {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized');
    }
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!_isInitialized) return;
    await _client.auth.signOut();
  }

  sb.User? get currentUser {
    if (!_isInitialized) return null;
    return _client.auth.currentUser;
  }

  Stream<sb.AuthState> get authState {
    if (!_isInitialized) return const Stream.empty();
    return _client.auth.onAuthStateChange;
  }

  // Filamente
  Future<List<Filament>> getFilamente() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('filamente')
        .select()
        .eq('user_id', userId)
        .order('gekauft_am', ascending: false);

    return response.map((e) => Filament.fromMap(e)).toList();
  }

  Stream<List<Filament>> getFilamenteStream() {
    final userId = currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('filamente')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((e) => e.map((m) => Filament.fromMap(m)).toList());
  }

  Future<void> addFilament(Filament filament) async {
    await _client.from('filamente').insert(filament.toMap());
  }

  Future<void> updateFilament(Filament filament) async {
    await _client
        .from('filamente')
        .update(filament.toMap())
        .eq('id', filament.id);
  }

  Future<void> deleteFilament(String id) async {
    await _client.from('filamente').delete().eq('id', id);
  }

  // Verbrauch
  Future<List<Verbrauch>> getVerbrauch() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('verbrauch')
        .select()
        .eq('user_id', userId)
        .order('datum', ascending: false);

    return response.map((e) => Verbrauch.fromMap(e)).toList();
  }

  Stream<List<Verbrauch>> getVerbrauchStream() {
    final userId = currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('verbrauch')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((e) => e.map((m) => Verbrauch.fromMap(m)).toList());
  }

  Future<void> addVerbrauch(Verbrauch verbrauch) async {
    await _client.from('verbrauch').insert(verbrauch.toMap());
  }

  Future<void> deleteVerbrauch(String id) async {
    await _client.from('verbrauch').delete().eq('id', id);
  }

  // Statistiken
  Future<Map<String, int>> getVerbrauchProMonat() async {
    final userId = currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('verbrauch')
        .select()
        .eq('user_id', userId);

    final Map<String, int> result = {};
    for (var item in response) {
      final v = Verbrauch.fromMap(item);
      final key = '${v.datum.year}-${v.datum.month.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + v.verbrauchtGramm;
    }
    return result;
  }

  Future<int> getGesamtVerbraucht() async {
    final userId = currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('verbrauch')
        .select('verbraucht_gramm')
        .eq('user_id', userId);

    int total = 0;
    for (var item in response) {
      total += item['verbraucht_gramm'] as int;
    }
    return total;
  }
}

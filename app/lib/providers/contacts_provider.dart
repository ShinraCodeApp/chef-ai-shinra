import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../core/api_client.dart';
import '../models/contact.dart';
import '../models/inventory_item.dart';
import '../core/i18n.dart';

class ContactsProvider extends ChangeNotifier {
  final _dio = ApiClient.instance.dio;

  List<Contact> contacts = [];
  List<PendingInvite> pendingInvites = [];
  bool isLoading = false;
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _dio.get('/contacts'),
        _dio.get('/contacts/pending'),
      ]);
      contacts = (results[0].data as List)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList();
      pendingInvites = (results[1].data as List)
          .map((e) => PendingInvite.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      error = tr('No se pudo cargar los contactos');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> sendInvite(String email) async {
    try {
      await _dio.post('/contacts/invite', data: {'email': email});
      return null;
    } catch (e) {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return tr('No se pudo enviar la invitación');
    }
  }

  Future<String?> respondInvite(String contactId, bool accept) async {
    try {
      await _dio.post('/contacts/$contactId/respond', data: {'accept': accept});
      await loadAll();
      return null;
    } catch (_) {
      return tr('Error al responder la invitación');
    }
  }

  Future<String?> removeContact(String contactId) async {
    try {
      await _dio.delete('/contacts/$contactId');
      contacts.removeWhere((c) => c.contactId == contactId);
      notifyListeners();
      return null;
    } catch (_) {
      return tr('No se pudo eliminar el contacto');
    }
  }

  Future<String?> toggleFavorite(String contactId) async {
    try {
      await _dio.patch('/contacts/$contactId/favorite');
      final idx = contacts.indexWhere((c) => c.contactId == contactId);
      if (idx != -1) {
        contacts[idx].isFavorite = !contacts[idx].isFavorite;
        // Reordenar: favoritos primero
        contacts.sort((a, b) {
          if (a.isFavorite == b.isFavorite) return 0;
          return a.isFavorite ? -1 : 1;
        });
        notifyListeners();
      }
      return null;
    } catch (_) {
      return tr('No se pudo actualizar favorito');
    }
  }

  /// Lee los contactos del teléfono, extrae los emails y pregunta al backend
  /// cuáles tienen cuenta en la app.
  Future<List<PhoneContactWithApp>> findContactsWithApp() async {
    final hasPermission = await fc.FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) return [];

    final phoneContacts = await fc.FlutterContacts.getContacts(withProperties: true);
    final emails = phoneContacts
        .expand((c) => c.emails.map((e) => e.address.trim().toLowerCase()))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (emails.isEmpty) return [];

    try {
      final res = await _dio.post('/contacts/find-by-emails', data: {'emails': emails});
      return (res.data as List)
          .map((e) => PhoneContactWithApp.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<InventoryItem>?> getContactInventory(String contactUserId) async {
    try {
      final res = await _dio.get('/contacts/$contactUserId/inventory');
      return (res.data as List)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}

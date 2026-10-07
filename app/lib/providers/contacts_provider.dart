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

  /// true si la última invitación falló porque esa persona no tiene la app
  /// (la pantalla ofrece mandarle el link para descargarla).
  bool lastInviteUserNotFound = false;

  Future<String?> sendInvite(String email) async {
    lastInviteUserNotFound = false;
    try {
      await _dio.post('/contacts/invite', data: {'email': email.trim().toLowerCase()});
      return null;
    } catch (e) {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['code'] == 'USER_NOT_FOUND') {
        lastInviteUserNotFound = true;
        return tr('Esa persona todavía no tiene Chef AI');
      }
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
  /// Por qué la última búsqueda en los contactos del celular no trajo nada.
  ContactScanStatus lastScanStatus = ContactScanStatus.ok;

  /// Cuántos contactos del celular tienen email (Chef AI busca por email).
  int lastScanEmailCount = 0;

  Future<List<PhoneContactWithApp>> findContactsWithApp() async {
    lastScanEmailCount = 0;
    final hasPermission = await fc.FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      lastScanStatus = ContactScanStatus.noPermission;
      return [];
    }

    final phoneContacts = await fc.FlutterContacts.getContacts(withProperties: true);
    final emails = phoneContacts
        .expand((c) => c.emails.map((e) => e.address.trim().toLowerCase()))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    lastScanEmailCount = emails.length;

    if (emails.isEmpty) {
      lastScanStatus = ContactScanStatus.noEmails;
      return [];
    }

    try {
      final found = <PhoneContactWithApp>[];
      // De a 500 para no mandar listas enormes en un solo pedido
      for (var i = 0; i < emails.length; i += 500) {
        final chunk = emails.sublist(i, i + 500 > emails.length ? emails.length : i + 500);
        final res = await _dio.post('/contacts/find-by-emails', data: {'emails': chunk});
        found.addAll((res.data as List)
            .map((e) => PhoneContactWithApp.fromJson(e as Map<String, dynamic>)));
      }
      lastScanStatus = found.isEmpty ? ContactScanStatus.noneWithApp : ContactScanStatus.ok;
      return found;
    } catch (_) {
      lastScanStatus = ContactScanStatus.serverError;
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

enum ContactScanStatus { ok, noPermission, noEmails, noneWithApp, serverError }

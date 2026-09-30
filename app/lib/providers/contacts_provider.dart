import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/contact.dart';
import '../models/inventory_item.dart';

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
      error = 'No se pudo cargar los contactos';
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
      return 'No se pudo enviar la invitación';
    }
  }

  Future<String?> respondInvite(String contactId, bool accept) async {
    try {
      await _dio.post('/contacts/$contactId/respond', data: {'accept': accept});
      await loadAll();
      return null;
    } catch (_) {
      return 'Error al responder la invitación';
    }
  }

  Future<String?> removeContact(String contactId) async {
    try {
      await _dio.delete('/contacts/$contactId');
      contacts.removeWhere((c) => c.contactId == contactId);
      notifyListeners();
      return null;
    } catch (_) {
      return 'No se pudo eliminar el contacto';
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

class ContactUser {
  final String userId;
  final String name;
  final String email;

  ContactUser({required this.userId, required this.name, required this.email});

  factory ContactUser.fromJson(Map<String, dynamic> json) => ContactUser(
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

class Contact {
  final String contactId;
  final String userId;
  final String name;
  final String email;
  bool isFavorite;

  Contact({
    required this.contactId,
    required this.userId,
    required this.name,
    required this.email,
    this.isFavorite = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        contactId: json['contactId'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );
}

class PhoneContactWithApp {
  final String userId;
  final String name;
  final String email;
  final bool isContact;

  PhoneContactWithApp({
    required this.userId,
    required this.name,
    required this.email,
    required this.isContact,
  });

  factory PhoneContactWithApp.fromJson(Map<String, dynamic> json) =>
      PhoneContactWithApp(
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        isContact: json['isContact'] as bool? ?? false,
      );
}

class PendingInvite {
  final String contactId;
  final ContactUser from;
  final DateTime createdAt;

  PendingInvite({required this.contactId, required this.from, required this.createdAt});

  factory PendingInvite.fromJson(Map<String, dynamic> json) => PendingInvite(
        contactId: json['contactId'] as String,
        from: ContactUser.fromJson(json['from'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

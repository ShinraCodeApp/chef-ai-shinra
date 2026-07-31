class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? sex;
  final String? goal;
  final String? activityLevel;
  final double? monthlyBudget;
  final int? familyMembers;
  final List<String> dietPreferences;
  final List<String> allergies;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.age,
    this.weightKg,
    this.heightCm,
    this.sex,
    this.goal,
    this.activityLevel,
    this.monthlyBudget,
    this.familyMembers,
    required this.dietPreferences,
    required this.allergies,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        age: json['age'] as int?,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        sex: json['sex'] as String?,
        goal: json['goal'] as String?,
        activityLevel: json['activityLevel'] as String?,
        monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble(),
        familyMembers: json['familyMembers'] as int?,
        dietPreferences: (json['dietPreferences'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        allergies:
            (json['allergies'] as List? ?? []).map((e) => e.toString()).toList(),
      );

  User copyWith({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    String? sex,
    String? goal,
    String? activityLevel,
    double? monthlyBudget,
    int? familyMembers,
    List<String>? dietPreferences,
    List<String>? allergies,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      sex: sex ?? this.sex,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      familyMembers: familyMembers ?? this.familyMembers,
      dietPreferences: dietPreferences ?? this.dietPreferences,
      allergies: allergies ?? this.allergies,
    );
  }
}

class Person {
  String id;
  String name, father, mother, photo, mobile, cnic, birthPlace, address,
      permAddress, gender, marital, spouse, relation, notes;
  DateTime? dob, dod;
  List<String> children;
  bool deceased;

  Person({
    required this.id,
    this.name = '',
    this.father = '',
    this.mother = '',
    this.photo = '',
    this.mobile = '',
    this.cnic = '',
    this.birthPlace = '',
    this.address = '',
    this.permAddress = '',
    this.gender = 'M',
    this.marital = 'ms_single',
    this.spouse = '',
    this.relation = 'other',
    this.notes = '',
    this.dob,
    this.dod,
    this.children = const [],
    this.deceased = false,
  });

  int? get age {
    if (dob == null) return null;
    final end = (deceased && dod != null) ? dod! : DateTime.now();
    var a = end.year - dob!.year;
    if (end.month < dob!.month ||
        (end.month == dob!.month && end.day < dob!.day)) {
      a--;
    }
    return a < 0 ? 0 : a;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'father': father,
        'mother': mother,
        'photo': photo,
        'mobile': mobile,
        'cnic': cnic,
        'birthPlace': birthPlace,
        'address': address,
        'permAddress': permAddress,
        'gender': gender,
        'marital': marital,
        'spouse': spouse,
        'relation': relation,
        'notes': notes,
        'dob': dob?.toIso8601String(),
        'dod': dod?.toIso8601String(),
        'children': children,
        'deceased': deceased,
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        father: j['father'] ?? '',
        mother: j['mother'] ?? '',
        photo: j['photo'] ?? '',
        mobile: j['mobile'] ?? '',
        cnic: j['cnic'] ?? '',
        birthPlace: j['birthPlace'] ?? '',
        address: j['address'] ?? '',
        permAddress: j['permAddress'] ?? '',
        gender: j['gender'] ?? 'M',
        marital: j['marital'] ?? 'ms_single',
        spouse: j['spouse'] ?? '',
        relation: j['relation'] ?? 'other',
        notes: j['notes'] ?? '',
        dob: j['dob'] != null ? DateTime.tryParse(j['dob']) : null,
        dod: j['dod'] != null ? DateTime.tryParse(j['dod']) : null,
        children: List<String>.from(j['children'] ?? const []),
        deceased: j['deceased'] ?? false,
      );
}

enum OheyGender { unspecified, male, female }

extension OheyGenderX on OheyGender {
  String get key => switch (this) {
    OheyGender.unspecified => 'unspecified',
    OheyGender.male => 'male',
    OheyGender.female => 'female',
  };

  String get label => switch (this) {
    OheyGender.unspecified => '未設定',
    OheyGender.male => '男性',
    OheyGender.female => '女性',
  };
}

OheyGender oheyGenderFromKey(String? key) =>
    switch (key?.trim().toLowerCase()) {
      'male' => OheyGender.male,
      'female' => OheyGender.female,
      _ => OheyGender.unspecified,
    };

const selectableOheyGenders = <OheyGender>[OheyGender.male, OheyGender.female];

enum NomoGender { unspecified, male, female }

extension NomoGenderX on NomoGender {
  String get key => switch (this) {
    NomoGender.unspecified => 'unspecified',
    NomoGender.male => 'male',
    NomoGender.female => 'female',
  };

  String get label => switch (this) {
    NomoGender.unspecified => '未設定',
    NomoGender.male => '男性',
    NomoGender.female => '女性',
  };
}

NomoGender nomoGenderFromKey(String? key) =>
    switch (key?.trim().toLowerCase()) {
      'male' => NomoGender.male,
      'female' => NomoGender.female,
      _ => NomoGender.unspecified,
    };

const selectableNomoGenders = <NomoGender>[NomoGender.male, NomoGender.female];

enum TomoGender { unspecified, male, female }

extension TomoGenderX on TomoGender {
  String get key => switch (this) {
    TomoGender.unspecified => 'unspecified',
    TomoGender.male => 'male',
    TomoGender.female => 'female',
  };

  String get label => switch (this) {
    TomoGender.unspecified => '未設定',
    TomoGender.male => '男性',
    TomoGender.female => '女性',
  };
}

TomoGender tomoGenderFromKey(String? key) =>
    switch (key?.trim().toLowerCase()) {
      'male' => TomoGender.male,
      'female' => TomoGender.female,
      _ => TomoGender.unspecified,
    };

const selectableTomoGenders = <TomoGender>[TomoGender.male, TomoGender.female];

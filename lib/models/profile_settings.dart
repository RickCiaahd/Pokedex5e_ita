class ProfileSettings {
  final String selectedRegion;
  final bool showOnlyCaught;
  final bool showOnlySeen;

  ProfileSettings({
    required this.selectedRegion,
    required this.showOnlyCaught,
    required this.showOnlySeen,
  });

  factory ProfileSettings.defaults() {
    return ProfileSettings(
      selectedRegion: 'Kanto',
      showOnlyCaught: false,
      showOnlySeen: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedRegion': selectedRegion,
      'showOnlyCaught': showOnlyCaught,
      'showOnlySeen': showOnlySeen,
    };
  }

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      selectedRegion: json['selectedRegion'] ?? 'Kanto',
      showOnlyCaught: json['showOnlyCaught'] ?? false,
      showOnlySeen: json['showOnlySeen'] ?? false,
    );
  }
}
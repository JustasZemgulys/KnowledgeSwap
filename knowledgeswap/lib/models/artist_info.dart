class ArtistInfo {
  final int id;
  final String artistName;
  final String bio;
  // Add other properties as needed

  ArtistInfo({
    required this.id,
    required this.artistName,
    required this.bio,
    // Initialize other properties
  });

  factory ArtistInfo.fromJson(Map<String, dynamic> json) {
    return ArtistInfo(
      id: json['id'],
      artistName: json['artistName'],
      bio: json['bio'],
      // Assign other properties
    );
  }
}

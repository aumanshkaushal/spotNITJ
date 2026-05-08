class FloorData {
  final String floor;

  final int availableSeats;

  final List<int> availableSeatIds;

  FloorData({
    required this.floor,
    required this.availableSeats,
    required this.availableSeatIds,
  });

  factory FloorData.fromJson(Map<String, dynamic> json) {
    return FloorData(
      floor: json['floor'],

      availableSeats: json['availableSeats'],

      availableSeatIds: List<int>.from(json['availableSeatIds']),
    );
  }
}

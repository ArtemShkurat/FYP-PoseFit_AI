class PoseLandmark {
  final int index;
  final double x;
  final double y;
  final double z;
  final double? visibility;

  const PoseLandmark({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    this.visibility,
  });

  factory PoseLandmark.fromMap(Map<dynamic, dynamic> map) {
    return PoseLandmark(
      index: map['index'] as int,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
      visibility: map['visibility'] != null
          ? (map['visibility'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'index': index, 'x': x, 'y': y, 'z': z, 'visibility': visibility};
  }
}

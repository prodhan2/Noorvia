class PosterModel {
  final String no;
  final String imglink;
  final String details;

  PosterModel({
    required this.no,
    required this.imglink,
    required this.details,
  });

  factory PosterModel.fromJson(Map<String, dynamic> json) {
    return PosterModel(
      no: json['no'] ?? '',
      imglink: json['imglink'] ?? '',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'no': no,
      'imglink': imglink,
      'details': details,
    };
  }
}

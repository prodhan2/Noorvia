class PosterModel {
  final String id;
  final String no;
  final String imglink;
  final String details;
  final String title;
  final String targetUrl;
  final bool active;
  final int sortOrder;

  const PosterModel({
    this.id = '',
    required this.no,
    required this.imglink,
    required this.details,
    this.title = '',
    this.targetUrl = '',
    this.active = true,
    this.sortOrder = 0,
  });

  factory PosterModel.fromJson(Map<String, dynamic> json, {String id = ''}) {
    final rawActive = json['active'] ?? json['isActive'] ?? true;
    final rawOrder = json['sortOrder'] ?? json['order'] ?? json['no'] ?? 0;

    return PosterModel(
      id: id,
      no: (json['no'] ?? rawOrder ?? '').toString(),
      imglink: (json['imglink'] ?? json['imageUrl'] ?? '').toString(),
      details: (json['details'] ?? json['description'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      targetUrl: (json['targetUrl'] ?? json['url'] ?? '').toString(),
      active: rawActive is bool
          ? rawActive
          : rawActive.toString().toLowerCase() != 'false',
      sortOrder: rawOrder is num
          ? rawOrder.toInt()
          : int.tryParse(rawOrder.toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'no': no,
        'imglink': imglink,
        'details': details,
        'title': title,
        'targetUrl': targetUrl,
        'active': active,
        'sortOrder': sortOrder,
      };
}


void main() {
  dynamic item = {'snippet': {'title': 'hi'}, 'statistics': {'subscriberCount': '123', 'viewCount': '123', 'videoCount': '123'}};
  var data = {
    'platform': 'youtube',
    'title': item['snippet']['title'],
    'subscribers': int.tryParse(item['statistics']['subscriberCount']?.toString() ?? '0') ?? 0,
  };
  print(data is Map<String, dynamic>);
}


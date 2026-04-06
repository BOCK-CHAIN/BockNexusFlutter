import 'api_client.dart';

class AddressService {
  final ApiClient _client;

  AddressService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<List<dynamic>> getAddresses() async {
    final response = await _client.get('/address/user', auth: true);
    return response['addresses'] as List;
  }

  Future<Map<String, dynamic>> addAddress({
    required String nickname,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String zip,
    required String country,
    required String receiverName,
    required bool isDefault,
    required String type,
  }) async {
    final body = <String, dynamic>{
      'nickname': nickname,
      'line1': line1,
      'line2': line2 ?? '',
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      'receiverName': receiverName,
      'isDefault': isDefault,
      'type': type,
    };

    final response = await _client.post('/address', body, auth: true);
    return response['address'] as Map<String, dynamic>;
  }

  Future<void> editAddress({
    required int id,
    String? nickname,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? zip,
    String? country,
    String? receiverName,
    bool? isDefault,
    String? type,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (nickname != null) body['nickname'] = nickname;
    if (line1 != null) body['line1'] = line1;
    if (line2 != null) body['line2'] = line2;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    if (zip != null) body['zip'] = zip;
    if (country != null) body['country'] = country;
    if (receiverName != null) body['receiverName'] = receiverName;
    if (isDefault != null) body['isDefault'] = isDefault;
    if (type != null) body['type'] = type;

    await _client.put('/address/${id.toString()}', body, auth: true);
  }

  Future<void> deleteAddress(String id) async {
    await _client.delete('/address/$id', auth: true);
  }
}


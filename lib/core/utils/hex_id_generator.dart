import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateHexId({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  required String dob,
  required String gender,
}) {
  final input = email + password + firstName + lastName + dob + gender;
  final bytes = utf8.encode(input);
  final digest = sha512.convert(bytes);
  return digest.toString().substring(0, 16);
}

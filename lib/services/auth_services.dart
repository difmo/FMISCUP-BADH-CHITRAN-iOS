class AuthService {
  static const String _baseUrl = 'https://fcrupid.fmisc.up.gov.in/api/appuserapi';
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    if (!await GlobalClass.checkInternet()) {
      throw Exception('No internet connection');
    }

    final url = Uri.parse('$_baseUrl/PALogin');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userid': email, 'password': password}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return {
            'success': true,
            'data': jsonResponse['data'],
            'message': 'Login successful'
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Login failed'
          };
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Invalid email or password'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'Server error, please try again later'};
      } else {
        return {
          'success': false,
          'message': 'Request failed with status: ${response.statusCode}'
        };
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> sendOtp(String mobileNumber, String otp) async {
    if (!await GlobalClass.checkInternet()) {
      throw Exception('No internet connection');
    }

    final url = Uri.parse(
      'https://smsjust.com/sms/user/urlsms.php?'
      'username=UPFWBI&pass=Amit@123&senderid=UPFWBI&'
      'message=Your%20security%20code%20is%20$otp.%20UPFWBI&'
      'dest_mobileno=$mobileNumber&msgtype=TXT&response=Y',
    );

    try {
      final response = await http.get(url).timeout(_timeout);
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to send OTP: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

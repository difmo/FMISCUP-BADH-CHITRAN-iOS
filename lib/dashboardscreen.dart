import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fmiscupaap3/uploadfloodworkscreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'globalclass.dart';
import 'loginscreen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // for SharedPreferences
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ministers = [
    {
      'name': 'Yogi Adityanath',
      'position': 'Hon\'ble Chief Minister\nUttar Pradesh',
      'imagePath': 'assets/image/yogiji.jpg',
    },
    {
      'name': 'Shri Swatantra Dev Singh',
      'position': 'Hon\'ble Cabinet Minister\nJal Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/swatantra.jpg',
    },
    {
      'name': 'Shri Dinesh Khateek',
      'position': 'Hon\'ble Minister of State\nJal Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/dinesh.jpg',
    },
    {
      'name': 'Shri Ramkesh Nishad',
      'position': 'Hon\'ble Minister of State\nJal Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/ramkesh.jpg',
    },
  ];

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    sendLocalData();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn =
          (prefs.getString('userId') != null &&
              prefs.getString('userId')!.isNotEmpty);
    });
  }

  void sendLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    String request = prefs.getString('uploadRequestData') ?? "";
    if (request.isNotEmpty) {
      Map<String, dynamic> requestData = await jsonDecode(request);
      String imagePath = prefs.getString('imagePath') ?? "";
      imagePath = jsonDecode(imagePath);
      if (await GlobalClass.checkInternet()) {
        await sendLocalDataOnServer(requestData, imagePath);
      }
    }
  }

  Future<void> sendLocalDataOnServer(
    Map<String, dynamic> requestData,
    String imagePath,
  ) async {
    Map<String, String> requestDataString = requestData.map((key, value) {
      return MapEntry(key, value.toString());
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://fcrupid.fmisc.up.gov.in/api/AppPhotoAPI/PAImgUpload'),
    );
    GlobalClass.logRequest(
      'https://fcrupid.fmisc.up.gov.in/api/AppPhotoAPI/PAImgUpload',
      body: requestDataString,
    );
    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();
      GlobalClass.logResponse(
        'https://fcrupid.fmisc.up.gov.in/api/AppPhotoAPI/PAImgUpload',
        response.statusCode,
        responseBody,
      );
      var decodedResponse = jsonDecode(responseBody);
      if (decodedResponse['success'] == true) {
        clearData();
        _showDialog('Success', decodedResponse['message']);
      }
    } catch (e) {
      print('Upload error: $e');
    } finally {}
  }

  void clearData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('uploadRequestData', "");
    prefs.setString('imagePath', "");
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xffE6F0FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xff1A237E),
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered text
                Center(
                  child: Text(
                    'बाढ़ चित्रण',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Left logo
                Positioned(
                  left: 10,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/image/logo.png'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                // Right Logout Button
                if (_isLoggedIn)
                  Positioned(
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        setState(() {
                          _isLoggedIn = false;
                        });
                        GlobalClass.customToast("Logged out successfully");
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Blue Box with Hindi text
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF62c0fe), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: const Color(0xff1A237E), width: 3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'FMISC फ्लड मोबाइल ऐप बाढ़ से संबंधित रियल-टाइम जानकारी, चेतावनियाँ और सुरक्षा युक्तियाँ प्रदान करता है। यह उपयोगकर्ताओं को बाढ़ प्रभावित क्षेत्रों के इंटरैक्टिव मानचित्र, आपातकालीन संपर्क विवरण और स्थानीय अधिकारियों को स्थिति रिपोर्ट करने की सुविधा प्रदान करता है।',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign:
                      TextAlign
                          .justify, // Ensures the text stretches across the container
                  //   textDirection: TextDirection.rtl, // Ensures Hindi text aligns properly
                ),
              ),
              SizedBox(height: 10),
              // Ministers Title
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xff1A237E),
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: const Text(
                    "Hon'ble Ministers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Minister Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;

                  int crossAxisCount;
                  if (screenWidth < 600) {
                    crossAxisCount = 2;
                  } else if (screenWidth < 900) {
                    crossAxisCount = 3;
                  } else {
                    crossAxisCount = 4;
                  }

                  List<List<Map<String, String>>> rows = [];
                  for (int i = 0; i < ministers.length; i += crossAxisCount) {
                    int end = i + crossAxisCount;
                    if (end > ministers.length) {
                      end = ministers.length;
                    }
                    rows.add(ministers.sublist(i, end));
                  }

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: rows.asMap().entries.map((entry) {
                        int rowIndex = entry.key;
                        List<Map<String, String>> rowItems = entry.value;

                        return Padding(
                          padding: EdgeInsets.only(bottom: rowIndex == rows.length - 1 ? 0 : 12),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: List.generate(crossAxisCount, (colIndex) {
                                Widget childWidget;
                                if (colIndex < rowItems.length) {
                                  final minister = rowItems[colIndex];
                                  final isWideImage = minister['name'] == 'Yogi Adityanath';
                                  childWidget = MinisterCard(
                                    name: minister['name']!,
                                    position: minister['position']!,
                                    imagePath: minister['imagePath']!,
                                    isWideImage: isWideImage,
                                  );
                                } else {
                                  childWidget = const SizedBox.shrink();
                                }

                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: colIndex == 0 ? 0 : 6,
                                      right: colIndex == crossAxisCount - 1 ? 0 : 6,
                                    ),
                                    child: childWidget,
                                  ),
                                );
                              }),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
              // Continue Button
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1A237E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final String? userId = prefs.getString('userId');

                      if (userId != null && userId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadFloodWorkScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MinisterCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String position;
  final bool isWideImage;

  const MinisterCard({
    super.key,
    required this.name,
    required this.position,
    required this.imagePath,
    this.isWideImage = false,
  });

  String _formatText(String text) {
    List<String> words = text.split(' ');
    if (words.length <= 1) return text;
    if (words.length == 3) {
      return '${words[0]} ${words[1]}\n${words[2]}';
    }
    int mid = words.length ~/ 2;
    return '${words.sublist(0, mid).join(' ')}\n${words.sublist(mid).join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.4,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF62c0fe), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Color(0xFF0D47A1), width: 1.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                imagePath,
                width: isWideImage ? 120 : 80,
                height: isWideImage ? 95 : 80,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatText(name),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.030,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              position,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.023,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

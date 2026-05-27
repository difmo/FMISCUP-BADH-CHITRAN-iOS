import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fmiscupaap3/dashboardscreen.dart';
import 'package:fmiscupaap3/globalclass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class UploadFloodWorkScreen extends StatefulWidget {
  const UploadFloodWorkScreen({super.key});

  @override
  _UploadFloodWorkScreenState createState() => _UploadFloodWorkScreenState();
}

class _UploadFloodWorkScreenState extends State<UploadFloodWorkScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _riverNameController = TextEditingController();
  final _riverSideController = TextEditingController();
  final _districtController = TextEditingController();
  final _blockController = TextEditingController();
  final _villageController = TextEditingController();
  final _workNameController = TextEditingController();
  final _workDurationController = TextEditingController();
  final _remarksController =
      TextEditingController(); // Added controller for Remarks
  final _elevationController = TextEditingController();
  final _accuracyController = TextEditingController();
  bool _isLoading = true;
  bool _isImageError = false;
  bool _isUploading = false;
  File? _selectedImage;
  dynamic _selectedRiver;
  List<dynamic> _riverList = [];
  double? _elevation = 0;
  double? _accuracy = 0;
  double? _latitude;
  double? _longitude;
  bool _isImageUploading = false;
  String? _userId;
  File? _pickedImage;
  List<dynamic> _districtList = [];
  dynamic _selectedDistrict;

  // Future<void> _pickImage() async {
  //   final picked = await ImagePicker().pickImage(source: ImageSource.camera);
  //   if (picked != null) {
  //     setState(() {
  //       _selectedImage = File(picked.path);
  //     });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    fetchDistricts();
    _fetchRivers();
    fetchLocationData(context);
    loadUserId();
  }

  void loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  Future<void> fetchLocationData(BuildContext context) async {
    LocationPermission permission;
    while (!await Geolocator.isLocationServiceEnabled()) {
      bool shouldContinue = await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: Text("Enable Your Location"),
              content: Text(
                "Please enable location on your device to proceed.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text("Retry"),
                ),
              ],
            ),
      );

      if (shouldContinue != true) return;
      await Future.delayed(Duration(seconds: 1));
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text("Permission Denied"),
                content: Text(
                  "Location permission is denied. Please allow access from app settings.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              ),
        );
        return;
      }
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // You can store these in variables or use them directly
    double latitude = position.latitude;
    double longitude = position.longitude;
    double elevation = position.altitude;
    double accuracy = position.accuracy;

    // Optional: Store them in class variables if needed
    _latitude = latitude;
    _longitude = longitude;
    _elevation = elevation;
    _accuracy = accuracy;

    print('Latitude: $latitude');
    print('Longitude: $longitude');
    print('Elevation: $elevation');
    print('Accuracy: $accuracy');
  }

  Future<void> fetchLocationData2() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Permissions are denied
        return;
      }
    }
    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // ✅ Store values in variables
    _elevation = position.altitude;
    _accuracy = position.accuracy;
    print('Elevation: $_elevation');
    print('Accuracy: $_accuracy');
  }

  Future<void> fetchDistricts({int retryCount = 0}) async {
    const String url =
        'https://fcrupid.fmisc.up.gov.in/api/appstationapi/GetDistrictDDL';
    final headers = {
      'Accept': 'application/json',
      'User-Agent': 'FMISC-UP-App',
      'Connection': 'keep-alive',
    };
    GlobalClass.logRequest(url, headers: headers);
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      GlobalClass.logResponse(url, response.statusCode, response.body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            _districtList = jsonData['data'];
          });
        }
      } else {
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 1));
          return fetchDistricts(retryCount: retryCount + 1);
        }
      }
    } catch (e) {
      if (retryCount < 2) {
        await Future.delayed(const Duration(seconds: 1));
        return fetchDistricts(retryCount: retryCount + 1);
      }
      print('Error in fetchDistricts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<File?> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'custom_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String customPath = path.join(appDir.path, fileName);

      File originalFile = File(pickedFile.path);
      int fileSize = await originalFile.length();

      // Check if file is already under 4 MB
      if (fileSize <= 4 * 1024 * 1024) {
        final File newImage = await originalFile.copy(customPath);
        return newImage;
      }

      // Compress the image if it's larger than 4 MB
      final String compressedPath = path.join(
        appDir.path,
        'compressed_$fileName',
      );
      final XFile? compressedFile =
          (await FlutterImageCompress.compressAndGetFile(
            originalFile.path,
            compressedPath,
            quality: 70, // You can adjust quality for better size control
          ));
      File file = File(compressedFile?.path ?? "");
      if (await file.length() <= 4 * 1024 * 1024) {
        return file;
      } else {
        // If still too big, return null or handle accordingly
        print('Image is too large even after compression.');
        return null;
      }
    }
    return null;
  }

  void _handlePhotoCapture() async {
    try {
      final File? imagePath = await _takePhoto();
      if (imagePath != null) {
        setState(() {
          _pickedImage = imagePath;
        });
      } else {
        print('No photo captured.');
      }
    } catch (e) {
      e.toString();
    }
  }

  Future<void> uploadImageToServer(File imageFile) async {
    final districtIdToSend = _selectedDistrict?['districtID'].toString() ?? '';
    final riverNameToSend = _selectedRiver?['riverName'] ?? '';
    var requestData = {
      'UserID': _userId,
      'Title': _workNameController.text,
      'DistrictID': districtIdToSend,
      'Block': _blockController.text,
      'Village': _villageController.text,
      'Elevation': _elevation,
      'Accuracy': _accuracy,
      'RiverSide': _riverSideController.text,
      'PhotoTaken': _workDurationController.text,
      'RiverName': riverNameToSend,
      'Remarks': _remarksController.text,
      'Latitude': _latitude,
      'Longitude': _longitude,
    };
    print(
      'sdasdfdsfgfdgddfgr  : $_elevation , $_accuracy , userid : $_userId '
      ', _latitude : $_latitude '
      ', Longitude : $_longitude  ',
    );
    Map<String, String> requestDataString = requestData.map((key, value) {
      return MapEntry(key, value.toString());
    });
    if (await checkInternet() == true) {
      setState(() {
        _isImageError = _pickedImage == null;
        _isUploading = true;
      });

      if (_pickedImage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please upload an image")));
        setState(() => _isUploading = false);
        return;
      }
      if (_selectedDistrict == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a district')));
        setState(() => _isUploading = false);
        return;
      }

      int retryCount = 0;
      const int maxRetries = 3;
      bool uploadSuccess = false;
      String lastError = '';

      while (retryCount < maxRetries && !uploadSuccess) {
        var client = http.Client();
        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://fcrupid.fmisc.up.gov.in/api/AppPhotoAPI/PAImgUpload',
            ),
          );

          request.headers.addAll({
            'Accept': 'application/json, text/plain, */*',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
            'Connection': 'keep-alive',
          });

          request.fields.addAll(requestDataString);

          request.files.add(
            await http.MultipartFile.fromPath(
              'WorkImage',
              imageFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );

          GlobalClass.logRequest(
            'https://fcrupid.fmisc.up.gov.in/api/AppPhotoAPI/PAImgUpload',
            body: requestDataString,
          );

          // Use client.send to allow for timeout and resource management
          http.StreamedResponse response = await client
              .send(request)
              .timeout(const Duration(seconds: 60));

          String responseBody = await response.stream.bytesToString();
          GlobalClass.logResponse(
            'https://fcrupid.fmisc.up.gov.in/api/AppPhotoAPI/PAImgUpload',
            response.statusCode,
            responseBody,
          );

          var decodedResponse = jsonDecode(responseBody);
          if (decodedResponse['success'] == true) {
            uploadSuccess = true;
            _showDialog('Success', decodedResponse['message']);
          } else {
            // If server returns success=false, don't retry, it's a logic error
            _showDialog('Failure', decodedResponse['message']);
            break;
          }
        } catch (e) {
          print('Upload attempt ${retryCount + 1} failed: $e');
          lastError = e.toString();
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: 2)); // Wait before retry
          }
        } finally {
          client.close();
        }
      }

      if (!uploadSuccess && retryCount == maxRetries) {
        _showDialog(
          'Error',
          'Upload failed after $maxRetries attempts. Error: $lastError',
        );
      }

      setState(() => _isUploading = false);
    } else {
      //todo local
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('uploadRequestData', jsonEncode(requestData));
      prefs.setString('imagePath', jsonEncode(imageFile.path));
      _showDialog('Success', "Data Locally Saved Successfully");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (title == 'Success') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showLoaderDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 4.0,
              ),
              const SizedBox(height: 10),
              const Text(
                'Uploading...',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchRivers({int retryCount = 0}) async {
    final url = Uri.parse(
      'https://fcrupid.fmisc.up.gov.in/api/appphotoapi/GetRiverDDL',
    );
    final headers = {
      'Accept': 'application/json',
      'User-Agent': 'FMISC-UP-App',
      'Connection': 'keep-alive',
    };
    GlobalClass.logRequest(url.toString(), headers: headers);
    try {
      final response = await http.get(url, headers: headers);
      GlobalClass.logResponse(
        url.toString(),
        response.statusCode,
        response.body,
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            _riverList = jsonData['data'];
            _isLoading = false;
          });
        }
      } else {
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 1));
          return _fetchRivers(retryCount: retryCount + 1);
        }
      }
    } catch (e) {
      if (retryCount < 2) {
        await Future.delayed(const Duration(seconds: 1));
        return _fetchRivers(retryCount: retryCount + 1);
      }
      print('Error in _fetchRivers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    setState(() {
      _isImageUploading = true;
    });

    // Check and request camera permission
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera,
        );
        if (pickedFile != null) {
          File imageFile = File(pickedFile.path);
          // Compress the image to ensure it's under 4MB
          final Directory appDir = await getTemporaryDirectory();
          final String compressedPath = path.join(
            appDir.path,
            'compressed_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          final XFile? compressedFile =
              await FlutterImageCompress.compressAndGetFile(
                imageFile.path,
                compressedPath,
                quality: 85, // Adjust quality as needed
              );

          if (compressedFile != null) {
            File compressedImageFile = File(compressedFile.path);
            final fileSize = await compressedImageFile.length();
            if (fileSize <= 4 * 1024 * 1024) {
              setState(() {
                _pickedImage = compressedImageFile;
                _isImageError = false;
              });
              print(
                'Compressed image size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size exceeds 4 MB after compression.'),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image compression failed.')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    } else if (status.isPermanentlyDenied) {
      // Show dialog to guide user to settings
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Camera Permission Required'),
              content: const Text(
                'Please enable camera access from settings to capture photos.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Open Settings'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }

    setState(() {
      _isImageUploading = false;
    });
  }

  Future<bool> checkInternet() async {
    try {
      final socket = await Socket.connect(
        'google.com',
        80,
        timeout: Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildIntegerTextField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xff1A237E),
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered title
                const Center(
                  child: Text(
                    'बाढ़ चित्रण',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Left side: Back button and Logo
                Positioned(
                  left: 10,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 5),
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/image/logo.png'),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                // Right side: Logout button
                Positioned(
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _logout();
                                  },
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: 'River Name',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedRiver,
                    items:
                        _riverList.map((river) {
                          return DropdownMenuItem(
                            value: river,
                            child: Text(river['riverName']),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRiver = value;
                        print('ddff: $_selectedRiver');
                      });
                    },
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'River Side',
                    border: OutlineInputBorder(),
                  ),
                  initialValue:
                      _riverSideController.text.isNotEmpty
                          ? _riverSideController.text
                          : null,
                  items:
                      ['Left', 'Right'].map((side) {
                        return DropdownMenuItem(value: side, child: Text(side));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _riverSideController.text = value!;
                    });
                  },
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Please select river side'
                              : null,
                ),
                SizedBox(height: 10),
                // Inside your widget:
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(
                    labelText: 'Choose District',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedDistrict,
                  items:
                      _districtList.map<DropdownMenuItem<Map<String, dynamic>>>(
                        (district) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: district,
                            child: Text(district['districtName']),
                          );
                        },
                      ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                      print(
                        '_selectedDistrictID: ${_selectedDistrict?['districtID']}',
                      );
                    });
                  },
                ),
                SizedBox(height: 10),
                _buildTextField('Block', _blockController),
                SizedBox(height: 10),
                _buildTextField('Village', _villageController),
                SizedBox(height: 10),
                _buildTextField('Work Name', _workNameController),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Work duration',
                    border: OutlineInputBorder(),
                  ),
                  initialValue:
                      _workDurationController.text.isNotEmpty
                          ? _workDurationController.text
                          : null,
                  items:
                      ['Before Work', 'During Work', 'After Work'].map((side) {
                        return DropdownMenuItem(value: side, child: Text(side));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _workDurationController.text = value!;
                    });
                  },
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Please select Work duration'
                              : null,
                ),
                const SizedBox(height: 10),
                _buildTextField('Remarks', _remarksController),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _handlePhotoCapture(),
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          label: Text(
                            'Upload Image',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0056A4),
                          ),
                        ),
                        const SizedBox(width: 20),
                        if (_isImageUploading)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_pickedImage != null)
                          Image.file(
                            _pickedImage!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                    if (_isImageError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Image is required',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isUploading
                            ? null
                            : () async {
                              if (!_formKey.currentState!.validate()) {
                                setState(() {
                                  _isImageError = _pickedImage == null;
                                });
                                return;
                              }

                              setState(() {
                                _isUploading = true;
                              });
                              // if(await checkInternet() == false) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     SnackBar(content: Text('No internet connection')),
                              //   );
                              //   setState(() {
                              //     _isUploading = false;
                              //   });
                              //   return;
                              // }

                              try {
                                bool locationEnabled =
                                    await Geolocator.isLocationServiceEnabled();
                                if (!locationEnabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please enable your location',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                LocationPermission permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                  if (permission == LocationPermission.denied) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Location permission is required',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                if (permission ==
                                    LocationPermission.deniedForever) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Location permission permanently denied. Please enable it from settings.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await fetchLocationData2();
                                if (_pickedImage != null) {
                                  await uploadImageToServer(_pickedImage!);
                                } else {
                                  setState(() {
                                    _isImageError = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please upload an image'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print("Upload Error: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isUploading = false;
                                  });
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0056A4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child:
                        _isUploading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

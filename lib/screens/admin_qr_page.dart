import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AdminQrPage extends StatefulWidget {
  const AdminQrPage({super.key});

  @override
  _AdminQrPageState createState() => _AdminQrPageState();
}

class _AdminQrPageState extends State<AdminQrPage> {  final AuthService _authService = AuthService();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _expiresHoursController = TextEditingController();
  
  // Global key for capturing QR code widget
  final GlobalKey _qrKey = GlobalKey();
  
  String? _generatedQRData;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _isSharing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _checkAdminPermissions();
  }
  void _initializeForm() {
    // Set default values with future dates to test different scenarios
    _eventNameController.text = 'Daily Attendance';
    
    // Use tomorrow's date as default to avoid conflicts
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _dateController.text = tomorrow.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    
    _expiresHoursController.text = '24';
  }

  // Helper method to generate different test dates
  void _setTestDate(int daysFromNow) {
    final targetDate = DateTime.now().add(Duration(days: daysFromNow));
    _dateController.text = targetDate.toIso8601String().split('T')[0];
  }
  @override
  void dispose() {
    _eventNameController.dispose();
    _dateController.dispose();
    _expiresHoursController.dispose();
    super.dispose();
  }

  // Method to capture QR code as image
  Future<Uint8List?> _captureQRCode() async {
    try {
      RenderRepaintBoundary? boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing QR code: $e');
      return null;
    }
  }

  // Method to save QR code to gallery
  Future<void> _saveToGallery() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final imageBytes = await _captureQRCode();
      if (imageBytes == null) {
        throw Exception('Failed to capture QR code image');
      }

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: "QR_${_eventNameController.text}_${_dateController.text}",
        isReturnImagePathOfIOS: true,
      );

      if (result['isSuccess'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('QR Code saved to gallery!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Failed to save image to gallery');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save QR code: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Method to share QR code
  Future<void> _shareQRCode() async {
    setState(() {
      _isSharing = true;
      _errorMessage = null;
    });

    try {
      final imageBytes = await _captureQRCode();
      if (imageBytes == null) {
        throw Exception('Failed to capture QR code image');
      }

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'QR_${_eventNameController.text}_${_dateController.text}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code for ${_eventNameController.text} - ${_dateController.text}\n\nGenerated with Go Cloud Frontend',
        subject: 'QR Code - ${_eventNameController.text}',
      );
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to share QR code: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _checkAdminPermissions() async {
    try {
      // Check if user has access token
      final token = await _authService.getAccessToken();
      if (token == null) {
        _redirectToLogin();
        return;
      }

      // Check if user has admin role
      final isAdmin = await _authService.isUserAdmin();
      if (!isAdmin) {
        _redirectToUnauthorized();
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _redirectToUnauthorized() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }
  Future<void> _generateQRCode() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    // Validate input
    final eventName = _eventNameController.text.trim();
    final date = _dateController.text.trim();
    final expiresHoursText = _expiresHoursController.text.trim();

    if (eventName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an event name';
      });
      return;
    }

    if (date.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a date';
      });
      return;
    }

    // Validate date format (YYYY-MM-DD)
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(date)) {
      setState(() {
        _errorMessage = 'Date must be in YYYY-MM-DD format';
      });
      return;
    }

    int expiresHours;
    try {
      expiresHours = int.parse(expiresHoursText);
      if (expiresHours <= 0) {
        throw const FormatException();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Expires hours must be a positive number';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Get admin token
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      // Prepare payload
      final payload = {
        'event_name': eventName,
        'date': date,
        'expires_hours': expiresHours,
      };      // Make API call
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/qr/admin/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));// Debug: Print response details
      print('🔍 QR Generation Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('📦 Parsed Response Data: $responseData');
        
        // Handle different response formats
        String qrData = '';
        if (responseData.containsKey('qr_content')) {
          qrData = responseData['qr_content'];
        } else if (responseData.containsKey('jwt_token')) {
          qrData = responseData['jwt_token'];
        } else if (responseData.containsKey('qr_data')) {
          qrData = responseData['qr_data'];
        } else if (responseData.containsKey('token')) {
          qrData = responseData['token'];
        } else {
          // If no recognized field, try to find any string value
          qrData = responseData.values.firstWhere(
            (value) => value is String && value.isNotEmpty,
            orElse: () => responseData.toString(),
          );
        }
        
        print('🎯 Extracted QR Data: $qrData');
        
        setState(() {
          _generatedQRData = qrData;
          _successMessage = 'QR Code generated successfully!\nEvent: ${_eventNameController.text}\nDate: ${_dateController.text}';
          _errorMessage = null;
          _isGenerating = false;
        });
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Admin privileges required.');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden. Access denied.');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to generate QR code (${response.statusCode})');
        } catch (e) {
          throw Exception('Failed to generate QR code: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate QR code: $e';
        _isGenerating = false;
      });
    }
  }  void _clearQRCode() {
    setState(() {
      _generatedQRData = null;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0f0f23),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Admin QR Generator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'QR Code Generator',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),                  const SizedBox(height: 12),
                  Text(
                    'Generate QR codes for attendance tracking with JWT tokens',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Input Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Event Name Field
                  TextField(
                    controller: _eventNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintText: 'e.g., Daily Attendance',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF0f0f23),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF667eea),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date Field
                  TextField(
                    controller: _dateController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintText: '2025-06-08',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF0f0f23),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF667eea),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.grey[400]),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            _dateController.text = date.toIso8601String().split('T')[0];
                          }                        },
                      ),
                    ),
                  ),
                  
                  // Quick Date Selection Buttons
                  const SizedBox(height: 12),
                  Text(
                    'Quick Date Selection:',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickDateButton('Tomorrow', 1),
                      _buildQuickDateButton('2 days', 2),
                      _buildQuickDateButton('3 days', 3),
                      _buildQuickDateButton('1 week', 7),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Expires Hours Field
                  TextField(
                    controller: _expiresHoursController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Expires Hours',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintText: '24',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF0f0f23),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF667eea),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isGenerating ? null : _generateQRCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isGenerating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Generate QR Code',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_generatedQRData != null) ...[
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _clearQRCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear, size: 20),
                              SizedBox(width: 4),
                              Text('Clear'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // QR Code Display Section
            if (_generatedQRData != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Generated QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),                    const SizedBox(height: 24),
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: _generatedQRData!,
                          size: 200,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action buttons for QR code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Save button
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveToGallery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: _isSaving 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save_alt, size: 18),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        
                        // Share button
                        ElevatedButton.icon(
                          onPressed: _isSharing ? null : _shareQRCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: _isSharing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.share, size: 18),
                          label: Text(
                            _isSharing ? 'Sharing...' : 'Share',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Size: 200x200 pixels',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Debug Information
                    ExpansionTile(
                      title: Text(
                        'Debug Information',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      iconColor: Colors.grey[400],
                      collapsedIconColor: Colors.grey[400],
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0f0f23),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QR Data Length: ${_generatedQRData!.length} characters',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Raw JWT Token:',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                _generatedQRData!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),      ),
    );
  }

  // Helper method to build quick date selection buttons
  Widget _buildQuickDateButton(String label, int daysFromNow) {
    return ElevatedButton(
      onPressed: () => _setTestDate(daysFromNow),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667eea).withValues(alpha: 0.3),
        foregroundColor: const Color(0xFF667eea),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

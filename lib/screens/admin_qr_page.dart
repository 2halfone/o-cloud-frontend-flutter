import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  State<AdminQrPage> createState() => _AdminQrPageState();
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
  bool _isSharing = false;  String? _errorMessage;
  String? _successMessage;
  Color _qrBackgroundColor = Colors.white;
    // QR Customization variables
  Color _qrCodeColor = Colors.black;
  Color _textColor = Colors.black;
  double _qrSize = 200.0;
  double _textSize = 16.0;
  bool _showBorder = false;
  bool _showShadow = false;
  String? _expandedPanel; // null, 'colors', 'style', 'size'

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
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);    return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
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
          ScaffoldMessenger.of(context).showSnackBar(            const SnackBar(
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
        body: jsonEncode(payload),      ).timeout(const Duration(seconds: 15));// Debug: Print response details
      debugPrint('🔍 QR Generation Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Response Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        debugPrint('📦 Parsed Response Data: $responseData');
        
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
          );        }
        
        debugPrint('🎯 Extracted QR Data: $qrData');
          setState(() {
          _generatedQRData = qrData;
          _successMessage = 'QR Code generated successfully with event details!\nEvent: ${_eventNameController.text}\nDate: ${_dateController.text}\n\nThe QR code now includes the event name and date for easy identification.';
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
                    ),                    const SizedBox(height: 24),                    // QR Code Section
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _qrBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: _showBorder ? Border.all(
                            color: _qrCodeColor.withValues(alpha: 0.3),
                            width: 2,
                          ) : null,
                          boxShadow: _showShadow ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Event Name
                            Text(
                              _eventNameController.text.isNotEmpty 
                                ? _eventNameController.text 
                                : 'Event',
                              style: TextStyle(
                                fontSize: _textSize,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Date
                            Text(
                              _dateController.text.isNotEmpty 
                                ? _dateController.text 
                                : 'Date',
                              style: TextStyle(
                                fontSize: _textSize - 2,
                                fontWeight: FontWeight.w600,
                                color: _textColor.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // QR Code
                            QrImageView(
                              data: _generatedQRData!,
                              size: _qrSize,
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: _qrCodeColor,
                              ),
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: _qrCodeColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Footer text
                            Text(
                              'Scan to register attendance',
                              style: TextStyle(
                                fontSize: _textSize - 4,
                                color: _textColor.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),                    const SizedBox(height: 16),
                    
                    // Minimal QR Customization Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCustomizationButton(
                          'Colors',
                          Icons.palette,
                          'colors',
                          const Color(0xFF667eea),
                        ),
                        _buildCustomizationButton(
                          'Style',
                          Icons.style,
                          'style',
                          const Color(0xFF4CAF50),
                        ),
                        _buildCustomizationButton(
                          'Size',
                          Icons.photo_size_select_large,
                          'size',
                          const Color(0xFFFF9800),
                        ),
                      ],
                    ),
                    
                    // Expanded Options Panel
                    if (_expandedPanel != null) ...[
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f0f23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getPanelColor(_expandedPanel!).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header with close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getPanelTitle(_expandedPanel!),
                                  style: TextStyle(
                                    color: _getPanelColor(_expandedPanel!),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _expandedPanel = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Panel content
                            _buildPanelContent(_expandedPanel!),
                          ],
                        ),
                      ),
                    ],
                    
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
          ],        ),      ),
    );  }
  // Minimal Customization Button System  // Minimal Customization Button System
  Widget _buildCustomizationButton(String label, IconData icon, String panelId, Color color) {
    final bool isActive = _expandedPanel == panelId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedPanel = isActive ? null : panelId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
            ? color.withValues(alpha: 0.2) 
            : const Color(0xFF0f0f23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? color : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get panel color based on panel type
  Color _getPanelColor(String panelId) {
    switch (panelId) {
      case 'colors':
        return const Color(0xFF667eea);
      case 'style':
        return const Color(0xFF4CAF50);
      case 'size':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF667eea);
    }
  }

  // Get panel title based on panel type
  String _getPanelTitle(String panelId) {
    switch (panelId) {
      case 'colors':
        return 'Color Options';
      case 'style':
        return 'Style Options';
      case 'size':
        return 'Size Options';
      default:
        return 'Options';
    }
  }

  // Build panel content based on panel type
  Widget _buildPanelContent(String panelId) {
    switch (panelId) {
      case 'colors':
        return _buildColorsPanel();
      case 'style':
        return _buildStylePanel();
      case 'size':
        return _buildSizePanel();
      default:
        return _buildColorsPanel();
    }
  }

  // Colors panel for minimal interface
  Widget _buildColorsPanel() {
    return Column(
      children: [
        // Background Colors
        _buildMinimalColorSection(
          'Background',
          [
            Colors.white,
            const Color(0xFFF5F5F5),
            const Color(0xFFE3F2FD),
            const Color(0xFFE8F5E8),
            const Color(0xFFFFF3E0),
          ],
          _qrBackgroundColor,
          (color) => setState(() => _qrBackgroundColor = color),
        ),
        const SizedBox(height: 16),
        // QR Code Colors
        _buildMinimalColorSection(
          'QR Code',
          [
            Colors.black,
            const Color(0xFF1565C0),
            const Color(0xFF2E7D32),
            const Color(0xFFE65100),
            const Color(0xFF6A1B9A),
          ],
          _qrCodeColor,
          (color) => setState(() => _qrCodeColor = color),
        ),
        const SizedBox(height: 16),
        // Text Colors
        _buildMinimalColorSection(
          'Text',
          [
            Colors.black,
            const Color(0xFF424242),
            const Color(0xFF1565C0),
            const Color(0xFF2E7D32),
            const Color(0xFF6A1B9A),
          ],
          _textColor,
          (color) => setState(() => _textColor = color),
        ),
      ],
    );
  }

  // Style panel for minimal interface
  Widget _buildStylePanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMinimalStyleToggle(
          'Border',
          Icons.border_all,
          _showBorder,
          (value) => setState(() => _showBorder = value),
        ),
        _buildMinimalStyleToggle(
          'Shadow',
          Icons.blur_on,
          _showShadow,
          (value) => setState(() => _showShadow = value),
        ),
      ],
    );
  }

  // Size panel for minimal interface
  Widget _buildSizePanel() {
    return Column(
      children: [
        _buildMinimalSlider(
          'QR Size',
          _qrSize,
          150.0,
          300.0,
          (value) => setState(() => _qrSize = value),
        ),
        const SizedBox(height: 20),
        _buildMinimalSlider(
          'Text Size',
          _textSize,
          12.0,
          24.0,
          (value) => setState(() => _textSize = value),
        ),
      ],
    );
  }

  // Minimal color section helper
  Widget _buildMinimalColorSection(String title, List<Color> colors, Color selectedColor, Function(Color) onColorSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF667eea),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: colors.map((color) => 
            _buildMinimalColorOption(color, selectedColor == color, () => onColorSelected(color))
          ).toList(),
        ),
      ],
    );
  }

  // Minimal color option helper
  Widget _buildMinimalColorOption(Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                size: 18,
                color: Color(0xFF667eea),
              )
            : null,
      ),
    );
  }

  // Minimal style toggle helper
  Widget _buildMinimalStyleToggle(String label, IconData icon, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: value 
            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value 
              ? const Color(0xFF4CAF50)
              : Colors.grey.withValues(alpha: 0.3),
            width: value ? 2 : 1,
          ),
          boxShadow: value ? [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: value ? const Color(0xFF4CAF50) : Colors.grey[400],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? const Color(0xFF4CAF50) : Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Minimal slider helper
  Widget _buildMinimalSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.round()}',
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF9800),
            thumbColor: const Color(0xFFFF9800),
            overlayColor: const Color(0xFFFF9800).withValues(alpha: 0.2),
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

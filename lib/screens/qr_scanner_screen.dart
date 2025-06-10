import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'dart:io';
import '../widgets/qr_scanner/qr_camera_widget.dart';
import '../widgets/qr_scanner/attendance_form.dart';
import '../services/attendance_service.dart';
import '../models/attendance.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  bool _hasPermission = false;
  bool _isFlashOn = false;
  String? _scannedData;
  bool _showAttendanceForm = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkCameraPermission();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    }
  }
  void _onQRScanned(String data) async {
    setState(() {
      _scannedData = data;
    });
    
    // Check if user already has attendance for today
    await _checkTodayAttendanceBeforeShowingForm();
  }

  Future<void> _checkTodayAttendanceBeforeShowingForm() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      final attendanceService = AttendanceService();
      final todayAttendanceResponse = await attendanceService.getTodayAttendance();
      
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (todayAttendanceResponse.hasAttendance) {
        // User already has attendance for today - show informational dialog
        if (mounted) {
          _showAttendanceAlreadyRegisteredDialog(todayAttendanceResponse);
        }
      } else {
        // No attendance yet - show attendance form
        if (mounted) {
          setState(() {
            _showAttendanceForm = true;
          });
        }
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // If there's an error checking today's attendance, still allow them to try submitting
      // This ensures the app doesn't break if the check fails
      print('Error checking today\'s attendance: $e');
      
      if (mounted) {
        setState(() {
          _showAttendanceForm = true;
        });
        
        // Optionally show a warning that we couldn't check today's attendance
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not verify today\'s attendance status: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  void _showAttendanceAlreadyRegisteredDialog(TodayAttendanceResponse todayResponse) {
    final attendance = todayResponse.attendance;
    final statusText = attendance?.status.toString().split('.').last ?? 'unknown';
    final timeText = attendance?.timestamp != null 
        ? _formatTime(attendance!.timestamp.toString())
        : 'unknown time';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[400]),
            const SizedBox(width: 8),
            const Text(
              'Attendance Already Registered',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have already registered your attendance for today.',
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
            ),
            if (attendance != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${statusText.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(statusText),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: $timeText',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Event: ${attendance.eventName}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.blue[400]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return timestamp;
    }
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  void _onFlashToggle() {
    print('Flash toggle called - current state: $_isFlashOn');
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    print('Flash toggle completed - new state: $_isFlashOn');
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFlashOn ? 'Flash turned ON' : 'Flash turned OFF'),
        duration: const Duration(seconds: 1),
        backgroundColor: _isFlashOn ? Colors.yellow[700] : Colors.grey[700],
      ),
    );
  }  Future<void> _pickImageFromGallery() async {
    print('Gallery function called');
    if (!mounted) {
      print('Widget not mounted, returning');
      return;
    }
    
    try {
      print('Requesting permissions...');
      // Request appropriate permissions based on platform
      PermissionStatus permissionStatus;
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use photos permission
        permissionStatus = await Permission.photos.request();
        if (permissionStatus.isDenied) {
          // Fallback to storage permission for older Android versions
          permissionStatus = await Permission.storage.request();
        }
      } else {
        // For iOS, photos permission is typically handled automatically by image_picker
        permissionStatus = await Permission.photos.request();
      }

      print('Permission status: $permissionStatus');
      
      if (!permissionStatus.isGranted && !permissionStatus.isLimited) {
        if (mounted) {
          _showErrorSnackBar('Gallery access permission is required');
        }
        return;
      }

      print('Opening image picker...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      
      print('Image selected: ${image?.path}');
      
      if (image != null && mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          ),
        );

        try {
          print('Scanning QR code from image...');
          // Scan QR code from the selected image
          final String? qrData = await QrCodeToolsPlugin.decodeFrom(image.path);
          
          print('QR scan result: $qrData');
          
          // Hide loading indicator
          if (mounted) {
            Navigator.of(context).pop();
            
            if (qrData != null && qrData.isNotEmpty) {
              // Successfully detected QR code
              print('QR code detected, calling onQRScanned');
              _onQRScanned(qrData);
            } else {
              _showErrorSnackBar('No QR code found in the selected image');
            }
          }
        } catch (e) {
          print('Error scanning QR code: $e');
          // Hide loading indicator
          if (mounted) {
            Navigator.of(context).pop();
            _showErrorSnackBar('Failed to scan QR code from image: $e');
          }
        }
      }
    } catch (e) {
      print('Error in gallery function: $e');
      if (mounted) {
        _showErrorSnackBar('Error during image selection: $e');
      }
    }
  }

  void _onAttendanceSubmitSuccess() {
    Navigator.pop(context);
  }

  void _onAttendanceCancel() {
    setState(() {
      _showAttendanceForm = false;
      _scannedData = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // Main content
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _hasPermission
                          ? _buildScannerContent()
                          : _buildPermissionError(),
                    ),
                    _buildBottomControls(),
                  ],
                ),                
                // Attendance Form Overlay
                if (_showAttendanceForm && _scannedData != null)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.8),
                      child: Center(
                        child: AttendanceForm(
                          qrData: _scannedData!,
                          onSubmitSuccess: _onAttendanceSubmitSuccess,
                          onCancel: _onAttendanceCancel,
                        ),
                      ),
                    ),                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a1a),
            Color(0xFF2d2d44),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR Scanner',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Scan the code to register attendance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Color(0xFF667eea),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: QRCameraWidget(
          onQRScanned: _onQRScanned,
          isFlashOn: _isFlashOn,
          onFlashToggle: _onFlashToggle,
        ),
      ),
    );
  }

  Widget _buildPermissionError() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),          const Text(
            'Camera Permission Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Grant camera access to scan QR codes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _checkCameraPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add a visual indicator that this is an interactive area
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed: () {
                    print('Gallery button pressed'); // Debug log
                    _pickImageFromGallery();
                  },
                  color: const Color(0xFF4facfe),
                ),
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Reset',
                  onPressed: () {
                    print('Reset button pressed'); // Debug log
                    setState(() {
                      _scannedData = null;
                      _showAttendanceForm = false;
                    });
                  },
                  color: const Color(0xFF667eea),
                ),
                _buildControlButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  label: 'Flash',
                  onPressed: () {
                    print('Flash button pressed'); // Debug log
                    _onFlashToggle();
                  },
                  color: _isFlashOn ? Colors.yellow : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                print('GestureDetector - Button $label tapped'); // Debug log
                // Add haptic feedback
                HapticFeedback.lightImpact();
                onPressed();
              },
              onTapDown: (_) {
                print('GestureDetector - Button $label pressed down');
              },
              onTapUp: (_) {
                print('GestureDetector - Button $label released');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      print('InkWell - Button $label tapped'); // Debug log
                      // Add haptic feedback
                      HapticFeedback.lightImpact();
                      onPressed();
                    },
                    onTapDown: (_) {
                      print('InkWell - Button $label pressed down');
                    },
                    onTapUp: (_) {
                      print('InkWell - Button $label released');
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: color.withValues(alpha: 0.3),
                    highlightColor: color.withValues(alpha: 0.1),
                    child: Container(
                      width: double.infinity,
                      height: 60, // Fixed height for consistent touch area
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        icon,
                        color: color,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

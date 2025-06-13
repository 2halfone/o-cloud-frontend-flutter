import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'dart:io';
import 'dart:async';
import '../widgets/qr_scanner/qr_camera_widget.dart';
import '../services/attendance_service.dart';
import '../models/attendance.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {  bool _hasPermission = false;
  bool _isFlashOn = false;
  String? _scannedData;
  
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
  }  void _onQRScanned(String data) async {
    setState(() {
      _scannedData = data;
    });
    
    // NEW: Direct attendance registration without status selection
    await _handleDirectAttendanceRegistration();
  }

  Future<void> _handleDirectAttendanceRegistration() async {
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
      
      // Parse QR content
      final qrContent = attendanceService.parseQRContent(_scannedData!);
      if (qrContent == null) {
        throw Exception('Invalid QR code format');
      }

      // Create request without status (automatic "present")
      final request = AttendanceRequest(
        qrContent: qrContent,
        reason: null, // No reason needed for automatic presence
      );

      // Submit attendance directly
      final response = await attendanceService.submitAttendance(request);

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog with automatic registration message
      if (mounted) {
        _showAutomaticAttendanceSuccessDialog(response);
      }

    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Check if it's a duplicate attendance error
      if (e.toString().contains('already registered') || 
          e.toString().contains('already exists') ||
          e.toString().contains('duplicate')) {
        // If already registered, check today's attendance and show info
        await _checkTodayAttendanceBeforeShowingForm();
      } else {
        // Show error message
        if (mounted) {
          _showErrorSnackBar('Failed to register attendance: $e');
        }
      }
    }
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
        }      } else {
        // No attendance yet - this should not happen with direct registration
        // Log for debugging purposes
        debugPrint('No existing attendance found, but this should have been handled by direct registration');
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // If there's an error checking today's attendance, still allow them to try submitting
      // This ensures the app doesn't break if the check fails      debugPrint('Error checking today\'s attendance: $e');
      
      // Note: With direct registration, this error handling is mainly for edge cases
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not verify today\'s attendance status: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }  void _showAutomaticAttendanceSuccessDialog(AttendanceResponse response) {
    _showValidationScreen(true);
  }

  void _showAttendanceAlreadyRegisteredDialog(TodayAttendanceResponse todayResponse) {
    _showValidationScreen(false);
  }  void _showValidationScreen(bool isSuccess) {
    debugPrint('🔊 _showValidationScreen called with isSuccess: $isSuccess');
      // 🔊 Play system sound for feedback
    try {
      if (isSuccess) {
        debugPrint('🎵 Playing success sound...');
        SystemSound.play(SystemSoundType.click); // Success sound
        HapticFeedback.lightImpact(); // Light vibration for success
        // Try alternative success sound
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.selectionClick();
        });
        debugPrint('✅ Success sound and vibration triggered');
      } else {
        debugPrint('🎵 Playing error sound...');
        SystemSound.play(SystemSoundType.alert); // Error sound
        HapticFeedback.mediumImpact(); // Medium vibration for error
        // Try stronger vibration for error
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
        });
        debugPrint('❌ Error sound and vibration triggered');
      }
    } catch (e) {
      debugPrint('⚠️ Error playing sound/vibration: $e');
    }
    
    // Navigate to full-screen validation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _ValidationScreen(
          isSuccess: isSuccess,
          onComplete: () {
            Navigator.of(context).pop(); // Close validation screen
            Navigator.of(context).pop(); // Go back to home
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showValidationScreen(false);
  }
  Future<void> _pickImageFromGallery() async {
    debugPrint('Gallery function called');
    if (!mounted) {
      debugPrint('Widget not mounted, returning');
      return;
    }
    
    try {
      debugPrint('Requesting permissions...');
      // Request appropriate permissions based on platform
      PermissionStatus permissionStatus;
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use photos permission
        debugPrint('Requesting Android photos permission...');
        permissionStatus = await Permission.photos.request();
        if (permissionStatus.isDenied) {
          // Fallback to storage permission for older Android versions
          debugPrint('Photos permission denied, trying storage permission...');
          permissionStatus = await Permission.storage.request();
        }
        if (permissionStatus.isDenied) {
          // Try media library as final fallback
          debugPrint('Storage permission denied, trying media library permission...');
          permissionStatus = await Permission.mediaLibrary.request();
        }
      } else {
        // For iOS, photos permission is typically handled automatically by image_picker
        debugPrint('Requesting iOS photos permission...');
        permissionStatus = await Permission.photos.request();
      }

      debugPrint('Permission status: $permissionStatus');
        if (!permissionStatus.isGranted && !permissionStatus.isLimited) {
        if (mounted) {
          // Check if permission was permanently denied
          if (permissionStatus.isPermanentlyDenied) {
            _showPermissionSettingsDialog();
          } else {
            _showErrorSnackBar('Gallery access required. Please check app permission settings.');
          }
        }
        return;
      }

      debugPrint('Opening image picker...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      debugPrint('Image selected: ${image?.path}');
      
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
          debugPrint('Scanning QR code from image...');
          // Scan QR code from the selected image
          final String? qrData = await QrCodeToolsPlugin.decodeFrom(image.path);
          
          debugPrint('QR scan result: $qrData');
          
          // Hide loading indicator
          if (mounted) {
            Navigator.of(context).pop();
            
            if (qrData != null && qrData.isNotEmpty) {
              // Successfully detected QR code
              debugPrint('QR code detected, calling onQRScanned');
              _onQRScanned(qrData);
            } else {
              _showErrorSnackBar('No QR code found in the selected image');
            }
          }
        } catch (e) {
          debugPrint('Error scanning QR code: $e');
          // Hide loading indicator
          if (mounted) {
            Navigator.of(context).pop();
            _showErrorSnackBar('Failed to scan QR code from image: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in gallery function: $e');
      if (mounted) {
        _showErrorSnackBar('Error during image selection: $e');
      }
    }  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Permissions Required',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gallery access has been permanently denied.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'To scan QR codes from images, you need to enable permissions in app settings.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );    },
    );
  }

  void _onFlashToggle() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
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
                    ),                    _buildBottomControls(),
                  ],
                ),                
                // NOTE: AttendanceForm overlay removed - now using direct attendance registration
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
        ),        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
            padding: const EdgeInsets.all(8),            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.2),
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
        borderRadius: BorderRadius.circular(20),        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
      padding: const EdgeInsets.all(32),      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
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
            textAlign: TextAlign.center,            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
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
                    debugPrint('Gallery button pressed'); // Debug log
                    _pickImageFromGallery();
                  },
                  color: const Color(0xFF4facfe),
                ),                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Reset',
                  onPressed: () {
                    debugPrint('Reset button pressed'); // Debug log
                    setState(() {
                      _scannedData = null;
                    });
                  },
                  color: const Color(0xFF667eea),
                ),
                _buildControlButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  label: 'Flash',
                  onPressed: () {
                    debugPrint('Flash button pressed'); // Debug log
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
                debugPrint('GestureDetector - Button $label tapped'); // Debug log
                // Add haptic feedback
                HapticFeedback.lightImpact();
                onPressed();
              },
              onTapDown: (_) {
                debugPrint('GestureDetector - Button $label pressed down');
              },
              onTapUp: (_) {
                debugPrint('GestureDetector - Button $label released');
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
                      debugPrint('InkWell - Button $label tapped'); // Debug log
                      // Add haptic feedback
                      HapticFeedback.lightImpact();
                      onPressed();
                    },
                    onTapDown: (_) {
                      debugPrint('InkWell - Button $label pressed down');
                    },
                    onTapUp: (_) {
                      debugPrint('InkWell - Button $label released');
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

// Validation Screen Widget
class _ValidationScreen extends StatefulWidget {
  final bool isSuccess;
  final VoidCallback onComplete;

  const _ValidationScreen({
    required this.isSuccess,
    required this.onComplete,
  });

  @override
  State<_ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<_ValidationScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Auto-close after 1.5 seconds
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSuccess ? Colors.green : Colors.red;
    final icon = widget.isSuccess ? Icons.check : Icons.close;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
        builder: (context, child) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 60,
                      color: backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

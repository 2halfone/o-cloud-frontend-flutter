import 'package:flutter/material.dart';
import '../services/admin_events_service.dart';
import '../models/admin_events.dart';

class AdminEventDetailScreen extends StatefulWidget {
  final AdminEvent event;

  const AdminEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<AdminEventDetailScreen> createState() => _AdminEventDetailScreenState();
}

class _AdminEventDetailScreenState extends State<AdminEventDetailScreen> {
  final AdminEventsService _eventsService = AdminEventsService();
  
  List<UserAttendanceDetail> _scannedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadScannedUsers();
  }
  Future<void> _loadScannedUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final response = await _eventsService.getEventUsers(
        widget.event.eventId,
        statusFilter: _statusFilter,
        page: 1,
        limit: 1000,
      );
      
      // Filtra solo gli utenti che hanno scannerizzato (presente o assente)
      final scannedUsers = response.users.where((user) => 
        user.status == 'present' || user.status == 'absent'
      ).toList();
      
      if (mounted) {
        setState(() {
          _scannedUsers = scannedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEvent() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete Event',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this event?',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event: ${widget.event.eventName}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Date: ${widget.event.date}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    'Total Scanned Users: ${_scannedUsers.length}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. All attendance data for this event will be permanently deleted.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );    if (confirmed == true) {
      try {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Delete the event
        await _eventsService.deleteEvent(widget.event.eventId);
        
        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Event "${widget.event.eventName}" deleted successfully'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate back to events monitor
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Failed to delete event: $e'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.event.eventName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScannedUsers,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_scannedUsers.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatusFilter(),
        _buildStats(),
        Expanded(
          child: _buildUsersList(),
        ),
      ],
    );
  }
  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterButton('All', null),
          const SizedBox(width: 8),
          _buildFilterButton('Present', 'present'),
          const SizedBox(width: 8),
          _buildFilterButton('Absent', 'absent'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String? status) {
    final isSelected = _statusFilter == status;
    
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _statusFilter = status;
          });
          _loadScannedUsers();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildStats() {
    final presentCount = _scannedUsers.where((u) => u.status == 'present').length;
    final absentCount = _scannedUsers.where((u) => u.status == 'absent').length;
    final totalScanned = _scannedUsers.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
          Expanded(
            child: _buildStatItem(
              'Total Scans',
              totalScanned.toString(),
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Present',
              presentCount.toString(),
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Absent',
              absentCount.toString(),
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    final filteredUsers = _statusFilter == null 
        ? _scannedUsers 
        : _scannedUsers.where((u) => u.status == _statusFilter).toList();

    return Container(
      margin: const EdgeInsets.all(16),      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: filteredUsers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(UserAttendanceDetail user) {
    final isPresent = user.status == 'present';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isPresent ? Colors.green : Colors.red,
        child: Icon(
          isPresent ? Icons.check : Icons.close,
          color: Colors.white,
        ),
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),      subtitle: user.timestamp != null
          ? Text(
              'Scanned: ${user.displayTimestamp}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isPresent ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isPresent ? 'PRESENT' : 'ABSENT',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),            const SizedBox(height: 16),
            const Text(
              'Loading Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadScannedUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: Colors.grey[400],
            ),            const SizedBox(height: 16),
            const Text(
              'No Scans Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No participants have scanned the QR code for this event yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadScannedUsers,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

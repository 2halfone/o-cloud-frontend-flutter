import 'package:flutter/material.dart';
import '../services/admin_events_service.dart';
import '../models/admin_events.dart';

class StatusManagementWidget extends StatefulWidget {
  final UserAttendanceDetail user;
  final AdminEvent event;
  final Function(UserAttendanceDetail, String) onStatusUpdate;
  final bool showConfirmationDialog;
  final bool enableRealTimeUpdates;

  const StatusManagementWidget({
    super.key,
    required this.user,
    required this.event,
    required this.onStatusUpdate,
    this.showConfirmationDialog = true,
    this.enableRealTimeUpdates = true,
  });

  @override
  State<StatusManagementWidget> createState() => _StatusManagementWidgetState();
}

class _StatusManagementWidgetState extends State<StatusManagementWidget>
    with TickerProviderStateMixin {
  final AdminEventsService _eventsService = AdminEventsService();
  bool _isUpdating = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableRealTimeUpdates) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showStatusSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatusSelectionDialog(
        currentStatus: widget.user.status,
        eventsService: _eventsService,
        onStatusSelected: (status) => _handleStatusChange(status),
        showConfirmation: widget.showConfirmationDialog,
      ),
    );
  }

  void _handleStatusChange(String newStatus) {
    if (widget.showConfirmationDialog) {
      _showConfirmationDialog(newStatus);
    } else {
      _updateStatus(newStatus);
    }
  }

  void _showConfirmationDialog(String newStatus) {
    showDialog(
      context: context,
      builder: (context) => StatusChangeConfirmationDialog(
        user: widget.user,
        currentStatus: widget.user.status,
        newStatus: newStatus,
        eventsService: _eventsService,
        onConfirm: () => _updateStatus(newStatus),
      ),
    );
  }

  void _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.onStatusUpdate(widget.user, newStatus);
      
      if (widget.enableRealTimeUpdates) {
        _pulseController.reset();
        _pulseController.forward();
      }
    } catch (e) {
      if (mounted) {        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableRealTimeUpdates ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _isUpdating ? null : _showStatusSelectionDialog,
            child: Container(              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _eventsService.getStatusColor(widget.user.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _eventsService.getStatusColor(widget.user.status),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _eventsService.getStatusColor(widget.user.status).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUpdating) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _eventsService.getStatusColor(widget.user.status),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      _eventsService.getStatusEmoji(widget.user.status),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _eventsService.getStatusIcon(widget.user.status),
                      size: 16,
                      color: _eventsService.getStatusColor(widget.user.status),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    _eventsService.getStatusLabelWithoutEmoji(widget.user.status),
                    style: TextStyle(
                      color: _eventsService.getStatusColor(widget.user.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isUpdating) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: _eventsService.getStatusColor(widget.user.status),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatusSelectionDialog extends StatelessWidget {
  final String currentStatus;
  final AdminEventsService eventsService;
  final Function(String) onStatusSelected;
  final bool showConfirmation;

  const StatusSelectionDialog({
    super.key,
    required this.currentStatus,
    required this.eventsService,
    required this.onStatusSelected,
    this.showConfirmation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  color: Color(0xFF38ef7d),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose a status for this user:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...eventsService.getAvailableStatuses().map((status) {
              final isSelected = status == currentStatus;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).pop();
                      onStatusSelected(status);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),                      decoration: BoxDecoration(
                        color: isSelected
                            ? eventsService.getStatusColor(status).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? eventsService.getStatusColor(status)
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            eventsService.getStatusEmoji(status),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            eventsService.getStatusIcon(status),
                            color: eventsService.getStatusColor(status),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventsService.getStatusLabelWithoutEmoji(status),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  eventsService.getStatusDescription(status),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.check_circle,
                              color: eventsService.getStatusColor(status),
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class StatusChangeConfirmationDialog extends StatefulWidget {
  final UserAttendanceDetail user;
  final String currentStatus;
  final String newStatus;
  final AdminEventsService eventsService;
  final VoidCallback onConfirm;

  const StatusChangeConfirmationDialog({
    super.key,
    required this.user,
    required this.currentStatus,
    required this.newStatus,
    required this.eventsService,
    required this.onConfirm,
  });

  @override
  State<StatusChangeConfirmationDialog> createState() =>
      _StatusChangeConfirmationDialogState();
}

class _StatusChangeConfirmationDialogState
    extends State<StatusChangeConfirmationDialog> {
  final TextEditingController _motivationController = TextEditingController();
  bool _includeMotivation = false;

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Confirm Status Change',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${widget.user.fullName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'From: ${widget.eventsService.getStatusEmoji(widget.currentStatus)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.eventsService.getStatusLabelWithoutEmoji(widget.currentStatus),
                        style: TextStyle(
                          color: widget.eventsService.getStatusColor(widget.currentStatus),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'To: ${widget.eventsService.getStatusEmoji(widget.newStatus)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.eventsService.getStatusLabelWithoutEmoji(widget.newStatus),
                        style: TextStyle(
                          color: widget.eventsService.getStatusColor(widget.newStatus),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _includeMotivation,
                  onChanged: (value) {
                    setState(() {
                      _includeMotivation = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF38ef7d),
                ),
                const Text(
                  'Add reason/note',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            if (_includeMotivation) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _motivationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter reason for status change...',
                  hintStyle: const TextStyle(color: Colors.white60),                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF38ef7d)),
                  ),
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.eventsService.getStatusColor(widget.newStatus),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BulkStatusManagementWidget extends StatefulWidget {
  final List<UserAttendanceDetail> selectedUsers;
  final AdminEvent event;
  final Function(List<UserAttendanceDetail>, String) onBulkStatusUpdate;
  final VoidCallback onCancel;

  const BulkStatusManagementWidget({
    super.key,
    required this.selectedUsers,
    required this.event,
    required this.onBulkStatusUpdate,
    required this.onCancel,
  });

  @override
  State<BulkStatusManagementWidget> createState() =>
      _BulkStatusManagementWidgetState();
}

class _BulkStatusManagementWidgetState extends State<BulkStatusManagementWidget>
    with TickerProviderStateMixin {
  final AdminEventsService _eventsService = AdminEventsService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _showBulkStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.group_work,
                    color: Color(0xFF38ef7d),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Bulk Status Update',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Update ${widget.selectedUsers.length} selected users to:',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ..._eventsService.getAvailableStatuses().map((status) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onBulkStatusUpdate(widget.selectedUsers, status);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _eventsService.getStatusEmoji(status),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _eventsService.getStatusIcon(status),
                              color: _eventsService.getStatusColor(status),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _eventsService.getStatusLabelWithoutEmoji(status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(            colors: [
              const Color(0xFF38ef7d).withValues(alpha: 0.1),
              const Color(0xFF11998e).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38ef7d)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF38ef7d),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.selectedUsers.length} user${widget.selectedUsers.length > 1 ? 's' : ''} selected',
                style: const TextStyle(
                  color: Color(0xFF38ef7d),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: _showBulkStatusDialog,
              child: const Text(
                'Update Status',
                style: TextStyle(color: Color(0xFF38ef7d)),
              ),
            ),
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/auth_log.dart';
import '../services/log_service.dart';
import '../widgets/admin_logs/admin_logs_header.dart';
import '../widgets/admin_logs/log_card.dart';
import '../widgets/admin_logs/log_details_modal.dart';
import '../widgets/admin_logs/admin_logs_states.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  _AdminLogsScreenState createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> 
    with TickerProviderStateMixin {
  final LogService _logService = LogService();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<AuthLog> _logs = [];
  AuthLogStats? _stats;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    
    // Inizializza animazioni
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
    
    _loadLogs();
    _scrollController.addListener(_onScroll);
    
    // Avvia animazioni
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLogs() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _logService.getAuthLogs(
        page: 1,
        limit: _pageSize,
      );
      
      if (response != null && mounted) {
        setState(() {
          _logs = response.logs;
          _stats = response.stats;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore || _stats == null || _currentPage >= _stats!.pagesTotal) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _logService.getAuthLogs(
        page: nextPage,
        limit: _pageSize,
      );
      
      if (response != null && mounted) {
        setState(() {
          _logs.addAll(response.logs);
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        _showErrorSnackBar('Error loading more logs: $e');
      }
    }
  }

  Future<void> _refreshLogs() async {
    await _loadLogs();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadLogs,
        ),
      ),
    );
  }

  void _showLogDetails(AuthLog log) {
    LogDetailsModal.show(context, log);
  }

  @override  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Sfondo molto scuro
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F0F),
              const Color(0xFF1a1a1a),
              const Color(0xFF000000),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF333333),
            width: 2,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  AdminLogsHeader(
                    stats: _stats,
                    isLoading: _isLoading,
                    onBack: () => Navigator.pop(context),
                    onRefresh: () => _refreshLogs(),
                  ),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _logs.isEmpty) {
      return AdminLogsStates.buildLoadingState();
    }

    if (_error != null && _logs.isEmpty) {
      return AdminLogsStates.buildErrorState(_error!, _loadLogs);
    }

    return RefreshIndicator(
      onRefresh: _refreshLogs,
      child: Column(
        children: [
          // Lista dei log
          Expanded(
            child: _logs.isEmpty
                ? AdminLogsStates.buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _logs.length) {
                        return _buildLoadingMoreIndicator();
                      }
                      return LogCard(
                        log: _logs[index],
                        index: index,
                        onTap: () => _showLogDetails(_logs[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Loading more logs...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

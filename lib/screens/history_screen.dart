import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/custom_widgets.dart';
import '../models/scan_result.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _scanHistory = [];
  List<ScanResult> _filteredHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await DatabaseService.getAllScanResults();
      setState(() {
        _scanHistory = history;
        _applyFilter(_selectedFilter);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredHistory = List.from(_scanHistory);
      } else {
        _filteredHistory = _scanHistory.where((result) {
          switch (filter) {
            case 'Safe':
              return result.isSafe;
            case 'Suspicious':
              return result.isSuspicious;
            case 'Phishing':
              return result.isPhishing;
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Clear History',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to clear all scan history?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.clearAllHistory();
        await _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('History cleared successfully'),
              backgroundColor: AppTheme.safeGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear history: ${e.toString()}'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Map<String, int> _getStatistics() {
    final stats = <String, int>{
      'All': _scanHistory.length,
      'Safe': 0,
      'Suspicious': 0,
      'Phishing': 0,
    };
    
    for (final result in _scanHistory) {
      if (result.isSafe) stats['Safe'] = (stats['Safe'] ?? 0) + 1;
      if (result.isSuspicious) stats['Suspicious'] = (stats['Suspicious'] ?? 0) + 1;
      if (result.isPhishing) stats['Phishing'] = (stats['Phishing'] ?? 0) + 1;
    }
    
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStatistics();
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text('Scan History'),
        actions: [
          if (_scanHistory.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: Icon(
                Icons.delete_outline,
                color: AppTheme.dangerRed,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: ModernLoadingIndicator(message: 'Loading history...'),
            )
          : _scanHistory.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.history,
                  title: 'No Scan History',
                  subtitle: 'Start scanning QR codes to build your security history',
                  buttonText: 'Start Scanning',
                  onButtonPressed: () {
                    Navigator.pushReplacementNamed(context, '/scan');
                  },
                )
              : Column(
                  children: [
                    // Filter Chips
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: ['All', 'Safe', 'Suspicious', 'Phishing'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          final count = stats[filter] ?? 0;
                          final color = filter == 'Safe' 
                              ? AppTheme.safeGreen
                              : filter == 'Phishing'
                                  ? AppTheme.dangerRed
                                  : filter == 'Suspicious'
                                      ? AppTheme.warningOrange
                                      : AppTheme.primaryCyan;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('$filter ($count)'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) _applyFilter(filter);
                              },
                              backgroundColor: AppTheme.cardBackground,
                              selectedColor: color.withOpacity(0.2),
                              checkmarkColor: color,
                              labelStyle: TextStyle(
                                color: isSelected ? color : AppTheme.textPrimary,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSelected ? color : AppTheme.borderColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    // History List
                    Expanded(
                      child: _filteredHistory.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.filter_list,
                              title: 'No $_selectedFilter Results',
                              subtitle: 'Try changing the filter or scan more URLs',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadHistory,
                              color: AppTheme.primaryCyan,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredHistory.length,
                                itemBuilder: (context, index) {
                                  final result = _filteredHistory[index];
                                  return _buildHistoryItem(result);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHistoryItem(ScanResult result) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/result',
            arguments: result,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.getStatusColor(result.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          status: result.status,
                          fontSize: 10,
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(result.timestamp),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.url,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Risk: ${result.score}',
                          style: TextStyle(
                            color: AppTheme.getRiskScoreColor(result.score),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Confidence: ${(result.confidence * 100).toInt()}%',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

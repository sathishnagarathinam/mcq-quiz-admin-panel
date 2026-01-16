import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/admin_layout.dart';

class BannerManagementPage extends StatefulWidget {
  const BannerManagementPage({super.key});

  @override
  State<BannerManagementPage> createState() => _BannerManagementPageState();
}

class _BannerManagementPageState extends State<BannerManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Banner Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Promotional Banners',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showBannerDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Banner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Banners List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('banners')
                  .orderBy('priority', descending: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final banners = snapshot.data?.docs ?? [];

                if (banners.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No banners created yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first promotional banner to display in the mobile app',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: banners.length,
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    final data = banner.data() as Map<String, dynamic>;

                    return _buildBannerCard(banner.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(String bannerId, Map<String, dynamic> data) {
    final isActive = data['isActive'] ?? false;
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final now = DateTime.now();

    final isCurrentlyActive =
        isActive &&
        (startDate?.isBefore(now) ?? false) &&
        (endDate?.isAfter(now) ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data['title'] ?? 'Untitled Banner',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentlyActive
                                  ? Colors.green
                                  : isActive
                                  ? Colors.orange
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCurrentlyActive
                                  ? 'LIVE'
                                  : isActive
                                  ? 'SCHEDULED'
                                  : 'INACTIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['subtitle'] ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (data['couponCode']?.isNotEmpty == true) ...[
                            Chip(
                              label: Text('Code: ${data['couponCode']}'),
                              backgroundColor: Colors.blue[50],
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (data['discount']?.isNotEmpty == true)
                            Chip(
                              label: Text('${data['discount']} OFF'),
                              backgroundColor: Colors.green[50],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _showBannerDialog(bannerId: bannerId, data: data),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Banner',
                        ),
                        IconButton(
                          onPressed: () =>
                              _toggleBannerStatus(bannerId, !isActive),
                          icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                          tooltip: isActive ? 'Deactivate' : 'Activate',
                        ),
                        IconButton(
                          onPressed: () => _deleteBanner(bannerId),
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          tooltip: 'Delete Banner',
                        ),
                      ],
                    ),
                    Text(
                      'Priority: ${data['priority'] ?? 0}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            if (startDate != null || endDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Active: ${startDate != null ? DateFormat('MMM dd, yyyy').format(startDate) : 'N/A'} - ${endDate != null ? DateFormat('MMM dd, yyyy').format(endDate) : 'N/A'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBannerDialog({String? bannerId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(
        bannerId: bannerId,
        initialData: data,
        onSave: () {
          setState(() {}); // Refresh the list
        },
      ),
    );
  }

  Future<void> _toggleBannerStatus(String bannerId, bool isActive) async {
    try {
      await _firestore.collection('banners').doc(bannerId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Banner ${isActive ? 'activated' : 'deactivated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating banner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text(
          'Are you sure you want to delete this banner? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('banners').doc(bannerId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class BannerFormDialog extends StatefulWidget {
  final String? bannerId;
  final Map<String, dynamic>? initialData;
  final VoidCallback onSave;

  const BannerFormDialog({
    super.key,
    this.bannerId,
    this.initialData,
    required this.onSave,
  });

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _couponCodeController = TextEditingController();
  final _discountController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _priorityController = TextEditingController();

  String _primaryColor = '#E91E63';
  String _secondaryColor = '#9C27B0';
  String _selectedIcon = 'lightbulb';
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  // Exam selection
  String? _selectedExamId;
  String? _selectedExamName;
  List<Map<String, dynamic>> _availableExams = [];
  bool _loadingExams = false;

  final List<String> _iconOptions = [
    'lightbulb',
    'star',
    'gift',
    'discount',
    'sale',
    'percent',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _populateFields();
    }
    _loadExams();
  }

  void _populateFields() {
    final data = widget.initialData!;
    _titleController.text = data['title'] ?? '';
    _subtitleController.text = data['subtitle'] ?? '';
    _couponCodeController.text = data['couponCode'] ?? '';
    _discountController.text = data['discount'] ?? '';
    _targetUrlController.text = data['targetUrl'] ?? '';
    _priorityController.text = (data['priority'] ?? 0).toString();
    _primaryColor = data['primaryColor'] ?? '#E91E63';
    _secondaryColor = data['secondaryColor'] ?? '#9C27B0';
    _selectedIcon = data['iconName'] ?? 'lightbulb';
    _isActive = data['isActive'] ?? true;
    _startDate = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _endDate =
        (data['endDate'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 30));
    _selectedExamId = data['examId'];
    _selectedExamName = data['examName'];
  }

  Future<void> _loadExams() async {
    setState(() {
      _loadingExams = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('exams')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final exams = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'examType': data['examType'] ?? '',
        };
      }).toList();

      setState(() {
        _availableExams = exams;
        _loadingExams = false;
      });
    } catch (e) {
      print('Error loading exams: $e');
      setState(() {
        _loadingExams = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bannerId == null ? 'Create Banner' : 'Edit Banner',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title and Subtitle
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Subtitle is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Coupon and Discount
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _couponCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Coupon Code',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              decoration: const InputDecoration(
                                labelText: 'Discount (e.g., 30%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target URL and Priority
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _targetUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Target URL (optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _priorityController,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Exam Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Link to Exam (optional)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          _loadingExams
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: _selectedExamId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Exam',
                                    border: OutlineInputBorder(),
                                    hintText:
                                        'Choose an exam to link to this banner',
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('No exam selected'),
                                    ),
                                    ..._availableExams.map((exam) {
                                      return DropdownMenuItem<String>(
                                        value: exam['id'],
                                        child: Text(
                                          '${exam['name']} (${exam['examType']})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedExamId = value;
                                      if (value != null) {
                                        final selectedExam = _availableExams
                                            .firstWhere(
                                              (exam) => exam['id'] == value,
                                            );
                                        _selectedExamName =
                                            selectedExam['name'];
                                      } else {
                                        _selectedExamName = null;
                                      }
                                    });
                                  },
                                ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Colors and Icon
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Primary Color'),
                                const SizedBox(height: 8),
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        _primaryColor.replaceFirst('#', '0xFF'),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: TextButton(
                                    onPressed: () => _showColorPicker(true),
                                    child: Text(
                                      _primaryColor,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Secondary Color'),
                                const SizedBox(height: 8),
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        _secondaryColor.replaceFirst(
                                          '#',
                                          '0xFF',
                                        ),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: TextButton(
                                    onPressed: () => _showColorPicker(false),
                                    child: Text(
                                      _secondaryColor,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Icon'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedIcon,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _iconOptions.map((icon) {
                                    return DropdownMenuItem(
                                      value: icon,
                                      child: Text(icon),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedIcon = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Date'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_startDate),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('End Date'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_endDate),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active Toggle
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text(
                          'Banner will be displayed in the app when active and within date range',
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveBanner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.bannerId == null ? 'Create' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(bool isPrimary) {
    // Simple color picker - you can implement a more sophisticated one
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select ${isPrimary ? 'Primary' : 'Secondary'} Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              [
                '#E91E63',
                '#9C27B0',
                '#673AB7',
                '#3F51B5',
                '#2196F3',
                '#00BCD4',
                '#009688',
                '#4CAF50',
                '#8BC34A',
                '#CDDC39',
                '#FFEB3B',
                '#FFC107',
                '#FF9800',
                '#FF5722',
                '#795548',
              ].map((color) {
                return ListTile(
                  leading: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(color),
                  onTap: () {
                    setState(() {
                      if (isPrimary) {
                        _primaryColor = color;
                      } else {
                        _secondaryColor = color;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'couponCode': _couponCodeController.text.trim(),
        'discount': _discountController.text.trim(),
        'primaryColor': _primaryColor,
        'secondaryColor': _secondaryColor,
        'iconName': _selectedIcon,
        'isActive': _isActive,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'targetUrl': _targetUrlController.text.trim(),
        'examId': _selectedExamId,
        'examName': _selectedExamName,
        'priority': int.tryParse(_priorityController.text) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.bannerId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['createdBy'] = 'admin'; // TODO: Get actual admin user
        await FirebaseFirestore.instance.collection('banners').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(widget.bannerId)
            .update(data);
      }

      widget.onSave();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Banner ${widget.bannerId == null ? 'created' : 'updated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving banner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _couponCodeController.dispose();
    _discountController.dispose();
    _targetUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
  }
}

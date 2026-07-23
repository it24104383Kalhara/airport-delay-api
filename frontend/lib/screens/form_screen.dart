// ============================================================
//  form_screen.dart
//  Add / Edit form for a FlightDelayAlert.
//  Validation rules:
//    - All fields required
//    - new_departure must be strictly after original_departure
//  On submit: times are converted to UTC before serialization.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';

class FormScreen extends StatefulWidget {
  /// Pass an existing alert to pre-fill fields for editing.
  /// Leave null for the "create" flow.
  final FlightDelayAlert? existingAlert;

  const FormScreen({super.key, this.existingAlert});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormatter = DateFormat('dd MMM yyyy  HH:mm');

  // ── Controllers ───────────────────────────────────────────
  late final TextEditingController _flightNumberCtrl;
  late final TextEditingController _airlineCtrl;
  late final TextEditingController _destinationCtrl;
  late final TextEditingController _terminalCtrl;
  late final TextEditingController _reasonCtrl;

  // ── Dropdown state ────────────────────────────────────────
  late SeverityLevel _severity;
  late AlertStatus _status;

  // ── DateTime state (stored as local time for display) ─────
  DateTime? _originalDep;
  DateTime? _newDep;

  bool get _isEditing => widget.existingAlert != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAlert;
    _flightNumberCtrl = TextEditingController(text: a?.flightNumber ?? '');
    _airlineCtrl = TextEditingController(text: a?.airline ?? '');
    _destinationCtrl = TextEditingController(text: a?.destination ?? '');
    _terminalCtrl = TextEditingController(text: a?.terminalZone ?? '');
    _reasonCtrl = TextEditingController(text: a?.delayReason ?? '');
    _severity = a?.severityLevel ?? SeverityLevel.moderate;
    _status = a?.status ?? AlertStatus.active;
    // Convert stored UTC to local for the date picker
    _originalDep = a?.originalDeparture.toLocal();
    _newDep = a?.newDeparture.toLocal();
  }

  @override
  void dispose() {
    _flightNumberCtrl.dispose();
    _airlineCtrl.dispose();
    _destinationCtrl.dispose();
    _terminalCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  // ─── Date / Time picker ─────────────────────────────────
  Future<void> _pickDateTime({required bool isOriginal}) async {
    final now = DateTime.now();
    final initial = (isOriginal ? _originalDep : _newDep) ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isOriginal) {
        _originalDep = combined;
      } else {
        _newDep = combined;
      }
    });
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
      ),
      child: child!,
    );
  }

  // ─── Submit ─────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Date validations
    if (_originalDep == null) {
      _showError('Please select the original departure time.');
      return;
    }
    if (_newDep == null) {
      _showError('Please select the new departure time.');
      return;
    }
    // Business rule: new must be after original
    if (!_newDep!.isAfter(_originalDep!)) {
      _showError(
        'New departure must be chronologically after the original departure.',
      );
      return;
    }

    final provider = context.read<AlertProvider>();

    // Build the alert — convert local DateTime → UTC for API payload
    final alert = FlightDelayAlert(
      id: widget.existingAlert?.id,
      flightNumber: _flightNumberCtrl.text.trim().toUpperCase(),
      airline: _airlineCtrl.text.trim(),
      destination: _destinationCtrl.text.trim(),
      terminalZone: _terminalCtrl.text.trim(),
      originalDeparture: _originalDep!.toUtc(),
      newDeparture: _newDep!.toUtc(),
      delayReason: _reasonCtrl.text.trim(),
      severityLevel: _severity,
      status: _status,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateAlert(widget.existingAlert!.id!, alert);
    } else {
      success = await provider.createAlert(alert);
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true); // signal caller to refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Alert updated successfully ✓'
                : 'New delay alert logged ✓',
          ),
        ),
      );
    } else {
      _showError(provider.errorMessage ?? 'Something went wrong.');
      provider.clearError();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.critical,
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AlertProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alert' : 'Log New Delay'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _sectionHeader('Flight Information'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _flightNumberCtrl,
                  label: 'Flight Number',
                  hint: 'e.g. SQ322',
                  icon: Icons.flight_rounded,
                  caps: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _airlineCtrl,
                  label: 'Airline',
                  hint: 'e.g. Singapore Airlines',
                  icon: Icons.business_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _destinationCtrl,
                  label: 'Destination',
                  hint: 'e.g. London Heathrow (LHR)',
                  icon: Icons.location_on_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _terminalCtrl,
                  label: 'Terminal / Zone',
                  hint: 'e.g. Terminal 3',
                  icon: Icons.domain_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                _sectionHeader('Departure Times (Local)'),
                const SizedBox(height: 12),
                _DateTimePickerTile(
                  label: 'Original Departure',
                  value: _originalDep != null
                      ? _dateFormatter.format(_originalDep!)
                      : null,
                  onTap: () => _pickDateTime(isOriginal: true),
                ),
                const SizedBox(height: 14),
                _DateTimePickerTile(
                  label: 'New Departure',
                  value: _newDep != null
                      ? _dateFormatter.format(_newDep!)
                      : null,
                  onTap: () => _pickDateTime(isOriginal: false),
                  isHighlighted: true,
                ),
                if (_originalDep != null &&
                    _newDep != null &&
                    !_newDep!.isAfter(_originalDep!))
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'New departure must be after original departure.',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.critical,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                _sectionHeader('Delay Details'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _reasonCtrl,
                  label: 'Delay Reason',
                  hint: 'e.g. Technical inspection on engine #2',
                  icon: Icons.info_outline_rounded,
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _buildDropdown<SeverityLevel>(
                  label: 'Severity Level',
                  value: _severity,
                  icon: Icons.warning_amber_rounded,
                  items: SeverityLevel.values,
                  itemLabel: (s) => s.label,
                  onChanged: (v) => setState(() => _severity = v!),
                ),
                const SizedBox(height: 14),
                _buildDropdown<AlertStatus>(
                  label: 'Status',
                  value: _status,
                  icon: Icons.toggle_on_rounded,
                  items: AlertStatus.values,
                  itemLabel: (s) => s.label,
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // ── Fixed bottom submit button ──────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Log Delay Alert',
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper builders ────────────────────────────────────
  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization caps = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: caps,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
      borderRadius: AppShapes.cardBorderRadius,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                itemLabel(item),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Date-time tile (not a form field, acts like a button) ───
class _DateTimePickerTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _DateTimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isHighlighted && hasValue
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.inputFill,
          borderRadius: AppShapes.inputBorderRadius,
          border: Border.all(
            color: isHighlighted && hasValue
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: isHighlighted && hasValue
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    hasValue ? value! : 'Tap to select date & time',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: hasValue
                          ? (isHighlighted
                              ? AppColors.primary
                              : AppColors.textPrimary)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

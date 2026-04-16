import 'package:flutter/material.dart';
import '../services/organization_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String organizacionId;
  final List<String> usuarios;

  const CreateTaskScreen({
    super.key,
    required this.organizacionId,
    required this.usuarios,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OrganizationService _organizationService = OrganizationService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Selecciona fecha de inicio',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _startDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _startDateController.text = _formatDate(_startDate!);

      // If start date moves forward, clear end date if it becomes invalid.
      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = null;
        _endDateController.clear();
      }
    });

    _formKey.currentState?.validate();
  }

  Future<void> _pickEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _endDate ?? _startDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate ?? DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Selecciona fecha de fin',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _endDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _endDateController.text = _formatDate(_endDate!);
    });

    _formKey.currentState?.validate();
  }

  DateTime _normalizeStartDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 8, 0, 0);
  }

  DateTime _normalizeEndDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 17, 0, 0);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _organizationService.createTaskByOrganization(
        organizacionId: widget.organizacionId,
        titulo: _titleController.text.trim(),
        fechaInicio: _normalizeStartDate(_startDate!),
        fechaFin: _normalizeEndDate(_endDate!),
        usuarios: widget.usuarios,
      );

      print('Formulario válido. Datos listos para la Fase 4');

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear la tarea: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Tarea'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration(
                            label: 'Título',
                            hint: 'Escribe el título de la tarea',
                            icon: Icons.title,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El título es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          onTap: _pickStartDate,
                          decoration: _buildInputDecoration(
                            label: 'Fecha de inicio',
                            hint: 'Selecciona una fecha',
                            icon: Icons.event,
                          ).copyWith(
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          validator: (String? value) {
                            if (_startDate == null) {
                              return 'La fecha de inicio es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _endDateController,
                          readOnly: true,
                          onTap: _pickEndDate,
                          decoration: _buildInputDecoration(
                            label: 'Fecha de fin',
                            hint: 'Selecciona una fecha',
                            icon: Icons.event_available,
                          ).copyWith(
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          validator: (String? value) {
                            if (_endDate == null) {
                              return 'La fecha de fin es obligatoria';
                            }
                            if (_startDate != null &&
                                _endDate!.isBefore(_startDate!)) {
                              return 'La fecha de fin no puede ser anterior a la fecha de inicio';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
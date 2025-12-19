import 'dart:io';

import 'package:connecthub_app/core/api/api_client.dart';
import 'package:connecthub_app/core/enums/app_enums.dart';
import 'package:connecthub_app/core/theme/app_theme.dart';
import 'package:connecthub_app/core/widgets/custom_text_field.dart';
import 'package:connecthub_app/core/widgets/primary_button.dart';
import 'package:connecthub_app/features/events/presentation/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class EventEditScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> event;

  const EventEditScreen({super.key, required this.event});

  @override
  ConsumerState<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends ConsumerState<EventEditScreen> {
  late final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.event['title'] ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.event['description'] ?? '');
  late final _locationController =
      TextEditingController(text: widget.event['venue'] ?? '');
  late final _prizeController =
      TextEditingController(text: widget.event['prize'].toString() ?? '0');

  late EventCategory _selectedType =
      _parseEventCategory(widget.event['category']);
  late int _maxUsers = widget.event['maxUsersCount'] ?? 50;
  late DateTime? _startDate = _parseDateTime(widget.event['startDate']);
  late DateTime? _endDate = _parseDateTime(widget.event['endDate']);
  late TimeOfDay? _startTime = _parseTime(widget.event['startDate']);
  late TimeOfDay? _endTime = _parseTime(widget.event['endDate']);

  late final List<Map<String, dynamic>> _existingTags =
      List<Map<String, dynamic>>.from(widget.event['tags'] ?? []);
  final List<String> _newTags = [];
  final List<int> _tagsToDelete = [];
  final TextEditingController _tagController = TextEditingController();

  final TextEditingController _customMaxUsersController =
      TextEditingController();
  final List<int> _maxUsersPresets = [10, 50, 100, 200];
  final List<EventCategory> _eventTypes = EventCategory.values;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _showCustomField = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.event['imageUrl'];
    _customMaxUsersController.text = _maxUsers.toString();
  }

  EventCategory _parseEventCategory(dynamic category) {
    if (category == null) return EventCategory.HACKATHON;
    try {
      return EventCategory.values.firstWhere(
        (e) => e.value == category.toString(),
        orElse: () => EventCategory.HACKATHON,
      );
    } catch (e) {
      return EventCategory.HACKATHON;
    }
  }

  DateTime? _parseDateTime(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.tryParse(dateString.toString());
    } catch (e) {
      return null;
    }
  }

  TimeOfDay? _parseTime(dynamic dateString) {
    if (dateString == null) return null;
    try {
      final date = DateTime.tryParse(dateString.toString());
      if (date != null) {
        return TimeOfDay(hour: date.hour, minute: date.minute);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _prizeController.dispose();
    _tagController.dispose();
    _customMaxUsersController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.electricBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      await _selectTime(isStart);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.electricBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addTag() {
    final tagText = _tagController.text.trim();
    if (tagText.isNotEmpty) {
      final tagExists = _existingTags.any((tag) => tag['name'] == tagText) ||
          _newTags.contains(tagText);
      if (!tagExists) {
        setState(() {
          _newTags.add(tagText);
          _tagController.clear();
        });
      }
    }
  }

  void _removeExistingTag(int index) {
    final tag = _existingTags[index];
    if (tag['id'] != null) {
      _tagsToDelete.add(tag['id']);
    }
    setState(() {
      _existingTags.removeAt(index);
    });
  }

  void _removeNewTag(int index) {
    setState(() {
      _newTags.removeAt(index);
    });
  }

  String _formatDateTime(DateTime? d, TimeOfDay? t) {
    if (d == null) return 'Выберите дату';
    final dateStr = DateFormat('dd.MM.yyyy').format(d);
    final timeStr = t?.format(context) ?? '--:--';
    return '$dateStr $timeStr';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _currentImageUrl = null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
    });
  }

  void _updateEvent() {
    if (_formKey.currentState!.validate()) {
      if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите название события')),
        );
        return;
      }

      if (_descriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите описание события')),
        );
        return;
      }

      if (_startDate == null ||
          _endDate == null ||
          _startTime == null ||
          _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Укажите даты начала и окончания')),
        );
        return;
      }

      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Дата окончания не может быть раньше даты начала')),
        );
        return;
      }

      if (_showCustomField) {
        try {
          final customValue = int.parse(_customMaxUsersController.text);
          if (customValue > 0) {
            _maxUsers = customValue;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Количество участников должно быть больше 0')),
            );
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Введите корректное число участников')),
          );
          return;
        }
      }

      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _selectedType.value,
        'venue': _locationController.text,
        'maxUsersCount': _maxUsers,
        'startDate': startDateTime.toIso8601String(),
        'endDate': endDateTime.toIso8601String(),
        'prize': _getPrizeValue(),
        'tags': _newTags,
        'tagsToDelete': _tagsToDelete,
        if (_selectedImage != null) 'imageFile': _selectedImage,
        if (_currentImageUrl == null && _selectedImage == null)
          'removeImage': true,
      };

      ref
          .read(eventsProvider.notifier)
          .updateEvent(eventData, widget.event['id'])
          .then((updatedEvent) {
        context.pop(updatedEvent);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Мероприятие обновлено!'),
            backgroundColor: AppColors.success,
          ),
        );
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Редактировать событие',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                        image: _getImageDecoration(),
                      ),
                      child: _selectedImage == null && _currentImageUrl == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Ionicons.camera_outline,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Добавить фото события',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  if (_selectedImage != null || _currentImageUrl != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Ionicons.close_circle,
                            size: 30,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _titleController,
                label: 'Название *',
                placeholder: 'Например, Хакатон 2024',
                validator: (v) =>
                    v?.isEmpty == true ? 'Введите название' : null,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание *',
                placeholder: 'Расскажите о мероприятии...',
                maxLines: 4,
                validator: (v) =>
                    v?.isEmpty == true ? 'Введите описание' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Тип события *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _eventTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final type = _eventTypes[index];
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type.value),
                      selected: isSelected,
                      selectedColor: AppColors.electricBlue,
                      backgroundColor: AppColors.backgroundSecondary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Начало *',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Ionicons.calendar_outline,
                                  size: 18,
                                  color: AppColors.electricBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(_startDate, _startTime),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
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
                        const Text(
                          'Окончание *',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Ionicons.time_outline,
                                  size: 18,
                                  color: AppColors.neonPink,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(_endDate, _endTime),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _locationController,
                label: 'Место проведения',
                prefixIcon: Ionicons.location_outline,
                placeholder: 'Например, Онлайн или Москва, ул. Пушкина 1',
              ),
              const SizedBox(height: 20),
              const Text(
                'Количество участников',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (!_showCustomField) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    ..._maxUsersPresets.map((count) {
                      final isSelected = _maxUsers == count;
                      return ChoiceChip(
                        label: Text(count.toString()),
                        selected: isSelected,
                        selectedColor: AppColors.electricBlue,
                        backgroundColor: AppColors.backgroundSecondary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _maxUsers = count);
                        },
                      );
                    }).toList(),
                    ChoiceChip(
                      label: const Text('Другое'),
                      selected: _showCustomField,
                      selectedColor: AppColors.electricBlue,
                      backgroundColor: AppColors.backgroundSecondary,
                      labelStyle: TextStyle(
                        color: _showCustomField ? Colors.white : AppColors.text,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _showCustomField = selected;
                          if (selected) {
                            _customMaxUsersController.text =
                                _maxUsers.toString();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _customMaxUsersController,
                        placeholder: 'Введите количество',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showCustomField = false;
                        });
                      },
                      icon: const Icon(
                        Ionicons.close_circle,
                        size: 32,
                        color: AppColors.neonPink,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              CustomTextField(
                controller: _prizeController,
                label: 'Призовой фонд',
                prefixIcon: Ionicons.trophy_outline,
                placeholder: 'Например, 100 000 ₽',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Text(
                'Теги',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_existingTags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_existingTags.length, (index) {
                    final tag = _existingTags[index];
                    return Chip(
                      label: Text(tag['name'] ?? ''),
                      deleteIcon: const Icon(Ionicons.close_circle, size: 18),
                      onDeleted: () => _removeExistingTag(index),
                      backgroundColor: AppColors.backgroundSecondary,
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
              if (_newTags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_newTags.length, (index) {
                    return Chip(
                      label: Text(_newTags[index]),
                      deleteIcon: const Icon(Ionicons.close_circle, size: 18),
                      onDeleted: () => _removeNewTag(index),
                      backgroundColor: AppColors.backgroundSecondary,
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _tagController,
                      placeholder: 'Добавить тег',
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(
                      Ionicons.add_circle,
                      size: 32,
                      color: AppColors.electricBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Отмена',
                      isSecondary: true,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Сохранить',
                      isLoading: state.isLoading,
                      onPressed: _updateEvent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  DecorationImage? _getImageDecoration() {
    if (_selectedImage != null) {
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage('$baseUrl/files/$_currentImageUrl'),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  String _getPrizeValue() {
    final text = _prizeController.text.trim();
    if (text.isEmpty) return '0';
    try {
      final cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanText.isEmpty) return '0';
      final numValue = double.parse(cleanText);
      if (numValue == numValue.toInt()) {
        return numValue.toInt().toString();
      }
      return cleanText;
    } catch (e) {
      return '0';
    }
  }
}

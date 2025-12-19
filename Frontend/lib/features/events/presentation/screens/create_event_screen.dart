import 'dart:io';

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

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _prizeController = TextEditingController();

  // State
  EventCategory _selectedType = EventCategory.HACKATHON;
  int _maxUsers = 50;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _customMaxUsersController =
      TextEditingController();
  final List<int> _maxUsersPresets = [10, 50, 100, 200];
  final List<EventCategory> _eventTypes = EventCategory.values;
  File? _selectedImage;
  bool _showCustomField = false;

  @override
  void initState() {
    super.initState();
    _customMaxUsersController.text = _maxUsers.toString();
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      // Теперь вызываем выбор времени только если дата выбрана
      await _selectTime(isStart);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
    if (_tagController.text.isNotEmpty) {
      if (!_tags.contains(_tagController.text.trim())) {
        setState(() {
          _tags.add(_tagController.text.trim());
          _tagController.clear();
        });
      }
    }
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
      });
    }
  }

  void _createEvent() {
    if (_formKey.currentState!.validate()) {
      // Проверка обязательных полей
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

      // Проверка, что конечная дата не раньше начальной
      final startDateTime = DateTime(_startDate!.year, _startDate!.month,
          _startDate!.day, _startTime!.hour, _startTime!.minute);
      final endDateTime = DateTime(_endDate!.year, _endDate!.month,
          _endDate!.day, _endTime!.hour, _endTime!.minute);

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Дата окончания не может быть раньше даты начала')),
        );
        return;
      }

      // Парсинг пользовательского количества участников
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
        'location': _locationController.text,
        'maxUsersCount': _maxUsers,
        'startDate': startDateTime.toIso8601String(),
        'endDate': endDateTime.toIso8601String(),
        'prize': _prizeController.text,
        'tags': _tags,
        if (_selectedImage != null) 'imageFile': _selectedImage,
      };

      ref.read(eventsProvider.notifier).createEvent(eventData).then((_) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Мероприятие создано!'),
              backgroundColor: AppColors.success),
        );
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
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
        title: const Text('Создать событие',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              // Кнопка загрузки фото события
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 2),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Ionicons.camera_outline,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
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
              const SizedBox(height: 20),

              // Название (обязательное)
              CustomTextField(
                controller: _titleController,
                label: 'Название *',
                placeholder: 'Например, Хакатон 2024',
                validator: (v) =>
                    v?.isEmpty == true ? 'Введите название' : null,
              ),
              const SizedBox(height: 20),

              // Описание (обязательное)
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание *',
                placeholder: 'Расскажите о мероприятии...',
                maxLines: 4,
                validator: (v) =>
                    v?.isEmpty == true ? 'Введите описание' : null,
              ),
              const SizedBox(height: 20),

              // Тип события (обязательный)
              const Text('Тип события *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
                          fontWeight: FontWeight.bold),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Даты (обязательные)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Начало *',
                            style: TextStyle(color: AppColors.textSecondary)),
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
                                const Icon(Ionicons.calendar_outline,
                                    size: 18, color: AppColors.electricBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        _formatDateTime(_startDate, _startTime),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600))),
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
                        const Text('Окончание *',
                            style: TextStyle(color: AppColors.textSecondary)),
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
                                const Icon(Ionicons.time_outline,
                                    size: 18, color: AppColors.neonPink),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        _formatDateTime(_endDate, _endTime),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600))),
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

              // Количество участников с произвольным вводом
              const Text('Количество участников',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
                            color: isSelected ? Colors.white : AppColors.text),
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
                      icon: const Icon(Ionicons.close_circle,
                          size: 32, color: AppColors.neonPink),
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
              ),
              const SizedBox(height: 20),
              const Text('Теги',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          deleteIcon:
                              const Icon(Ionicons.close_circle, size: 18),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                          backgroundColor: AppColors.backgroundSecondary,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
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
                    icon: const Icon(Ionicons.add_circle,
                        size: 32, color: AppColors.electricBlue),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: 'Создать событие',
                isLoading: state.isLoading,
                onPressed: _createEvent,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

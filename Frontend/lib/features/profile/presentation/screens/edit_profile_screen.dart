// lib/features/profile/presentation/screens/edit_profile_screen.dart

import 'package:connecthub_app/core/enums/app_enums.dart';
import 'package:connecthub_app/core/widgets/custom_text_field.dart';
import 'package:connecthub_app/features/auth/domain/user.dart';
import 'package:connecthub_app/features/auth/presentation/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

// Provider is already defined in auth_provider.dart

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late TextEditingController _specializationController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;
  late TextEditingController _tagInputController;

  UserStatus? _status;

  // Tracking existing tags
  List<Tag> _ownTags = [];
  List<Tag> _seekingTags = [];

  // Tracking removed existing tag IDs
  final Set<int> _deletedOwnTagIds = {};
  final Set<int> _deletedSeekingTagIds = {};

  // Tracking newly added tag names
  List<String> _newOwnTags = [];
  List<String> _newSeekingTags = [];

  String _activeTagType = 'own'; // 'own' | 'seeking'
  bool _isLoading = false;

  final _quickTagsOwn = [
    'React',
    'TypeScript',
    'UI/UX',
    'Node.js',
    'Figma',
    'Python'
  ];
  final _quickTagsSeeking = [
    'Стартапы',
    'Менторство',
    'Фриланс',
    'Исследования',
    'Хакатоны'
  ];

  final _statusOptions = [
    {
      'id': UserStatus.open_to_offers,
      'label': 'Открыт к предложениям',
      'icon': Ionicons.flash
    },
    {
      'id': UserStatus.looking_for_team,
      'label': 'Ищу команду',
      'icon': Ionicons.people
    },
    {
      'id': UserStatus.looking_for_project,
      'label': 'Ищу проект',
      'icon': Ionicons.briefcase
    },
    {
      'id': UserStatus.just_networking,
      'label': 'Нетворкинг',
      'icon': Ionicons.chatbubbles
    },
    {'id': UserStatus.freelance, 'label': 'Фриланс', 'icon': Ionicons.laptop},
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _tagController = TextEditingController(text: user?.tag ?? '');
    _specializationController =
        TextEditingController(text: user?.specialization ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _tagInputController = TextEditingController();

    _status = user?.status ?? UserStatus.just_networking;

    // Copy initial tags
    _ownTags = List.from(user?.ownTags ?? []);
    _seekingTags = List.from(user?.seekingTags ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _specializationController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (_activeTagType == 'own') {
        if (!_newOwnTags.contains(text) &&
            !_ownTags.any((t) => t.name == text)) {
          _newOwnTags.add(text);
        }
      } else {
        if (!_newSeekingTags.contains(text) &&
            !_seekingTags.any((t) => t.name == text)) {
          _newSeekingTags.add(text);
        }
      }
      _tagInputController.clear();
    });
  }

  void _removeTag(dynamic tag, String type) {
    setState(() {
      if (tag is Tag) {
        // Removing an existing tag
        if (type == 'own') {
          _ownTags.removeWhere((t) => t.id == tag.id);
          _deletedOwnTagIds.add(tag.id);
        } else {
          _seekingTags.removeWhere((t) => t.id == tag.id);
          _deletedSeekingTagIds.add(tag.id);
        }
      } else if (tag is String) {
        // Removing a newly added tag
        if (type == 'own') {
          _newOwnTags.remove(tag);
        } else {
          _newSeekingTags.remove(tag);
        }
      }
    });
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty ||
        _specializationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните обязательные поля')));
      return;
    }

    setState(() => _isLoading = true);

    final repo = ref.read(profileRepositoryProvider);

    try {
      // 1. Update Profile Information
      final updateData = {
        'name': _nameController.text.trim(),
        'tag': _tagController.text.trim(),
        'status': _status?.value,
        'city': _cityController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'bio': _bioController.text.trim(),
      };
      await repo.updateUser(updateData);

      // 2. Delete tags by ID (Parallel)
      await Future.wait([
        ..._deletedOwnTagIds.map((id) => repo.removeTag(id, 'OWN')),
        ..._deletedSeekingTagIds.map((id) => repo.removeTag(id, 'SEEKING')),
      ]);

      // 3. Add new tags (Parallel where possible)
      final List<Future> addFutures = [];
      if (_newOwnTags.isNotEmpty) {
        addFutures.add(repo.addTags(_newOwnTags, 'OWN'));
      }
      if (_newSeekingTags.isNotEmpty) {
        addFutures.add(repo.addTags(_newSeekingTags, 'SEEKING'));
      }
      if (addFutures.isNotEmpty) {
        await Future.wait(addFutures);
      }

      // 4. Refresh auth state to get updated user info
      await ref.read(authProvider.notifier).checkAuthStatus();

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль успешно обновлен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка сохранения')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Редактировать профиль',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionLabel('Имя *'),
                  CustomTextField(
                      controller: _nameController, placeholder: 'Иван Иванов'),
                  const SizedBox(height: 24),

                  _buildSectionLabel('Тег (@username)'),
                  CustomTextField(
                      controller: _tagController, placeholder: 'connecthub'),
                  const SizedBox(height: 24),

                  _buildSectionLabel('Специализация *'),
                  CustomTextField(
                      controller: _specializationController,
                      placeholder: 'Frontend разработчик'),
                  const SizedBox(height: 24),

                  _buildSectionLabel('Город'),
                  CustomTextField(
                      controller: _cityController, placeholder: 'Москва'),
                  const SizedBox(height: 24),

                  _buildSectionLabel('Статус'),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusOptions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final option = _statusOptions[index];
                        final isSelected = _status == option['id'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _status = option['id'] as UserStatus),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE3F2FD)
                                  : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? Border.all(color: const Color(0xFF007AFF))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE3F2FD)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(option['icon'] as IconData,
                                      size: 16,
                                      color: isSelected
                                          ? const Color(0xFF007AFF)
                                          : const Color(0xFF666666)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  option['label'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF007AFF)
                                        : const Color(0xFF666666),
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionLabel('О себе'),
                  Container(
                    height: 85,
                    // decoration: BoxDecoration(
                    //   // color: Colors.white,
                    //   borderRadius: BorderRadius.circular(12),
                    //   border: Border.all(color: const Color(0xFFE5E5EA)),
                    // ),
                    child: TextField(
                      controller: _bioController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Расскажите о своем опыте и интересах...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedBuilder(
                      animation: _bioController,
                      builder: (context, _) => Text(
                          '${_bioController.text.length}/500',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags Section
                  _buildTagTypeSelector(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5EA)),
                          ),
                          child: TextField(
                            controller: _tagInputController,
                            decoration: InputDecoration(
                              hintText: _activeTagType == 'own'
                                  ? 'Добавить навык...'
                                  : 'Добавить что ищу...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addTag,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5EA)),
                          ),
                          child: Icon(Ionicons.add,
                              color: _activeTagType == 'own'
                                  ? const Color(0xFF007AFF)
                                  : const Color(0xFFFF6B35)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_activeTagType == 'own'
                            ? _quickTagsOwn
                            : _quickTagsSeeking)
                        .map((tag) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_activeTagType == 'own') {
                              if (!_newOwnTags.contains(tag) &&
                                  !_ownTags.any((t) => t.name == tag)) {
                                _newOwnTags.add(tag);
                              }
                            } else {
                              if (!_newSeekingTags.contains(tag) &&
                                  !_seekingTags.any((t) => t.name == tag)) {
                                _newSeekingTags.add(tag);
                              }
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTagType == 'own'
                                ? const Color(0xFFF2F2F7)
                                : const Color(0xFFFFE5E5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text('+ $tag',
                              style: TextStyle(
                                color: _activeTagType == 'own'
                                    ? const Color(0xFF666666)
                                    : const Color(0xFFFF3B30),
                                fontSize: 13,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Render existing tags
                      ...(_activeTagType == 'own' ? _ownTags : _seekingTags)
                          .map((tag) => _buildTagItem(tag, true)),
                      // Render new tags
                      ...(_activeTagType == 'own'
                              ? _newOwnTags
                              : _newSeekingTags)
                          .map((tag) => _buildTagItem(tag, false)),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F2F7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Отмена',
                        style: TextStyle(
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isLoading ||
                            _nameController.text.isEmpty ||
                            _specializationController.text.isEmpty)
                        ? null
                        : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      disabledBackgroundColor: const Color(0xFFC7C7CC),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Сохранить',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
    );
  }

  Widget _buildTagItem(dynamic tag, bool isExisting) {
    final String label = isExisting ? (tag as Tag).name : (tag as String);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _activeTagType == 'own'
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                color: _activeTagType == 'own'
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFFF6B35),
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeTag(tag, _activeTagType),
            child: Icon(Ionicons.close,
                size: 16,
                color: _activeTagType == 'own'
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFFF6B35)),
          ),
        ],
      ),
    );
  }

  Widget _buildTagTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTagType = 'own'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTagType == 'own'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTagType == 'own'
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.ribbon_outline,
                        size: 18,
                        color: _activeTagType == 'own'
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF666666)),
                    const SizedBox(width: 8),
                    Text('Мои навыки (${_ownTags.length + _newOwnTags.length})',
                        style: TextStyle(
                          color: _activeTagType == 'own'
                              ? Colors.black
                              : const Color(0xFF666666),
                          fontWeight: _activeTagType == 'own'
                              ? FontWeight.w600
                              : FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTagType = 'seeking'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTagType == 'seeking'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTagType == 'seeking'
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.search_outline,
                        size: 18,
                        color: _activeTagType == 'seeking'
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFF666666)),
                    const SizedBox(width: 8),
                    Text(
                        'Ищу (${_seekingTags.length + _newSeekingTags.length})',
                        style: TextStyle(
                          color: _activeTagType == 'seeking'
                              ? Colors.black
                              : const Color(0xFF666666),
                          fontWeight: _activeTagType == 'seeking'
                              ? FontWeight.w600
                              : FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

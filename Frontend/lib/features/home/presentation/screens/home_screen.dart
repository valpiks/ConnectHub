import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home_provider.dart';
import '../widgets/action_buttons.dart';
import '../widgets/event_card.dart';
import '../widgets/mode_switch.dart';
import '../widgets/swipeable_card.dart';
import '../widgets/user_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<_SwipeStackState> _swipeStackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Mode Switch
            ModeSwitch(
              mode: state.mode == HomeMode.users ? 'users' : 'events',
              onModeChange: (mode) {
                notifier.setMode(
                  mode == 'users' ? HomeMode.users : HomeMode.events,
                );
                _swipeStackKey.currentState?.reset();
              },
            ),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(state, notifier, context),
            ),

            if (!state.isLoading && _hasContent(state))
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ActionButtons(
                  onSwipeLeft: () => _swipeStackKey.currentState?.swipeLeft(),
                  onSwipeRight: () => _swipeStackKey.currentState?.swipeRight(),
                  onInfo: () {
                    context.push(state.mode == HomeMode.users
                        ? '/profile/${state.users[state.currentIndex].uuid}'
                        : '/events/${state.events[state.currentIndex]['id']}');
                  },
                  mode: state.mode == HomeMode.users ? 'users' : 'events',
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasContent(HomeState state) {
    if (state.mode == HomeMode.users) {
      return state.users.isNotEmpty && state.currentIndex < state.users.length;
    } else {
      return state.events.isNotEmpty &&
          state.currentIndex < state.events.length;
    }
  }

  Widget _buildContent(
      HomeState state, HomeNotifier notifier, BuildContext context) {
    if (!_hasContent(state)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет новых рекомендаций',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: _SwipeStack(
        key: _swipeStackKey,
        state: state,
        notifier: notifier,
        onSwipeLeft: () => notifier.swipeLeft(),
        onSwipeRight: () => notifier.swipeRight(),
        onCardTap: (index) {
          context.push(state.mode == HomeMode.users
              ? '/profile/${state.users[index].uuid}'
              : '/events/${state.events[index]['id']}');
        },
      ),
    );
  }
}

class _SwipeStack extends StatefulWidget {
  final HomeState state;
  final HomeNotifier notifier;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final Function(int) onCardTap;

  const _SwipeStack({
    required this.state,
    required this.notifier,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onCardTap,
    super.key,
  });

  @override
  State<_SwipeStack> createState() => _SwipeStackState();
}

class _SwipeStackState extends State<_SwipeStack> {
  // Показываем только 2-3 верхние карточки
  static const int _visibleCards = 3;
  final GlobalKey<SwipeableCardState> _topCardKey =
      GlobalKey<SwipeableCardState>();

  @override
  void initState() {
    super.initState();
    _checkAndLoadMore();
  }

  void _checkAndLoadMore() {
    // Если осталось мало карточек, загружаем новые
    final remainingCards = _getRemainingCardsCount();
    if (remainingCards <= _visibleCards) {
      // Можно добавить загрузку новых данных
    }
  }

  int _getRemainingCardsCount() {
    final total = widget.state.mode == HomeMode.users
        ? widget.state.users.length
        : widget.state.events.length;
    return total - widget.state.currentIndex;
  }

  void swipeLeft() {
    _topCardKey.currentState?.swipe(false);
  }

  void swipeRight() {
    _topCardKey.currentState?.swipe(true);
  }

  void reset() {
    _topCardKey.currentState?.reset();
  }

  void _swipeCard(bool isLike) {
    final remainingCards = _getRemainingCardsCount();

    if (remainingCards > 0) {
      // Вызываем колбэк родителя
      if (isLike) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }

      // Проверяем нужно ли загрузить еще
      _checkAndLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingCards = _getRemainingCardsCount();
    final visibleCardCount = remainingCards.clamp(0, _visibleCards);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.92; // Slightly wider for premium look

    return SizedBox(
      width: cardWidth,
      height: 560, // Increased height for better proportions
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(visibleCardCount, (index) {
          // Bottom card has high stackIndex, Top card has stackIndex 0
          // We render from bottom-up: index 0 is largest stackIndex, index (count-1) is stackIndex 0
          final int stackIndex = visibleCardCount - 1 - index;
          final int dataIndex = widget.state.currentIndex + stackIndex;
          final isTopCard = stackIndex == 0;

          // These values match the visual logic in RN
          final double verticalOffset = stackIndex * 12.0;
          final double scale = 1.0 - (stackIndex * 0.05);
          final double opacity = 1.0 - (stackIndex * 0.3);

          return Positioned(
            top: verticalOffset,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: SizedBox(
                  width: cardWidth,
                  height: 500, // Fixed height to avoid unbounded height error
                  child: isTopCard
                      ? _buildTopCard(dataIndex)
                      : _buildBackCard(dataIndex, stackIndex),
                ),
              ),
            ),
          );
        }), // NO .reversed.toList() here! index (visibleCardCount-1) is the top one.
      ),
    );
  }

  Widget _buildTopCard(int dataIndex) {
    return SwipeableCard(
      key: _topCardKey,
      identity: widget.state.mode == HomeMode.users
          ? widget.state.users[dataIndex].uuid
          : widget.state.events[dataIndex]['id'],
      onSwipe: _swipeCard,
      onTap: () => widget.onCardTap(dataIndex),
      child: _buildCardContent(dataIndex),
    );
  }

  Widget _buildBackCard(int dataIndex, int stackIndex) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4 + (stackIndex * 2)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: _buildCardContent(dataIndex),
      ),
    );
  }

  Widget _buildCardContent(int index) {
    if (widget.state.mode == HomeMode.users) {
      if (index >= widget.state.users.length) return const SizedBox();
      return UserCard(user: widget.state.users[index]);
    } else {
      if (index >= widget.state.events.length) return const SizedBox();
      return EventCard(event: widget.state.events[index]);
    }
  }
}

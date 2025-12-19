import 'package:connecthub_app/features/chat/presentation/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatListProvider);
    final notifier = ref.read(chatListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Ionicons.people_outline, color: Colors.black),
            onPressed: () => context.push('/friends'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadThreads(),
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.threads.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.threads.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Пока нет чатов',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.threads.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final thread = state.threads[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(
                      Ionicons.chatbubbles_outline,
                      color: Colors.blueAccent,
                    ),
                  ),
                  title: Text(
                    thread.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: thread.lastMessage != null
                      ? Text(
                          thread.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: thread.hasUnread
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () => context.push('/chat/${thread.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


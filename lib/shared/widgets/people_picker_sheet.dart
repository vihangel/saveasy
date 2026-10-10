import 'adaptive_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../utils/context_x.dart';
import 'user_avatar.dart';

/// Escolher várias pessoas (marcar em publicação). Retorna a lista final ou
/// `null` se fechar sem confirmar.
Future<List<AppUser>?> showPeoplePicker(BuildContext context, {List<AppUser> selected = const []}) {
  return showAdaptiveSheet<List<AppUser>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PeoplePicker(initial: selected),
  );
}

class _PeoplePicker extends StatefulWidget {
  const _PeoplePicker({required this.initial});

  final List<AppUser> initial;

  @override
  State<_PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends State<_PeoplePicker> {
  late final _selected = {for (final u in widget.initial) u.id: u};
  late Future<List<AppUser>> _users = _search('');

  Future<List<AppUser>> _search(String q) =>
      context.read<UserRepository>().search(q, excludeId: context.currentUser.id);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              onChanged: (q) => setState(() => _users = _search(q)),
              decoration: const InputDecoration(hintText: 'Buscar pessoas', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _users,
              builder: (context, snapshot) {
                final users = snapshot.data;
                if (users == null) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return CheckboxListTile(
                      value: _selected.containsKey(u.id),
                      onChanged: (v) => setState(() => v! ? _selected[u.id] = u : _selected.remove(u.id)),
                      secondary: UserAvatar(name: u.name, imageUrl: u.avatarUrl, size: 40),
                      title: Text(u.name),
                      subtitle: Text('@${u.username}'),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected.values.toList()),
                  child: Text('Marcar ${_selected.length} pessoa(s)'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

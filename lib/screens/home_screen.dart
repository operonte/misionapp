import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_state.dart';
import '../models/person.dart';
import '../services/firestore_service.dart';
import '../utils/visit_color.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestore = FirestoreService();
  final Map<String, DateTime?> _lastVisitCache = {};

  String _sortBy = 'nombre'; // nombre | ultimaVisita | complejidad
  String? _filterQuiereVisitas; // null | Sí | No
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProfileIfNeeded();
  }

  Future<void> _loadProfileIfNeeded() async {
    if (currentUserProfile != null) return;
    final user = currentFirebaseUser;
    if (user == null) return;
    final profile = await _firestore.getUserProfile(user.uid);
    if (profile != null && mounted) {
      setState(() => currentUserProfile = profile);
    }
  }

  List<Person> _filterSort(List<Person> list) {
    var out = list;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      out = out
          .where((p) =>
              p.nombreApellidos.toLowerCase().contains(q) ||
              p.direccion.toLowerCase().contains(q))
          .toList();
    }
    if (_filterQuiereVisitas != null) {
      out = out
          .where((p) => p.quiereRecibirVisitas == _filterQuiereVisitas)
          .toList();
    }
    switch (_sortBy) {
      case 'ultimaVisita':
        out.sort((a, b) {
          final da = _lastVisitCache[a.id];
          final db = _lastVisitCache[b.id];
          if (da == null && db == null) return a.nombreApellidos.compareTo(b.nombreApellidos);
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
      case 'complejidad':
        out.sort((a, b) =>
            b.nivelComplejidad.compareTo(a.nivelComplejidad));
        break;
      default:
        out.sort((a, b) =>
            a.nombreApellidos.toLowerCase().compareTo(b.nombreApellidos.toLowerCase()));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final profile = currentUserProfile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o dirección',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chip('Ordenar', _sortBy == 'nombre'
                    ? 'Nombre'
                    : _sortBy == 'ultimaVisita'
                        ? 'Últ. visita'
                        : 'Complejidad', () => _showSortMenu(context)),
                const SizedBox(width: 8),
                _chip('Quiere visitas', _filterQuiereVisitas ?? 'Todos',
                    () => _showFilterMenu(context)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Person>>(
              stream: _firestore.personsStream(profile.grupo),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}'));
                }
                final list = snap.data ?? [];
                final ids = list.map((e) => e.id).toSet();
                if (ids.isNotEmpty) {
                  Future.wait(list.map((p) => _firestore.getLastVisitDate(p.id)))
                      .then((dates) {
                    if (!mounted) return;
                    bool changed = false;
                    for (var i = 0; i < list.length; i++) {
                      if (_lastVisitCache[list[i].id] != dates[i]) {
                        _lastVisitCache[list[i].id] = dates[i];
                        changed = true;
                      }
                    }
                    if (changed) setState(() {});
                  });
                }
                final displayed = _filterSort(list);
                if (displayed.isEmpty) {
                  return Center(
                    child: Text(
                      list.isEmpty
                          ? 'Aún no hay personas. Agrega la primera.'
                          : 'No hay resultados.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: displayed.length,
                  itemBuilder: (context, i) {
                    final p = displayed[i];
                    final lastVisit = _lastVisitCache[p.id];
                    final days = daysSince(lastVisit);
                    final color = colorForDaysSinceVisit(days);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.3),
                          child: Icon(Icons.person, color: color),
                        ),
                        title: Text(p.nombreApellidos),
                        subtitle: profile.isAdmin
                            ? Text(p.grupo,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary))
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/person/${p.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/person/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip(String label, String value, VoidCallback onTap) {
    return FilterChip(
      label: Text('$label: $value'),
      onSelected: (_) => onTap(),
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Por nombre'),
              onTap: () {
                setState(() => _sortBy = 'nombre');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Por última visita'),
              onTap: () {
                setState(() => _sortBy = 'ultimaVisita');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Por complejidad'),
              onTap: () {
                setState(() => _sortBy = 'complejidad');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              onTap: () {
                setState(() => _filterQuiereVisitas = null);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Sí quiere visitas'),
              onTap: () {
                setState(() => _filterQuiereVisitas = 'Sí');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('No quiere visitas'),
              onTap: () {
                setState(() => _filterQuiereVisitas = 'No');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

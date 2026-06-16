import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_state.dart';
import '../models/person.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../utils/visit_color.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestore = FirestoreService();

  String _sortBy = 'nombre'; // nombre | ultimaVisita | complejidad
  String? _filterQuiereVisitas; // null | Sí | No
  String? _filterInactividad;   // null | '30d' | '60d'
  bool _filterAltaComplejidad = false;
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

  Future<void> _refresh(String grupo) async {
    await _firestore.refreshPersons(grupo);
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

    if (_filterInactividad != null) {
      final days = _filterInactividad == '30d' ? 30 : 60;
      final cutoff = DateTime.now().subtract(Duration(days: days));
      out = out
          .where((p) => p.ultimaVisita == null || p.ultimaVisita!.isBefore(cutoff))
          .toList();
    }

    if (_filterAltaComplejidad) {
      out = out.where((p) => p.nivelComplejidad >= 5).toList();
    }

    switch (_sortBy) {
      case 'ultimaVisita':
        out.sort((a, b) {
          final da = a.ultimaVisita;
          final db = b.ultimaVisita;
          if (da == null && db == null) {
            return a.nombreApellidos.compareTo(b.nombreApellidos);
          }
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
      case 'complejidad':
        out.sort((a, b) => b.nivelComplejidad.compareTo(a.nivelComplejidad));
        break;
      default:
        out.sort((a, b) => a.nombreApellidos
            .toLowerCase()
            .compareTo(b.nombreApellidos.toLowerCase()));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: userProfileListenable,
      builder: (context, profile, _) {
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
              // Offline banner
              StreamBuilder<List<ConnectivityResult>>(
                stream: Connectivity().onConnectivityChanged,
                builder: (context, snap) {
                  final results = snap.data ?? [];
                  final isOffline = results.isNotEmpty &&
                      results.every((r) => r == ConnectivityResult.none);
                  if (!isOffline) return const SizedBox.shrink();
                  return Container(
                    color: Colors.orange.shade700,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 16),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_off, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sin conexión — mostrando datos guardados',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
                    _chip(
                        'Ordenar',
                        _sortBy == 'nombre'
                            ? 'Nombre'
                            : _sortBy == 'ultimaVisita'
                                ? 'Últ. visita'
                                : 'Complejidad',
                        () => _showSortMenu(context)),
                    const SizedBox(width: 8),
                    _chip(
                        'Quiere visitas',
                        _filterQuiereVisitas ?? 'Todos',
                        () => _showVisitasMenu(context)),
                    const SizedBox(width: 8),
                    _chip(
                        'Inactividad',
                        _filterInactividad == null
                            ? 'Todos'
                            : _filterInactividad == '30d'
                                ? '+30 días'
                                : '+60 días',
                        () => _showInactividadMenu(context)),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Alta complejidad'),
                      selected: _filterAltaComplejidad,
                      onSelected: (v) =>
                          setState(() => _filterAltaComplejidad = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Person>>(
                  stream: _firestore.personsStream(profile.grupo),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final list = snap.data ?? [];
                    final displayed = _filterSort(list);
                    return RefreshIndicator(
                      onRefresh: () => _refresh(profile.grupo),
                      child: displayed.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Text(
                                      list.isEmpty
                                          ? 'Aún no hay personas. Agrega la primera.'
                                          : 'No hay resultados para los filtros aplicados.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: displayed.length,
                              itemBuilder: (context, i) {
                                final p = displayed[i];
                                final days = daysSince(p.ultimaVisita);
                                final color = colorForDaysSinceVisit(days);
                                return Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          color.withValues(alpha: 0.3),
                                      child: Icon(Icons.person,
                                          color: color),
                                    ),
                                    title: Text(p.nombreApellidos),
                                    subtitle: _buildSubtitle(
                                        context, profile.isAdmin, p),
                                    trailing:
                                        const Icon(Icons.chevron_right),
                                    onTap: () =>
                                        context.push('/person/${p.id}'),
                                  ),
                                );
                              },
                            ),
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
      },
    );
  }

  Widget? _buildSubtitle(BuildContext context, bool isAdmin, Person p) {
    final visitText = p.totalVisitas > 0
        ? '${p.totalVisitas} ${p.totalVisitas == 1 ? 'visita' : 'visitas'}'
        : null;

    if (isAdmin) {
      final text = visitText != null ? '${p.grupo} · $visitText' : p.grupo;
      return Text(
        text,
        style: TextStyle(
            fontSize: 12, color: Theme.of(context).colorScheme.secondary),
      );
    }

    if (visitText == null) return null;
    return Text(
      visitText,
      style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              trailing: _sortBy == 'nombre'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _sortBy = 'nombre');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Por última visita'),
              trailing: _sortBy == 'ultimaVisita'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _sortBy = 'ultimaVisita');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Por complejidad'),
              trailing: _sortBy == 'complejidad'
                  ? const Icon(Icons.check)
                  : null,
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

  void _showVisitasMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              trailing: _filterQuiereVisitas == null
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _filterQuiereVisitas = null);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Sí quiere visitas'),
              trailing: _filterQuiereVisitas == 'Sí'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _filterQuiereVisitas = 'Sí');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('No quiere visitas'),
              trailing: _filterQuiereVisitas == 'No'
                  ? const Icon(Icons.check)
                  : null,
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

  void _showInactividadMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              trailing: _filterInactividad == null
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _filterInactividad = null);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Sin visita en más de 30 días'),
              trailing: _filterInactividad == '30d'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _filterInactividad = '30d');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Sin visita en más de 60 días'),
              trailing: _filterInactividad == '60d'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _filterInactividad = '60d');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

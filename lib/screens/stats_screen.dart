import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/person.dart';
import '../services/firestore_service.dart';
import '../utils/app_error.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestore = FirestoreService();
  late Future<List<Person>> _future;

  @override
  void initState() {
    super.initState();
    _future = _firestore.getAllPersonsForExport();
  }

  void _refresh() {
    setState(() => _future = _firestore.getAllPersonsForExport());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Person>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugLog('Error al cargar estadísticas', snap.error);
            return Center(child: Text('Error al cargar datos.'));
          }
          final persons = snap.data ?? [];
          if (persons.isEmpty) {
            return const Center(
                child: Text('Aún no hay personas registradas.'));
          }
          return _StatsContent(persons: persons);
        },
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final List<Person> persons;

  const _StatsContent({required this.persons});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff30 = now.subtract(const Duration(days: 30));
    final cutoff60 = now.subtract(const Duration(days: 60));

    final total = persons.length;
    final totalVisitas =
        persons.fold<int>(0, (s, p) => s + p.totalVisitas);
    final sinVisita = persons.where((p) => p.totalVisitas == 0).length;
    final sin30 = persons
        .where((p) =>
            p.ultimaVisita == null || p.ultimaVisita!.isBefore(cutoff30))
        .length;
    final sin60 = persons
        .where((p) =>
            p.ultimaVisita == null || p.ultimaVisita!.isBefore(cutoff60))
        .length;
    final quierenVisitas =
        persons.where((p) => p.quiereRecibirVisitas == 'Sí').length;

    // Por grupo
    final grupos = <String, int>{};
    for (final p in persons) {
      grupos[p.grupo] = (grupos[p.grupo] ?? 0) + 1;
    }
    final gruposSorted = grupos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxGrupo = gruposSorted.isEmpty ? 1 : gruposSorted.first.value;

    // Por complejidad (1–7)
    final complejidad = <int, int>{};
    for (final p in persons) {
      complejidad[p.nivelComplejidad] =
          (complejidad[p.nivelComplejidad] ?? 0) + 1;
    }
    final maxComp = complejidad.values.isEmpty
        ? 1
        : complejidad.values.reduce((a, b) => a > b ? a : b);

    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d/M/yyyy HH:mm');
    final lastUpdated = fmt.format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            _SummaryCard(
              value: '$total',
              label: 'Personas',
              icon: Icons.people_outline,
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              value: '$totalVisitas',
              label: 'Visitas totales',
              icon: Icons.event_available_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Activity section
        _SectionHeader(title: 'Actividad'),
        _BarRow(
          label: 'Nunca visitadas',
          count: sinVisita,
          total: total,
          color: cs.error,
        ),
        _BarRow(
          label: 'Sin visita en +30 días',
          count: sin30,
          total: total,
          color: Colors.orange,
        ),
        _BarRow(
          label: 'Sin visita en +60 días',
          count: sin60,
          total: total,
          color: Colors.deepOrange,
        ),
        _BarRow(
          label: 'Quieren recibir visitas',
          count: quierenVisitas,
          total: total,
          color: cs.primary,
        ),
        const SizedBox(height: 24),

        // By group
        _SectionHeader(title: 'Personas por grupo'),
        ...gruposSorted.map(
          (e) => _BarRow(
            label: e.key,
            count: e.value,
            total: maxGrupo,
            color: cs.secondary,
          ),
        ),
        const SizedBox(height: 24),

        // By complexity
        _SectionHeader(title: 'Distribución de complejidad (1–7)'),
        ...List.generate(7, (i) {
          final level = i + 1;
          final count = complejidad[level] ?? 0;
          return _BarRow(
            label: 'Nivel $level',
            count: count,
            total: maxComp,
            color: _complexityColor(level),
          );
        }),
        const SizedBox(height: 24),

        Text(
          'Actualizado: $lastUpdated',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.outline),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static Color _complexityColor(int level) {
    const colors = [
      Color(0xFF43A047), // 1 verde
      Color(0xFF8BC34A), // 2
      Color(0xFFCDDC39), // 3
      Color(0xFFFFC107), // 4 amarillo
      Color(0xFFFF9800), // 5 naranja
      Color(0xFFFF5722), // 6
      Color(0xFFE53935), // 7 rojo
    ];
    return colors[(level - 1).clamp(0, 6)];
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: cs.onPrimaryContainer),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: TextStyle(color: cs.onPrimaryContainer, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _BarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$count',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

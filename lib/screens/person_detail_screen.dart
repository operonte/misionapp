import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models/person.dart';
import '../models/visit.dart';
import '../services/firestore_service.dart';
import '../utils/visit_color.dart';
import '../app_config.dart';

class PersonDetailScreen extends StatelessWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  Color _complexityColor(int n) {
    if (n <= 1) return const Color(0xFF43A047);
    if (n <= 2) return const Color(0xFF8BC34A);
    if (n <= 3) return const Color(0xFFCDDC39);
    if (n <= 4) return const Color(0xFFFFC107);
    if (n <= 5) return const Color(0xFFFF9800);
    if (n <= 6) return const Color(0xFFFF5722);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final profile = currentUserProfile;
    final isAdmin = profile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persona'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/person/edit/$personId'),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, firestore),
            ),
        ],
      ),
      body: FutureBuilder<Person?>(
        future: firestore.getPerson(personId),
        builder: (context, personSnap) {
          if (!personSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }
          final person = personSnap.data;
          if (person == null) {
            return const Center(child: Text('No encontrada'));
          }
          final lastVisitFuture = firestore.getLastVisitDate(personId);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Chip(
                        label: Text(person.grupo),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer),
                  ),
                _row('Nombre y apellidos', person.nombreApellidos),
                _row('Dirección', person.direccion),
                _row('Teléfono', person.telefono),
                _row('Edad', person.edad),
                _row('Género', person.genero),
                _row('A qué se dedica', person.aQueSeDedica),
                _row('Cristiano / asiste iglesia',
                    person.esCristianoOAsisteIglesia),
                _row('Quiere recibir visitas', person.quiereRecibirVisitas),
                _row('Vicios', person.vicios.join(', ')),
                _row('Enfermedad mental', person.enfermedadMental),
                _row('Enfermedad crónica', person.enfermedadCronica),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Complejidad: '),
                    Expanded(
                      child: Row(
                        children: List.generate(7, (i) {
                          final v = i + 1;
                          return Expanded(
                            child: Container(
                              height: 24,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: person.nivelComplejidad >= v
                                    ? _complexityColor(v)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Text(' ${person.nivelComplejidad}/7'),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder<DateTime?>(
                  future: lastVisitFuture,
                  builder: (ctx, lastSnap) {
                    final last = lastSnap.data;
                    final days = daysSince(last);
                    final color = colorForDaysSinceVisit(days);
                    return Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          last == null
                              ? 'Sin visitas registradas'
                              : 'Última visita: ${DateFormat('d/M/yyyy').format(last)} (${days ?? 0} días)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Visitas',
                        style: Theme.of(context).textTheme.titleMedium),
                    FilledButton.icon(
                      onPressed: () => _openAddVisit(context, person),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Registrar visita'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Visit>>(
                  stream: firestore.visitsStream(personId),
                  builder: (context, visitSnap) {
                    final visits = visitSnap.data ?? [];
                    if (visits.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aún no hay visitas.',
                          style: TextStyle(
                              color: Colors.grey),
                        ),
                      );
                    }
                    return Column(
                      children: visits.map((v) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(DateFormat('d/M/yyyy').format(v.fecha)),
                            subtitle: Text(v.visitadoPor),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showVisitContent(context, v),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value.isEmpty ? '—' : value),
          ],
        ),
      ),
    );
  }

  void _showVisitContent(BuildContext context, Visit v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Visita ${DateFormat('d/M/yyyy').format(v.fecha)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Visitado por: ${v.visitadoPor}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(v.contenido),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddVisit(BuildContext context, Person person) async {
    final profile = currentUserProfile;
    if (profile == null) return;
    final content = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Registrar visita'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Contenido de la visita',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (content == null || !context.mounted) return;
    final visit = Visit(
      id: '',
      fecha: DateTime.now(),
      contenido: content,
      visitadoPor: profile.displayName,
    );
    await FirestoreService().addVisit(personId, visit);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita registrada')),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, FirestoreService firestore) async {
    final person = await firestore.getPerson(personId);
    if (person == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar persona'),
        content: Text(
          '¿Eliminar a ${person.nombreApellidos}? Se borrarán también todas sus visitas.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await firestore.deletePerson(personId);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Persona eliminada')),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models/person.dart';
import '../models/visit.dart';
import '../services/firestore_service.dart';
import '../utils/visit_color.dart';
import '../utils/app_error.dart';

final _dateFmt = DateFormat('d/M/yyyy HH:mm');

class PersonDetailScreen extends StatefulWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  // Service is a field — not re-created on every build.
  final FirestoreService _firestore = FirestoreService();

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
    final profile = currentUserProfile;
    final isAdmin = profile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persona'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/person/edit/${widget.personId}'),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeletePerson(context),
            ),
        ],
      ),
      // StreamBuilder keeps the detail in sync if the person is edited elsewhere.
      body: StreamBuilder<Person?>(
        stream: _firestore.personStream(widget.personId),
        builder: (context, personSnap) {
          if (personSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final person = personSnap.data;
          if (person == null) {
            return const Center(child: Text('Persona no encontrada'));
          }
          final days = daysSince(person.ultimaVisita);
          final visitColor = colorForDaysSinceVisit(days);

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
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
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
                if (person.comentarios.isNotEmpty)
                  _row('Comentarios', person.comentarios),
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: visitColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        person.ultimaVisita == null
                            ? 'Sin visitas registradas'
                            : 'Última visita: ${DateFormat('d/M/yyyy').format(person.ultimaVisita!)} (${days ?? 0} días)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (isAdmin && _hasAuditInfo(person)) ...[
                  const SizedBox(height: 12),
                  _auditInfo(context, person),
                ],
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visitas (${person.totalVisitas})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    FilledButton.icon(
                      onPressed: () => _openAddVisit(context, person),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Registrar visita'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Visit>>(
                  stream: _firestore.visitsStream(widget.personId),
                  builder: (context, visitSnap) {
                    final visits = visitSnap.data ?? [];
                    if (visits.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aún no hay visitas.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return Column(
                      children: visits.map((v) => _visitTile(context, v)).toList(),
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

  Widget _visitTile(BuildContext context, Visit v) {
    return Dismissible(
      key: ValueKey(v.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDeleteVisit(context, v),
      onDismissed: (_) async {
        try {
          await _firestore.deleteVisit(widget.personId, v.id);
        } catch (e, st) {
          debugLog('Error al eliminar visita', e, st);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(friendlyError(e)),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(DateFormat('d/M/yyyy').format(v.fecha)),
          subtitle: Text(v.visitadoPor),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showVisitContent(context, v),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
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

  bool _hasAuditInfo(Person p) =>
      p.creadoEn != null || p.fechaModificacion != null;

  Widget _auditInfo(BuildContext context, Person p) {
    final color = Theme.of(context).colorScheme.outline;
    final style = TextStyle(fontSize: 11, color: color);
    final lines = <String>[];
    if (p.creadoEn != null) {
      final who = p.creadoPor?.isNotEmpty == true ? ' por ${p.creadoPor}' : '';
      lines.add('Creado: ${_dateFmt.format(p.creadoEn!)}$who');
    }
    if (p.fechaModificacion != null) {
      final who = p.modificadoPor?.isNotEmpty == true
          ? ' por ${p.modificadoPor}'
          : '';
      lines.add('Modificado: ${_dateFmt.format(p.fechaModificacion!)}$who');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((l) => Text(l, style: style)).toList(),
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

  Future<bool> _confirmDeleteVisit(BuildContext context, Visit v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar visita'),
        content: Text(
            '¿Eliminar la visita del ${DateFormat('d/M/yyyy').format(v.fecha)}?'),
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
    return ok ?? false;
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
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Contenido de la visita',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (content == null || content.trim().isEmpty || !context.mounted) return;
    try {
      final visit = Visit(
        id: '',
        fecha: DateTime.now(),
        contenido: content.trim(),
        visitadoPor: profile.displayName,
      );
      await _firestore.addVisit(widget.personId, visit);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visita registrada')),
        );
      }
    } catch (e, st) {
      debugLog('Error al agregar visita', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeletePerson(BuildContext context) async {
    final person = await _firestore.getPerson(widget.personId);
    if (person == null || !context.mounted) return;
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
      try {
        await _firestore.deletePerson(widget.personId);
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Persona eliminada')),
          );
        }
      } catch (e, st) {
        debugLog('Error al eliminar persona', e, st);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyError(e)),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_state.dart';
import '../app_config.dart';
import '../models/person.dart';
import '../services/firestore_service.dart';
import '../services/group_validation_service.dart';
import '../services/notification_service.dart';
import '../utils/app_error.dart';

class PersonFormScreen extends StatefulWidget {
  final String? personId;

  const PersonFormScreen({super.key, this.personId});

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestore = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  bool _loading = false;
  bool _isEdit = false;

  // Campo grupo: cargado dinámicamente desde Firestore (con fast-path local).
  List<String> _availableGroups = [];

  late String nombreApellidos;
  late String direccion;
  late String telefono;
  late String edad;
  late String genero;
  late String aQueSeDedica;
  late String esCristianoOAsisteIglesia;
  late String quiereRecibirVisitas;
  late List<String> vicios;
  late String enfermedadMental;
  late String enfermedadCronica;
  late int nivelComplejidad;
  late String grupo;
  late String comentarios;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.personId != null;
    final profile = currentUserProfile;
    final isAdmin = profile?.isAdmin ?? false;

    nombreApellidos = '';
    direccion = '';
    telefono = '';
    edad = '';
    genero = genderOptions.first;
    aQueSeDedica = '';
    esCristianoOAsisteIglesia = 'No';
    quiereRecibirVisitas = 'Sí';
    vicios = [];
    enfermedadMental = mentalHealthOptions.first;
    enfermedadCronica = chronicIllnessOptions.first;
    nivelComplejidad = 1;
    grupo = profile?.grupo ?? missionGroups.first;
    comentarios = '';

    // Fast path: use local config immediately so dropdown is ready.
    _availableGroups = isAdmin
        ? missionGroups.where((g) => g != 'ADMINISTRADOR').toList()
        : [profile?.grupo ?? missionGroups.first];

    _loadGroupsFromFirestore();
    if (_isEdit) _loadPerson();
  }

  Future<void> _loadGroupsFromFirestore() async {
    final profile = currentUserProfile;
    if (!(profile?.isAdmin ?? false)) return; // non-admin: local fast path is enough
    try {
      final all = await GroupValidationService().getAllAllowedGroups();
      final groups = all.where((g) => g != 'ADMINISTRADOR').toList();
      if (mounted && groups.isNotEmpty) {
        setState(() {
          _availableGroups = groups;
          if (!groups.contains(grupo)) grupo = groups.first;
        });
      }
    } catch (_) {
      // Keep using local missionGroups on network error.
    }
  }

  Future<void> _loadPerson() async {
    final p = await _firestore.getPerson(widget.personId!);
    if (p != null && mounted) {
      setState(() {
        nombreApellidos = p.nombreApellidos;
        direccion = p.direccion;
        telefono = p.telefono;
        edad = p.edad;
        genero = p.genero;
        aQueSeDedica = p.aQueSeDedica;
        esCristianoOAsisteIglesia = p.esCristianoOAsisteIglesia;
        quiereRecibirVisitas = p.quiereRecibirVisitas;
        vicios = List.from(p.vicios);
        enfermedadMental = mentalHealthOptions.contains(p.enfermedadMental)
            ? p.enfermedadMental
            : mentalHealthOptions.first;
        enfermedadCronica = chronicIllnessOptions.contains(p.enfermedadCronica)
            ? p.enfermedadCronica
            : chronicIllnessOptions.first;
        nivelComplejidad = p.nivelComplejidad;
        grupo = p.grupo;
        comentarios = p.comentarios;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final person = Person(
        id: widget.personId ?? '',
        grupo: grupo.trim().toUpperCase(),
        nombreApellidos: nombreApellidos.trim(),
        direccion: direccion.trim(),
        telefono: telefono.trim(),
        edad: edad.trim(),
        genero: genero,
        aQueSeDedica: aQueSeDedica.trim(),
        esCristianoOAsisteIglesia: esCristianoOAsisteIglesia,
        quiereRecibirVisitas: quiereRecibirVisitas,
        vicios: vicios,
        enfermedadMental: enfermedadMental.trim(),
        enfermedadCronica: enfermedadCronica.trim(),
        nivelComplejidad: nivelComplejidad,
        comentarios: comentarios.trim(),
      );
      final auditName = currentUserProfile?.displayName ??
          currentFirebaseUser?.email ?? '';
      if (_isEdit) {
        await _firestore.updatePerson(person, modifiedBy: auditName);
        await _notificationService.sendSimpleNotification(
          'Persona actualizada',
          '${person.nombreApellidos} ha sido actualizada',
        );
      } else {
        await _firestore.addPerson(person, createdBy: auditName);
        await _notificationService.sendSimpleNotification(
          'Nueva persona agregada',
          '${person.nombreApellidos} ha sido registrada',
        );
      }
      if (mounted) {
        if (_isEdit) {
          context.pop();
        } else {
          context.go('/home');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Actualizado' : 'Persona agregada')),
        );
      }
    } catch (e, st) {
      debugLog('Error al guardar persona', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar persona' : 'Nueva persona'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    initialValue: nombreApellidos,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y apellidos',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                    onChanged: (v) => nombreApellidos = v,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: direccion,
                    decoration: const InputDecoration(
                        labelText: 'Dirección', border: OutlineInputBorder()),
                    maxLength: 200,
                    onChanged: (v) => direccion = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: telefono,
                    decoration: const InputDecoration(
                        labelText: 'Teléfono', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    onChanged: (v) => telefono = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: edad,
                    decoration: const InputDecoration(
                        labelText: 'Edad', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    onChanged: (v) => edad = v,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1 || n > 120) {
                        return 'Edad inválida (1–120)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: genero,
                    decoration: const InputDecoration(
                        labelText: 'Género', border: OutlineInputBorder()),
                    items: genderOptions
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => setState(() => genero = v ?? genero),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: aQueSeDedica,
                    decoration: const InputDecoration(
                      labelText: 'A qué se dedica',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 150,
                    onChanged: (v) => aQueSeDedica = v,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: esCristianoOAsisteIglesia.isEmpty
                        ? 'No'
                        : esCristianoOAsisteIglesia,
                    decoration: const InputDecoration(
                      labelText: '¿Es cristiano o asiste a una iglesia?',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Sí', 'No']
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => esCristianoOAsisteIglesia = v ?? 'No'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: quiereRecibirVisitas.isEmpty
                        ? 'Sí'
                        : quiereRecibirVisitas,
                    decoration: const InputDecoration(
                      labelText: '¿Quiere recibir visitas?',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Sí', 'No', 'A veces']
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => quiereRecibirVisitas = v ?? 'Sí'),
                  ),
                  const SizedBox(height: 12),
                  _viciosField(),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: mentalHealthOptions.contains(enfermedadMental)
                        ? enfermedadMental
                        : mentalHealthOptions.first,
                    decoration: const InputDecoration(
                      labelText: 'Enfermedad mental declarada',
                      border: OutlineInputBorder(),
                    ),
                    items: mentalHealthOptions
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => enfermedadMental = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: chronicIllnessOptions.contains(enfermedadCronica)
                        ? enfermedadCronica
                        : chronicIllnessOptions.first,
                    decoration: const InputDecoration(
                      labelText: 'Enfermedad crónica',
                      border: OutlineInputBorder(),
                    ),
                    items: chronicIllnessOptions
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => enfermedadCronica = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Complejidad (1-7): '),
                      Expanded(
                        child: Slider(
                          value: nivelComplejidad.toDouble(),
                          min: 1,
                          max: 7,
                          divisions: 6,
                          label: '$nivelComplejidad',
                          onChanged: (v) =>
                              setState(() => nivelComplejidad = v.toInt()),
                        ),
                      ),
                      Text('$nivelComplejidad'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Admin: dropdown con todos los grupos.
                  // No-admin: texto de solo lectura (no expone lista de grupos).
                  if (currentUserProfile?.isAdmin ?? false)
                    DropdownButtonFormField<String>(
                      value: _availableGroups.contains(grupo)
                          ? grupo
                          : (_availableGroups.isNotEmpty
                              ? _availableGroups.first
                              : null),
                      decoration: const InputDecoration(
                        labelText: 'Grupo de misión',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableGroups
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => grupo = v ?? grupo),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    )
                  else
                    TextFormField(
                      initialValue: grupo,
                      decoration: const InputDecoration(
                        labelText: 'Grupo de misión',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      enabled: false,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: comentarios,
                    decoration: const InputDecoration(
                      labelText: 'Comentarios',
                      hintText: 'Notas adicionales (opcional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 1000,
                    onChanged: (v) => comentarios = v,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(_isEdit ? 'Guardar cambios' : 'Agregar persona'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _viciosField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Vicios (varios)',
        border: OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 8,
        children: viceOptions.map((opt) {
          final selected = vicios.contains(opt);
          return FilterChip(
            label: Text(opt),
            selected: selected,
            onSelected: (v) {
              setState(() {
                if (v) {
                  vicios.add(opt);
                } else {
                  vicios.remove(opt);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

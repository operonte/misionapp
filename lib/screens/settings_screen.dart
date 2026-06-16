import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_state.dart';
import '../app_config.dart';
import '../app_themes.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/group_validation_service.dart';
import '../services/export_service.dart';
import '../utils/app_error.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  bool _loading = false;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  // Admin: dropdown with all groups.
  List<String> _allowedGroups = missionGroups;
  String? _selectedGroup;
  // Non-admin: free text field (doesn't expose group list).
  late TextEditingController _grupoController;

  @override
  void initState() {
    super.initState();
    final p = currentUserProfile;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _apellidoController = TextEditingController(text: p?.apellido ?? '');
    _grupoController = TextEditingController(text: p?.grupo ?? '');
    _selectedGroup = p?.grupo;
    // Only load group list for admin — non-admin uses a text field.
    if (p?.isAdmin ?? false) _loadAllowedGroups();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _grupoController.dispose();
    super.dispose();
  }

  Future<void> _loadAllowedGroups() async {
    try {
      final groups = await GroupValidationService().getAllAllowedGroups();
      if (mounted && groups.isNotEmpty) {
        setState(() {
          _allowedGroups = groups;
          if (_selectedGroup != null &&
              !_allowedGroups.contains(_selectedGroup)) {
            _selectedGroup = _allowedGroups.first;
          }
        });
      }
    } catch (_) {
      // Keep using local missionGroups.
    }
  }

  Future<void> _saveProfile() async {
    final user = currentFirebaseUser;
    if (user == null) return;

    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }
    final isAdmin = currentUserProfile?.isAdmin ?? false;
    String grupoFinal;
    if (isAdmin) {
      if (_selectedGroup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un grupo')),
        );
        return;
      }
      grupoFinal = _selectedGroup!;
    } else {
      final typed = _grupoController.text.trim().toUpperCase();
      if (typed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El grupo es requerido')),
        );
        return;
      }
      final valid = await GroupValidationService().validateGroupName(typed);
      if (!valid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Grupo no reconocido. Verifica el nombre con tu líder.')),
          );
        }
        return;
      }
      grupoFinal = typed;
    }

    setState(() => _loading = true);
    try {
      final profile =
          (currentUserProfile ?? await _firestore.getUserProfile(user.uid))!;
      final updated = profile.copyWith(
        nombre: nombre,
        apellido: _apellidoController.text.trim(),
        grupo: grupoFinal,
      );

      await _auth.updateUserProfile(updated);
      currentUserProfile = updated;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e, st) {
      debugLog('Error al guardar perfil', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _loading = true);
    try {
      final path = await ExportService().exportToExcel(_firestore);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                path != null ? 'Exportado correctamente' : 'No hay datos para exportar'),
          ),
        );
      }
    } catch (e, st) {
      debugLog('Error al exportar', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = currentUserProfile;
    final isAdmin = profile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Tu perfil',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 12),
                if (isAdmin)
                  DropdownButtonFormField<String>(
                    value: _allowedGroups.contains(_selectedGroup)
                        ? _selectedGroup
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Grupo de misión',
                      border: OutlineInputBorder(),
                    ),
                    items: _allowedGroups
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGroup = v),
                  )
                else
                  TextField(
                    controller: _grupoController,
                    decoration: const InputDecoration(
                      labelText: 'Grupo de misión',
                      hintText: 'Ingresa el nombre de tu grupo',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 50,
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saveProfile,
                  child: const Text('Guardar perfil'),
                ),
                const SizedBox(height: 32),
                const Text('Apariencia',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const _ThemePicker(),
                const SizedBox(height: 32),
                const Text('Información',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de'),
                  onTap: () => context.push('/about'),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Contacto'),
                  onTap: () => context.push('/contact'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Política de privacidad'),
                  onTap: () => context.push('/privacy'),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Términos de uso'),
                  onTap: () => context.push('/terms'),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  const Text('Administrador',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: const Text('Estadísticas'),
                    onTap: () => context.push('/stats'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.table_chart_outlined),
                    title: const Text('Exportar a Excel'),
                    onTap: _exportExcel,
                  ),
                ],
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar sesión'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await _auth.signOut();
                    currentUserProfile = null;
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
    );
  }
}

/// Muestra los 4 círculos de paleta. Actualiza el tema en tiempo real.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeIndexNotifier,
      builder: (context, current, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(appPalettes.length, (i) {
            final palette = appPalettes[i];
            final selected = i == current;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () async {
                  themeIndexNotifier.value = i;
                  await appStorage.setThemeIndex(i);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.seed,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : Border.all(color: Colors.transparent, width: 3),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: palette.seed.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      palette.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

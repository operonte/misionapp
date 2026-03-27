import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_state.dart';
import '../app_config.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/group_validation_service.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();
  final GroupValidationService _groupValidation = GroupValidationService();
  bool _loading = false;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _grupoController;
  List<String> _allowedGroups = [];
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    final p = currentUserProfile;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _apellidoController = TextEditingController(text: p?.apellido ?? '');
    _grupoController = TextEditingController(text: p?.grupo ?? '');
    _selectedGroup = p?.grupo;
    _loadAllowedGroups();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _grupoController.dispose();
    super.dispose();
  }

  Future<void> _loadAllowedGroups() async {
    final groups = await _groupValidation.getAllAllowedGroups();
    setState(() {
      _allowedGroups = groups;
      if (!_allowedGroups.contains(_selectedGroup) && _selectedGroup != null) {
        _selectedGroup = _allowedGroups.first;
      }
    });
  }

  Future<void> _saveProfile() async {
    final user = currentFirebaseUser;
    if (user == null) return;
    
    final grupoText = _grupoController.text.trim();
    if (grupoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes escribir un grupo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!missionGroups.contains(grupoText.toUpperCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('escribiste mal el grupo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final profile = (currentUserProfile ?? await _firestore.getUserProfile(user.uid))!;
      final updated = profile.copyWith(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        grupo: grupoText.toUpperCase(),
      );
      
      await _auth.updateUserProfile(updated);
      currentUserProfile = updated;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exportado: $path')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al exportar')),
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
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _grupoController,
                  decoration: const InputDecoration(
                    labelText: 'Grupo de misión',
                    hintText: 'Escribe el nombre del grupo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saveProfile,
                  child: const Text('Guardar perfil'),
                ),
                const SizedBox(height: 32),
                const Text('Información',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

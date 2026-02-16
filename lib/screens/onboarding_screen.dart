import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_state.dart';

/// Onboarding de 5 pantallas: lista, agregar persona, visitas, configuración, listo.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  Future<void> _finish() async {
    await appStorage.setOnboardingDone(true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  _Page(
                    icon: Icons.people_outline,
                    title: 'Tu grupo',
                    body: 'Aquí ves las personas de tu grupo de misión.',
                  ),
                  _Page(
                    icon: Icons.person_add_outlined,
                    title: 'Agregar personas',
                    body: 'Registra a cada persona con sus datos y su grupo.',
                  ),
                  _Page(
                    icon: Icons.event_note_outlined,
                    title: 'Registrar visitas',
                    body: 'Cada visita queda registrada con fecha y contenido para todos.',
                  ),
                  _Page(
                    icon: Icons.tune,
                    title: 'Ordenar y filtrar',
                    body: 'Ordena por nombre o última visita. Filtra y busca por nombre.',
                  ),
                  _Page(
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    body: 'Define tu nombre, apellidos y grupo en Ajustes.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: List.generate(_totalPages, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == i
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < _totalPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(
                        _currentPage < _totalPages - 1 ? 'Siguiente' : 'Empezar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Page(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

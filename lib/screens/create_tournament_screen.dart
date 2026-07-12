import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tournament_store.dart';
import 'registration_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _nameController = TextEditingController();
  int _duration = 35;
  final _formKey = GlobalKey<FormState>();

  static const _presets = [25, 35, 45];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<TournamentStore>();
    final tournament = await store.createTournament(
      name: _nameController.text.trim(),
      matchDurationMinutes: _duration,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RegistrationScreen(tournamentId: tournament.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau tournoi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset('assets/logo/capfun_petanque_icon.png', width: 52, height: 52),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Un nouveau tournoi de pétanque en 3 rounds !',
                      style: TextStyle(fontSize: 15, color: scheme.onSurface.withValues(alpha: 0.75)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du tournoi',
                  prefixIcon: Icon(Icons.emoji_events_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 28),
              Text('DURÉE MAXIMUM PAR MATCH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  )),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: Column(
                    children: [
                      Text(
                        '$_duration min',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: scheme.primary),
                      ),
                      Slider(
                        value: _duration.toDouble(),
                        min: 10,
                        max: 60,
                        divisions: 50,
                        label: '$_duration min',
                        onChanged: (v) => setState(() => _duration = v.round()),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final preset in _presets)
                              ChoiceChip(
                                label: Text('$preset min'),
                                selected: _duration == preset,
                                onSelected: (_) => setState(() => _duration = preset),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.check),
                label: const Text('Créer et inscrire les équipes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

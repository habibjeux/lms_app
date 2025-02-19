import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/modules_provider.dart';
import '../widgets/module_card.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les modules au démarrage
    Future.microtask(
      () => context.read<ModulesProvider>().loadModules(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes modules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ModulesProvider>().refreshModules(),
          ),
        ],
      ),
      body: Consumer<ModulesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.loadModules(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.modules.isEmpty) {
            return const Center(
              child: Text('Aucun module disponible'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshModules(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.modules.length,
              itemBuilder: (context, index) {
                final module = provider.modules[index];
                return ModuleCard(
                  module: module,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/module-detail',
                    arguments: module,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

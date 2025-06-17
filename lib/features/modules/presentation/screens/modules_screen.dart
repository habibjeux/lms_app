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
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Charger les modules au démarrage
    Future.microtask(
      () => context.read<ModulesProvider>().loadModules(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ModulesProvider>();
      if (provider.hasMorePages && !provider.isLoading) {
        provider.loadModules();
      }
    }
  }

  void _onSearch(String query) {
    context.read<ModulesProvider>().searchModules(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un module...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : const Text('Mes modules'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _onSearch('');
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<ModulesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.modules.isEmpty) {
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
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  provider.modules.length + (provider.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.modules.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

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

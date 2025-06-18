import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
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
  final _searchFocusNode = FocusNode();

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
    _searchFocusNode.dispose();
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

  void _clearSearch() {
    _searchController.clear();
    _onSearch('');
    // Maintenir le focus pour garder le clavier ouvert
    setState(() {});
  }

  Widget _buildWelcomeHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        final now = DateTime.now();
        final hour = now.hour;

        String greeting;
        if (hour < 12) {
          greeting = 'Bonjour';
        } else if (hour < 18) {
          greeting = 'Bon après-midi';
        } else {
          greeting = 'Bonsoir';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, ${user?.firstName ?? 'Étudiant'}! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Continuez votre apprentissage avec vos modules',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Déclencher la recherche quand on clique sur l'icône
              _onSearch(_searchController.text);
            },
            child: Icon(
              Icons.search,
              color: Colors.grey[500],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted:
                  _onSearch, // Recherche seulement quand on appuie sur "Rechercher"
              decoration: const InputDecoration(
                hintText: 'Rechercher un module...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40, // Réduire la hauteur de l'AppBar
      ),
      body: Consumer<ModulesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.modules.isEmpty) {
            return Column(
              children: [
                _buildWelcomeHeader(),
                _buildSearchBar(),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }

          if (provider.error != null) {
            return Column(
              children: [
                _buildWelcomeHeader(),
                _buildSearchBar(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Oops! Une erreur s\'est produite',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => provider.loadModules(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (provider.modules.isEmpty) {
            return Column(
              children: [
                _buildWelcomeHeader(),
                _buildSearchBar(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun module disponible',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vous n\'avez pas encore de modules assignés',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return GestureDetector(
            onTap: () {
              // Ne pas fermer le clavier quand on touche à l'extérieur
              // L'utilisateur peut fermer manuellement le clavier
            },
            child: RefreshIndicator(
              onRefresh: () => provider.refreshModules(),
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildWelcomeHeader(),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${provider.modules.length} module${provider.modules.length > 1 ? 's' : ''}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == provider.modules.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final module = provider.modules[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ModuleCard(
                            module: module,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/module-detail',
                              arguments: module,
                            ),
                          ),
                        );
                      },
                      childCount: provider.modules.length +
                          (provider.hasMorePages ? 1 : 0),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

//Lucas Lima Silva Nº16
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PokedexScreen(),
    );
  }
}

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _pokemonList = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSearchResult = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialPokemon();
  }

  Future<void> _fetchInitialPokemon() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSearchResult = false;
    });

    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=20'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        
        List<dynamic> detailedList = [];
        for (var item in results) {
          final detailResponse = await http.get(Uri.parse(item['url']));
          if (detailResponse.statusCode == 200) {
            detailedList.add(json.decode(detailResponse.body));
          }
        }

        setState(() {
          _pokemonList = detailedList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar dados do servidor.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Dispositivo offline ou erro de conexão.';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPokemon() async {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      _fetchInitialPokemon();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pokemonList = [data];
          _isSearchResult = true;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Pokémon não encontrado.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao buscar Pokémon.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Dispositivo offline ou erro de conexão.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar Pokémon por Nome ou ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searchPokemon,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage,
                                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                              if (_isSearchResult || _pokemonList.isEmpty) ...[
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchInitialPokemon();
                                  },
                                  child: const Text('Voltar para a Lista Inicial'),
                                ),
                              ]
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _pokemonList.length,
                          itemBuilder: (context, index) {
                            final pokemon = _pokemonList[index];
                            final id = pokemon['id'];
                            final name = pokemon['name'].toString().toUpperCase();
                            final imageUrl = pokemon['sprites']['front_default'] ?? '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : const Icon(Icons.image_not_supported),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Nº #$id'),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
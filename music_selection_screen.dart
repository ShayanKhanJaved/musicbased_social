
import 'package:cameosky/models/user_model.dart';
import 'package:cameosky/providers/auth_provider.dart';
import 'package:cameosky/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class MusicSelectionScreen extends StatefulWidget {
  const MusicSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Artist> _searchResults = [];
  List<Artist> _selectedArtists = [];
  
  Future<void> _searchArtists(String query) async {
    try {
      // This would use the Spotify Web API in a real implementation
      // For now, we'll mock it
      if (query.isNotEmpty) {
        setState(() {
          _searchResults = [
            Artist(id: '1', name: '$query Artist 1', imageUrl: '', genres: ['Pop']),
            Artist(id: '2', name: '$query Artist 2', imageUrl: '', genres: ['Rock']),
          ];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching artists: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedArtists.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least 5 artists')),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.updateUserMusicTastes(
      _selectedArtists.map((a) => a.name).toList()
    );
    
    if (success) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlack, AppTheme.secondaryBlack],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Select Your Top 5 Artists',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search artists...',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () => _searchArtists(_searchController.text),
                      ),
                    ),
                    onSubmitted: _searchArtists,
                  ),
                ),
                const SizedBox(height: 20),
                if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final artist = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: artist.imageUrl.isNotEmpty 
                                ? NetworkImage(artist.imageUrl)
                                : null,
                            child: artist.imageUrl.isEmpty 
                                ? Icon(Icons.music_note)
                                : null,
                          ),
                          title: Text(artist.name),
                          subtitle: Text(artist.genres.join(', ')),
                          trailing: _selectedArtists.contains(artist)
                              ? Icon(Icons.check_circle, color: AppTheme.successColor)
                              : null,
                          onTap: () {
                            setState(() {
                              if (_selectedArtists.contains(artist)) {
                                _selectedArtists.remove(artist);
                              } else if (_selectedArtists.length < 5) {
                                _selectedArtists.add(artist);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: _selectedArtists.map((artist) {
                    return Chip(
                      label: Text(artist.name),
                      onDeleted: () {
                        setState(() => _selectedArtists.remove(artist));
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saveSelection,
                  child: Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _likeAnimationController;
  late AnimationController _dislikeAnimationController;
  
  late Animation<double> _cardAnimation;
  late Animation<double> _likeAnimation;
  late Animation<double> _dislikeAnimation;
  
  bool _showLikeIcon = false;
  bool _showDislikeIcon = false;
  bool _showMessageDialog = false;

  @override
  void initState() {
    super.initState();
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _dislikeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOut),
    );
    
    _likeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
    
    _dislikeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dislikeAnimationController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadCurrentUser();
    await userProvider.loadPotentialMatches();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _likeAnimationController.dispose();
    _dislikeAnimationController.dispose();
    super.dispose();
  }

  void _onCardSwiped(UserModel user, bool liked) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (liked) {
      setState(() => _showLikeIcon = true);
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reset();
        setState(() => _showLikeIcon = false);
      });
      
      // Show option to add message
      _showMessageDialog = true;
      _showAddMessageDialog(user);
    } else {
      setState(() => _showDislikeIcon = true);
      _dislikeAnimationController.forward().then((_) {
        _dislikeAnimationController.reset();
        setState(() => _showDislikeIcon = false);
      });
      
      await userProvider.dislikeUser(user.uid);
    }
  }

  void _showAddMessageDialog(UserModel user) {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send a message?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Add a personal message (250 gems) or send without message (100 gems)',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: messageController,
                maxLines: 3,
                maxLength: 100,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _sendLike(user, null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlack,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Send'),
                          Text(
                            '100 gems',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: messageController.text.trim().isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _sendLike(user, messageController.text.trim());
                            },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Send + Message'),
                          Text(
                            '250 gems',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendLike(UserModel user, String? message) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool success = await userProvider.likeUser(user.uid, message: message);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Failed to send like'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlack,
              AppTheme.secondaryBlack,
              AppTheme.primaryBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              if (userProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (userProvider.potentialMatches.isEmpty) {
                return _buildNoMoreProfilesView();
              }

              return Column(
                children: [
                  _buildTopBar(userProvider),
                  Expanded(
                    child: _buildCardStack(userProvider),
                  ),
                  _buildBottomActions(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.diamond,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${userProvider.currentUser?.gems ?? 0}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showWatchAdDialog(),
            icon: GlassContainer(
              width: 48,
              height: 48,
              padding: EdgeInsets.zero,
              child: Icon(
                Icons.play_circle_fill,
                color: AppTheme.successColor,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(UserProvider userProvider) {
    final users = userProvider.potentialMatches;
    
    return Stack(
      children: [
        if (_showLikeIcon)
          Center(
            child: AnimatedBuilder(
              animation: _likeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _likeAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ),
        
        if (_showDislikeIcon)
          Center(
            child: AnimatedBuilder(
              animation: _dislikeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _dislikeAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ),
        
        for (int i = math.min(users.length - 1, 2); i >= 0; i--)
          _buildUserCard(users[i], i),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, int index) {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20 + (index * 4.0),
          right: 20 + (index * 4.0),
          top: 20 + (index * 8.0),
          bottom: 120,
        ),
        child: GestureDetector(
          onPanEnd: index == 0 ? (details) {
            if (details.velocity.pixelsPerSecond.dx > 300) {
              _onCardSwiped(user, true);
            } else if (details.velocity.pixelsPerSecond.dx < -300) {
              _onCardSwiped(user, false);
            }
          } : null,
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Profile Image Background
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accentColor,
                          AppTheme.secondaryBlack,
                        ],
                      ),
                    ),
                    child: user.profileImageUrl.isNotEmpty
                        ? Image.network(
                            user.profileImageUrl,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              Icons.person,
                              size: 100,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                  ),
                  
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          AppTheme.primaryBlack.withOpacity(0.8),
                          AppTheme.primaryBlack,
                        ],
                      ),
                    ),
                  ),
                  
                  // User Info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${user.age}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            user.bio,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          if (user.favoriteArtists.isNotEmpty) ...[
                            Text(
                              'Favorite Artists:',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: user.favoriteArtists.take(3).map((artist) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    artist,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: AppTheme.errorColor,
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              if (userProvider.potentialMatches.isNotEmpty) {
                _onCardSwiped(userProvider.potentialMatches.first, false);
              }
            },
          ),
          _buildActionButton(
            icon: Icons.favorite,
            color: AppTheme.successColor,
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              if (userProvider.potentialMatches.isNotEmpty) {
                _onCardSwiped(userProvider.potentialMatches.first, true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildNoMoreProfilesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No more profiles',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Check back later for new people!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _loadData(),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showWatchAdDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_fill,
                size: 64,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Watch Ad for Gems',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Watch a short video to earn 250 gems!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlack,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _watchAd();
                      },
                      child: const Text('Watch Ad'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _watchAd() async {
    // TODO: Implement actual ad watching with Google AdMob
    // For now, simulate watching ad
    await Future.delayed(const Duration(seconds: 2));
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.addGemsFromAd();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You earned 250 gems!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
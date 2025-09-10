import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'categories_screen.dart';
import 'chat_page.dart';
import 'notifications_screen.dart';
import 'my_tips_page.dart';
import 'edit_profile_screen.dart';
import '../services/wallet_service.dart';
import '../services/group_service.dart';
import '../services/websocket_service.dart';
import '../services/deeplink_service.dart';
import '../models/user.dart';
import '../models/group.dart';

class HomePage extends StatefulWidget {
  final GoogleSignInAccount user;
  
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _walletAddress;
  String? _privateKey;
  bool _isLoadingWallet = false;
  late TabController _tabController;
  bool _isPrivateKeyCopied = false;
  List<Group> _userGroups = [];
  bool _isLoadingGroups = false;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWalletData();
    _loadUserGroups();
    _connectWebSocket();
    _initializeDeeplinks();
  }

  void _initializeDeeplinks() {
    // Initialize deeplink service with current user context
    final currentUser = User(
      email: widget.user.email,
      name: widget.user.displayName ?? 'User',
      profilePicture: widget.user.photoUrl,
    );
    
    DeeplinkService().initialize(context, currentUser);
  }

  void _connectWebSocket() async {
    final wsService = WebSocketService.getInstance();
    if (!wsService.isConnected) {
      try {
        await wsService.connect(widget.user.email);
      } catch (e) {
        print('❌ WebSocket connection failed: $e');
        // Don't show error to user immediately, let them use the app without real-time features
        // The WebSocket will retry automatically in the background
      }
    }
    // Clear current group ID when on home screen so notifications can show
    wsService.clearCurrentGroupId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadWalletData() async {
    setState(() {
      _isLoadingWallet = true;
    });
    
    final walletData = await WalletService.getStoredWalletData();
    
    setState(() {
      _walletAddress = walletData?.walletAddress;
      _privateKey = walletData?.privateKey;
      _isLoadingWallet = false;
    });
  }

  void _loadUserGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });
    
    final groups = await GroupService.getUserGroups(widget.user.email);
    
    setState(() {
      _userGroups = groups;
      _isLoadingGroups = false;
    });
  }

  String _formatWalletAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _copyWalletAddress() async {
    if (_walletAddress != null) {
      await Clipboard.setData(ClipboardData(text: _walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet address copied to clipboard'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'computer':
        return Icons.computer;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'music_note':
        return Icons.music_note;
      case 'palette':
        return Icons.palette;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'business':
        return Icons.business;
      case 'school':
        return Icons.school;
      default:
        return Icons.group;
    }
  }

  String _getIconString(IconData icon) {
    if (icon == Icons.flutter_dash) return 'computer';
    if (icon == Icons.rocket_launch) return 'business';
    if (icon == Icons.design_services) return 'palette';
    return 'group';
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  String _getColorString(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),
            
            // Tab Bar
            _buildTabBar(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGlobalGroupsTab(),
                  _buildPrivateGroupsTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton(
              onPressed: () => _showCreateGroupDialog(context),
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 2),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1), width: 2),
              ),
              child: ClipOval(
                child: widget.user.photoUrl != null
                    ? Image.network(
                        widget.user.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.person, color: Colors.white70),
                      )
                    : const Icon(Icons.person, color: Colors.white70),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.user.displayName?.split(' ').first ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Notifications
          GestureDetector(
            onTap: () => _navigateToNotifications(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() => _selectedIndex = index),
        indicator: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Global'),
          Tab(text: 'Private'),
          Tab(text: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildGlobalGroupsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search global groups...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Categories
          Text(
            'Categories',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryCard('Technology', Icons.computer, const Color(0xFF6366F1)),
                _buildCategoryCard('Gaming', Icons.sports_esports, const Color(0xFF8B5CF6)),
                _buildCategoryCard('Music', Icons.music_note, const Color(0xFFEC4899)),
                _buildCategoryCard('Art', Icons.palette, const Color(0xFFF59E0B)),
                _buildCategoryCard('Sports', Icons.sports_soccer, const Color(0xFF10B981)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Popular Groups
          Text(
            'Popular Groups',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Popular Global Groups - accessible to everyone
          _buildGlobalGroupCard(
            'Programming & Development',
            'Share code, ask questions, and discuss programming topics',
            '12.5k members',
            Icons.code,
            const Color(0xFF10B981),
            groupId: 2, // Real group ID
          ),
          _buildGlobalGroupCard(
            'Startup Founders',
            'Connect with entrepreneurs worldwide',
            '8.2k members',
            Icons.business,
            const Color(0xFF6366F1),
            groupId: 30, // Real group ID
          ),
          _buildGlobalGroupCard(
            'Digital Art',
            'Share digital artwork, illustrations, and designs',
            '15.1k members',
            Icons.palette,
            const Color(0xFFEC4899),
            groupId: 13, // Real group ID
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateGroupsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Group Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.group_add,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create Private Group',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite friends and start your own community',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // My Groups
          Text(
            'My Groups',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User Groups
          if (_isLoadingGroups)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_userGroups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first group to start chatting with friends!',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._userGroups.map((group) => GestureDetector(
              onTap: () => _navigateToGroupChat(context, group),
              child: _buildGroupCard(
                group.name,
                group.description.isNotEmpty ? group.description : 'Private group',
                '1 member', // TODO: Get actual member count
                _getIconFromString(group.icon),
                _getColorFromString(group.color),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: widget.user.photoUrl != null
                      ? NetworkImage(widget.user.photoUrl!)
                      : null,
                  child: widget.user.photoUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white70)
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.user.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                // Wallet Address Display
                if (_isLoadingWallet)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  )
                else if (_walletAddress != null)
                  GestureDetector(
                    onTap: _copyWalletAddress,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: const Color(0xFF6366F1),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatWalletAddress(_walletAddress!),
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy,
                            color: Colors.grey[400],
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      'No wallet found',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToUserProfile(context),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToMyTips(context),
                        icon: const Icon(Icons.attach_money, size: 18),
                        label: const Text('My Tips'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Settings Options
          _buildExportPrivateKeyOption(),
          _buildSettingsOption(Icons.notifications, 'Notifications', 'Manage your notifications'),
          _buildSettingsOption(Icons.privacy_tip, 'Privacy', 'Control your privacy settings'),
          _buildSettingsOption(Icons.help, 'Help & Support', 'Get help and support'),
          _buildSettingsOption(Icons.info, 'About', 'Learn more about Pally'),
          
          const SizedBox(height: 24),
          
          // Sign Out Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: TextButton.icon(
            onPressed: () async {
                try {
                  // Sign out from Google
              await GoogleSignIn.instance.signOut();
                  
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                } catch (error) {
                  debugPrint('Sign out failed: $error');
                  // Still navigate back even if sign out fails
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _navigateToCategory(context, title, icon, color),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(String title, String description, String members, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  members,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[600],
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalGroupCard(String title, String description, String members, IconData icon, Color color, {required int groupId}) {
    // Create a real group object for global groups
    final globalGroup = Group(
      id: groupId,
      name: title,
      description: description,
      category: 'Global',
      icon: _getIconString(icon),
      color: _getColorString(color),
      isPrivate: false,
      createdBy: 'system',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return GestureDetector(
      onTap: () => _navigateToGroupChat(context, globalGroup),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    members,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportPrivateKeyOption() {
    return GestureDetector(
      onTap: _copyPrivateKey,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.vpn_key,
              color: Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Private Key',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Backup your wallet private key',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isPrivateKeyCopied ? Icons.check : Icons.copy,
              color: _isPrivateKeyCopied ? const Color(0xFF10B981) : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
                color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(BuildContext context, String categoryName, IconData categoryIcon, Color categoryColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriesScreen(
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          userEmail: widget.user.email,
        ),
      ),
    );
  }


  void _navigateToGroupChat(BuildContext context, Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          group: group,
          userEmail: widget.user.email,
        ),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userName: widget.user.displayName ?? 'User',
          userEmail: widget.user.email,
          userPhotoUrl: widget.user.photoUrl,
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedCategory = 'General';

    final List<Map<String, dynamic>> categories = [
      {'name': 'General', 'icon': Icons.group, 'color': const Color(0xFF6366F1)},
      {'name': 'Technology', 'icon': Icons.computer, 'color': const Color(0xFF10B981)},
      {'name': 'Gaming', 'icon': Icons.sports_esports, 'color': const Color(0xFFF59E0B)},
      {'name': 'Music', 'icon': Icons.music_note, 'color': const Color(0xFFEF4444)},
      {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': const Color(0xFF8B5CF6)},
      {'name': 'Art', 'icon': Icons.palette, 'color': const Color(0xFFEC4899)},
      {'name': 'Business', 'icon': Icons.business, 'color': const Color(0xFF06B6D4)},
      {'name': 'Education', 'icon': Icons.school, 'color': const Color(0xFF84CC16)},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Create Private Group',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
                items: categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'] as String,
                    child: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          color: category['color'] as Color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(category['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Create group
                final response = await GroupService.createGroup(
                  name: nameController.text,
                  description: descriptionController.text,
                  category: selectedCategory,
                  icon: categories.firstWhere((cat) => cat['name'] == selectedCategory)['icon'].toString(),
                  color: categories.firstWhere((cat) => cat['name'] == selectedCategory)['color'].toString(),
                  isPrivate: true,
                  userEmail: widget.user.email,
                );

                // Hide loading
                Navigator.pop(context);

                if (response != null && response.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created "${nameController.text}" group successfully!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  
                  // Reload groups
                  _loadUserGroups();
                  
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create group: ${response?.message ?? "Unknown error"}'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _navigateToMyTips(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyTipsPage(),
      ),
    );
  }

  void _copyPrivateKey() async {
    print('🔑 Copy private key requested');
    print('🔑 Private key available: ${_privateKey != null}');
    
    if (_privateKey == null || _privateKey!.isEmpty) {
      print('❌ No private key found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No private key found. Please sign in again.'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    print('✅ Copying private key to clipboard');
    await Clipboard.setData(ClipboardData(text: _privateKey!));
    
    setState(() {
      _isPrivateKeyCopied = true;
    });
    
    // Show toast message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Private key copied to clipboard'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Reset the icon after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isPrivateKeyCopied = false;
        });
      }
    });
  }
}

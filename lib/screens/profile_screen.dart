import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../core/unified_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPasswordFields = false;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  static const Map<String, List<String>> _avatarCategories = {
    'Attack on Titan': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305975/AOT_8_rosy3h.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305974/AOT_7_fi7vm2.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305972/AOT_6_e0mv9u.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305971/AOT_5_hiilfv.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305966/AOT_4_xpdk1j.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305964/AOT_3_yzbt3z.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305963/AOT_2_ckl2ob.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305962/AOT_1_mdihwv.jpg",
    ],
    'Black Clover': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771306008/black_clover_9_v8bz3c.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771306006/black_clover_8_uzmsgl.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771306004/black_clover_7_osasw9.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771306003/black_clover_6_umw01k.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771306001/black_clover_5_jgyjr2.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305999/black_clover_4_bufkt4.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305998/black_clover_3_q80tt1.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305996/black_clover_2_ukhyl7.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305995/black_clover_1_qeixwd.jpg",
    ],
    'Hunter X Hunter': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305941/HxH_9_lrpfsv.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305939/HxH_8_xbzwqe.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305938/HxH_7_mio00j.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305938/HxH_6_gtcbdk.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305933/HxH_5_getle5.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305932/HxH_4_fgmafa.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305930/HxH_3_icg41j.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305929/HxH_2_l02jqp.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305928/HxH_1_nbgqqv.jpg",
    ],
    'JJK': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305912/jjk_13_q1gumf.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305912/jjk_12_memp13.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305910/jjk_11_ubttqq.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305909/jjk_10_issnfc.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305907/jjk_9_dwyhne.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305906/jjk_8_dwpdq6.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305905/jjk_7_k8u64m.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305901/jjk_6_njmnut.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305900/jjk_5_dcljbd.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305899/jjk_4_svgcom.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305898/jjk_3_ijtgpz.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305896/jjk_2_a2x9fy.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305896/jjk_1_b6edkk.jpg",
    ],
    'Naruto': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305872/naruto_14_esvija.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305871/naruto_13_ewxrqk.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305871/naruto_12_v3821m.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305867/naruto_11_qrz21i.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305866/naruto_10_qxf3d8.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305865/naruto_9_kaisse.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305863/naruto_8_aucmm9.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305862/naruto_7_ofhb08.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305862/naruto_6_d5jobr.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305860/naruto_5_w6js8s.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305859/naruto_4_woyide.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305858/naruto_3_u29nrx.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305858/naruto_2_qvjqda.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305857/naruto_1_lkdowq.jpg",
    ],
    'One Piece': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305833/one_piece_11_itfgms.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305833/one_piece_10_x96js9.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305832/one_piece_9_v2su4x.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305828/one_piece_8_gll46r.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305827/one_piece_7_cbnz6f.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305827/one_piece_6_qppmi2.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305826/one_piece_5_j9b0p3.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305825/one_piece_4_thztao.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305824/one_piece_3_hexrnq.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305823/one_piece_2_eoopdo.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305822/One_piece_1_h3pqrm.jpg",
    ],
    'One Punch Man': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305782/One_punch_man_7_sdhrie.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305781/One_punch_man_6_tkopxv.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305780/One_punch_man_5_puhlw7.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305779/One_punch_man_4_tg9lwb.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305779/One_punch_man_3_iakqih.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305778/One_punch_man_2_ykiuaf.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305778/One_punch_man_1_axnhxj.jpg",
    ],
    'Sakamoto': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305717/Sakamoto_11_fwwwnj.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305716/Sakamoto_10_zdehfh.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305716/Sakamoto_9_en2txg.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305715/Sakamoto_8_yljgtl.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305715/Sakamoto_7_l9mrr1.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305714/Sakamoto_6_qtlldm.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305714/Sakamoto_5_xvwoxr.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305713/Sakamoto_4_qxyl5k.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305713/Sakamoto_3_odbxxm.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305713/Sakamoto_2_yjjipb.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305712/Sakamoto_1_itkrqj.jpg",
    ],
    'Solo Leveling': [
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305667/Solo_leveling_9_xjrpeb.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305667/Solo_leveling_10_iog5de.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305667/Solo_leveling_7_yhtdsd.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305667/Solo_leveling_8_ihfctv.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305666/Solo_leveling_6_w3a02z.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305666/Solo_leveling_4_qihtta.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305666/Solo_leveling_5_jslsde.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305666/Solo_leveling_3_bjil0c.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305666/Solo_leveling_1_o0kupe.jpg",
      "https://res.cloudinary.com/dp1orljzz/image/upload/v1771305666/Solo_leveling_2_nct62k.jpg",
    ]
  };
  String _selectedCategory = 'Attack on Titan';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _usernameController.text = auth.user?['username'] ?? auth.user?['name'] ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleProfileSave() async {
    setState(() {
      _isSavingProfile = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.updateProfile({
        'username': _usernameController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _handlePasswordUpdate() async {
    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
      _isSavingPassword = true;
    });

    final currentPw = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      setState(() {
        _passwordError = 'All password fields are required';
        _isSavingPassword = false;
      });
      return;
    }

    if (newPw.length < 6) {
      setState(() {
        _passwordError = 'New password must be at least 6 characters';
        _isSavingPassword = false;
      });
      return;
    }

    if (newPw != confirmPw) {
      setState(() {
        _passwordError = 'New passwords do not match';
        _isSavingPassword = false;
      });
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await auth.apiClient.dio.post('/auth/reset-password', data: {
        'currentPassword': currentPw,
        'newPassword': newPw,
      });

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _passwordSuccess = response.data['message'] ?? 'Password updated successfully';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _showPasswordFields = false;
        });
      } else {
        setState(() {
          _passwordError = response.data['message'] ?? 'Failed to update password';
        });
      }
    } catch (e) {
      setState(() {
        _passwordError = 'Invalid current password or update failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPassword = false;
        });
      }
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categories = _avatarCategories.keys.toList();
            final items = _avatarCategories[_selectedCategory] ?? [];

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Your Avatar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Categories list (Horizontal scroll)
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                _selectedCategory = cat;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[400],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Avatars grid (Scrollable)
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final url = items[index];
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            final auth = Provider.of<AuthProvider>(this.context, listen: false);
                            await auth.updateProfile({'avatar': url});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(LucideIcons.user, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    String dateStr = '';
    if (user != null && user['createdAt'] != null) {
      try {
        final parsed = DateTime.parse(user['createdAt']);
        dateStr = '${parsed.day}/${parsed.month}/${parsed.year}';
      } catch (e) {
        dateStr = '';
      }
    }

    return UnifiedScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.user, color: Color(0xFF3B82F6), size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Manage your account settings', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Profile Card (Avatar + Email + Username fields)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[850],
                          ),
                          child: user?['avatar'] != null && (user!['avatar'] as String).isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user['avatar'],
                                    width: 108,
                                    height: 108,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, error, stackTrace) => Center(
                                      child: Text(
                                        (user['username'] as String? ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    (user?['username'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAvatarPicker,
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF3B82F6),
                              radius: 18,
                              child: Icon(LucideIcons.camera, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form Fields
                  // Email (Read Only)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Email Address', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: user?['email'] ?? '',
                      prefixIcon: const Icon(LucideIcons.mail, size: 18),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Chip(
                          label: const Text('Verified', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Name (Editable)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Your Name', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Member Since
                  if (dateStr.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Member Since', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      readOnly: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: dateStr,
                        prefixIcon: const Icon(LucideIcons.calendar, size: 18),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  // Expandable Change Password
                  GestureDetector(
                    onTap: () => setState(() => _showPasswordFields = !_showPasswordFields),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.lock, size: 18, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Icon(_showPasswordFields ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (_showPasswordFields) ...[
                    const SizedBox(height: 12),
                    if (_passwordError != null) ...[
                      Text(_passwordError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    if (_passwordSuccess != null) ...[
                      Text(_passwordSuccess!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Current Password',
                        prefixIcon: Icon(LucideIcons.lock, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'New Password',
                        prefixIcon: Icon(LucideIcons.lock, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Confirm New Password',
                        prefixIcon: Icon(LucideIcons.lock, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSavingPassword ? null : _handlePasswordUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        minimumSize: const Size.fromHeight(42),
                      ),
                      child: _isSavingPassword
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Password', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Save Profile Changes Button
                  ElevatedButton(
                    onPressed: _isSavingProfile ? null : _handleProfileSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isSavingProfile
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/post_actions_bottom_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLiked = false;
  int _likesCount = 124;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Stack(
        children: [
          // Background Atmospheric Orbs
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.transparent)),
            ),
          ),
          Positioned(
            bottom: -100, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100), // Space for sticky input
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildPostArticle(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildCommentsSection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Comment Input Footer
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildStickyFooter(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F).withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text('Post', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondaryDark),
                onPressed: () => showPostActions(context, postId: widget.postId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostArticle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1311).withValues(alpha: 0.6),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Info & Featured Badge
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const CircleAvatar(
                        backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuC-2pcdrdfv8AfKOtroWvx0nbWjXEsNlVPywvMXqgHXkWI6dWddepmzdrjYp4vBNLbkrcbJlspB3X2nvz2SVWEaXlO_lUFnBSGf35Qt5JyA5a8J50z2yf1kLGGJao-Ap5vcLeu_7GhcQlJre3m2umcdRvUzEjVPQd2i42k_o-wigkqG4X0I8bZ1kz2gw3Iz9HwpXMjbYhh96ll7N59NUIcSnkkPkkCGyMG7WdV0QZVHsy5VUeeoPt2jRV9mF55vuoKGkqEU3IZGMSI'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Robotics Hub', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('3 hours ago', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('FEATURED', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
          
          // Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDrj0n858AAnKzYzgP7EhceEp6IuZwH2A-ueuqd_AxYj2Fv2JYx-k6ozCJPtt5dIQ0_xdUYXHYV-_bbg5tqzZMLGA6SdFfQ5EORkmT38n9zNj-KzhPGgsLmt6chMrAoxlU92B3ojsuPCpP8JTuC_FYLGNVf_llv2IjicKFLemaclHx8X2JVwzEIwdY5ypIpGPDhmeTgowIX-9FQcLuOpscofDQv0YFfiEaV-J_QokNiKJT7fnXUf83D2bOJqeLMj05l-3MJxo4dSB8',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16, bottom: 16, right: 16,
                      child: const Text(
                        'Final call for the Late Night Hackathon',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content Text
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Gear up for the final push! The Late Night Hackathon registration closes at midnight. Don't miss your chance to build, break, and innovate with the best engineering minds on campus. We've got 24 hours of pure building, pizza, and prizes.\n\nBring your parts, bring your code, and let's see what survives the night. See you at the Lab!",
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 32),
                
                // Reaction Bar
                Container(
                  padding: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      _buildReactionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        count: _likesCount.toString(),
                        isActive: _isLiked,
                        onTap: () => setState(() {
                          _isLiked = !_isLiked;
                          _likesCount += _isLiked ? 1 : -1;
                        }),
                      ),
                      const SizedBox(width: 24),
                      _buildReactionButton(icon: Icons.local_fire_department, count: '86', isActive: false, onTap: () {}),
                      const SizedBox(width: 24),
                      _buildReactionButton(icon: Icons.pan_tool, count: '32', isActive: false, onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton({required IconData icon, required String count, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isActive ? AppColors.primary : AppColors.textSecondaryDark, size: 24),
          const SizedBox(width: 8),
          Text(count, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Community Discussion', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('4 comments', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 24),
        _buildComment(
          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuALbbQNbOhp4zpQkrYfQ0sKPlC-QTFAz45aKWQ1rW_BAnc-O2BlbBYJIlBFnyb9n5gx_NXjptcdSZcFyfIGiGhH_yWFlH68rXAGf5pVczmTHR8DK6YV8kuSAg31vU9_5mmiviwfrWii6n0v-oHvuTmFPgz3t0_cl1dHSfYKBSv2LKL8K8gpYLQRoOlzbvYTVYM0hKPrC6KlF6vpqhzrq3eGBkpSIZpgEjS65LaqdG5XWAmLFLBC_CRzw-7tbji_RfdC1vyrDN-PKEo',
          name: 'Alex Sterling',
          role: 'Executive',
          timeAgo: '2m ago',
          content: "Just joined! Can't wait to see the builds.",
          likes: 4,
        ),
        const SizedBox(height: 24),
        _buildComment(
          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCtv_jRgtoZG-gGI7xMwGgMyPb4NQlHjtz7pFPNBmXNMeS5QfTF0OVfHvKCeysVECA6BG7Ccm2fpLLwpZ8j5VI9gDRXoCIemTd-wUNjdqQKWnLIH-BQi9cQe-oLUVpFPJTxq4KWhZcCv41sORue59tjdn4D8qDcCuEfpucupcVjhUMCzB5rS-09FHpOv1Z6tFebNQbC1wp7haE6a45L4ygxQkuAff1xRI7JDnqNdKBwPWG4wGxm0H5bJSylHDU3iIF8-zE5I8CDxa0',
          name: 'Sarah Chen',
          role: 'Executive',
          timeAgo: '5m ago',
          content: "Team limit is 4 people!",
        ),
        const SizedBox(height: 24),
        _buildIconComment(
          icon: Icons.person,
          color: AppColors.secondary,
          name: 'Marcus V.',
          timeAgo: '10m ago',
          content: "Is there a team size limit?",
        ),
        const SizedBox(height: 24),
        _buildIconComment(
          icon: Icons.person,
          color: AppColors.tertiary,
          name: 'Jordan Smith',
          timeAgo: '1h ago',
          content: "Looking for a teammate! I'm good with Arduino.",
        ),
      ],
    );
  }

  Widget _buildComment({required String avatarUrl, required String name, String? role, required String timeAgo, required String content, int? likes}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (role != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                      child: Text(role.toUpperCase(), style: const TextStyle(color: Color(0xFF571F00), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const Spacer(),
                  Text(timeAgo, style: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('REPLY', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  if (likes != null) ...[
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: AppColors.textSecondaryDark, size: 14),
                        const SizedBox(width: 4),
                        Text(likes.toString(), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconComment({required IconData icon, required Color color, required String name, required String timeAgo, required String content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Text(timeAgo, style: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
              const SizedBox(height: 8),
              const Text('REPLY', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F).withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: AppColors.textSecondaryDark),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 15)],
                ),
                child: const Icon(Icons.send, color: Color(0xFF571F00)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

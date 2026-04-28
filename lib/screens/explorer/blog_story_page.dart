import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlogStoryPage extends StatelessWidget {
  final Map<String, String> story;

  const BlogStoryPage({Key? key, required this.story}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            elevation: 0,
            backgroundColor: MyTheme.isDark(context) ? MyTheme.darkCard : MyTheme.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  story['imageUrl'] != null
                      ? CachedNetworkImage(
                          imageUrl: story['imageUrl']!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: MyTheme.shimmer_base),
                        )
                      : Container(color: MyTheme.accent_color),
                  // Gradient overlay for readability of back button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story['title'] ?? '',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: MyTheme.primaryText(context),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: MyTheme.primary(context).withOpacity(0.1),
                        child: Icon(Icons.person, size: 16, color: MyTheme.primary(context)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story['author'] ?? 'Admin',
                            style: TextStyle(color: MyTheme.primaryText(context), fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "Published • 5 min read",
                            style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Medium style typography
                  Text(
                    story['content'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.8,
                      color: MyTheme.primaryText(context).withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Georgia', // Giving it a classic serif feel if available
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  // "Explore Products" CTA at the end of the blog
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MyTheme.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MyTheme.border(context)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Inspired by this story?", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: MyTheme.primaryText(context))),
                              const SizedBox(height: 4),
                              Text("Explore authentic products from local artisans.", style: TextStyle(fontSize: 12, color: MyTheme.secondaryText(context))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [MyTheme.market_red, MyTheme.secondary_color]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("Shop Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

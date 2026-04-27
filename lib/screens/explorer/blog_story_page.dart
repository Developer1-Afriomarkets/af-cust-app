import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';

class BlogStoryPage extends StatelessWidget {
  final Map<String, String> story;

  const BlogStoryPage({Key? key, required this.story}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background(context),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: MyTheme.primaryText(context)),
        title: Text(
          'Story',
          style: TextStyle(color: MyTheme.primaryText(context), fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: MyTheme.brandBackground(
        context: context,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (story['imageUrl'] != null)
                Image.network(
                  story['imageUrl']!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story['title'] ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: MyTheme.primaryText(context),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: MyTheme.secondaryText(context)),
                        const SizedBox(width: 8),
                        Text(
                          story['author'] ?? 'Admin',
                          style: TextStyle(color: MyTheme.secondaryText(context), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      story['content'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: MyTheme.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BlogProvider(),
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (context) => BlogProvider(),
        child: BlogListScreen(),
      ),
    );
  }
}
class Blog {
  final String id;
  final String title;
  final String imageUrl;
  final String content;
  bool isFavorite; // flag to track if the blog is a favorite

  Blog({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.content,
    this.isFavorite = false,
  });
}
class BlogProvider with ChangeNotifier {
  List<Blog> blogs = [];

  void toggleFavorite(String id) {
    final blogIndex = blogs.indexWhere((blog) => blog.id == id);
    if (blogIndex != -1) {
      blogs[blogIndex].isFavorite = !blogs[blogIndex].isFavorite;
      notifyListeners();
    }
  }
}
class BlogListScreen extends StatefulWidget {

  @override
  _BlogListScreenState createState() => _BlogListScreenState();
}


class _BlogListScreenState extends State<BlogListScreen> {
  List<Blog> blogs = [];

  @override
  void initState() {
    super.initState();
    fetchBlogs();
  }
  void fetchBlogs() async {
    const String url = 'https://intent-kit-16.hasura.app/api/rest/blogs';
    const String adminSecret =
        '32qR4KmXOIpsGPQKMqEJHGJS27G5s7HdSKO3gdtQd2kv5e852SiYwWNfxkZOBuQ6';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'x-hasura-admin-secret': adminSecret,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = json.decode(response.body);
        final List<dynamic>? blogList = data?['blogs'];

        if (blogList != null) {
          final blogProvider = Provider.of<BlogProvider>(context, listen: false);

          setState(() {
            blogProvider.blogs = blogList.map((item) {
              return Blog(
                id: item['id'] ?? '',
                title: item['title'] ?? '',
                imageUrl: item['image_url'] ?? '',
                content: item['content'] ?? '',
              );
            }).toList();
          });
        } else {
          print('No blogs found in the API response.');
        }
      } else {
        print('Request failed with status code: ${response.statusCode}');
        print('Response data: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final blogProvider = Provider.of<BlogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoriteBlogScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: blogProvider.blogs.length,
        itemBuilder: (context, index) {
          final blog = blogProvider.blogs[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailedBlogScreen(
                      blog: blog,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      blog.imageUrl,
                      width: MediaQuery.of(context).size.width - 16,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    blog.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(
                    thickness: 2,
                    color: Colors.grey,
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

class DetailedBlogScreen extends StatelessWidget {
  final Blog blog;

  DetailedBlogScreen({required this.blog});

  @override
  Widget build(BuildContext context) {
    final blogProvider = Provider.of<BlogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detailed Blog'),
        actions: [
          IconButton(
            icon: Icon(
              blog.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: blog.isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              blogProvider.toggleFavorite(blog.id);

            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blog.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Image.network(blog.imageUrl),
            SizedBox(height: 16),
            Text(
              blog.content,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteBlogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final blogProvider = Provider.of<BlogProvider>(context);
    final favoriteBlogs = blogProvider.blogs.where((blog) => blog.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Blogs'),
      ),
      body: ListView.separated(
        itemCount: favoriteBlogs.length,
        separatorBuilder: (BuildContext context, int index) {
          return Divider();
        },
        itemBuilder: (context, index) {
          final blog = favoriteBlogs[index];
          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedBlogScreen(
                    blog: blog,
                  ),
                ),
              );
            },
            title: Text(blog.title),
          );
        },
      ),
    );
  }
}

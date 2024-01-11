import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => AppState(),
        child: MaterialApp(
            title: 'Rss-Reader',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            home: FeedPage()));
  }
}

class AppState extends ChangeNotifier {
  var url = 'https://godotengine.org/rss.xml';

  var rssEntries = [];

  void fetchRssEntries() async {
    var res = await http.get(Uri.parse(url));
    var rssResults = RssFeed.parse(res.body);
    rssEntries = [];
    for (var entry in rssResults.items!) {
      rssEntries.add(entry.title);
    }
    notifyListeners();
  }
}

class FeedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    var rssEntries = appState.rssEntries;
    if (rssEntries.isNotEmpty) {
      return ListView(
        children: [for (var entry in rssEntries) Text(entry.toString())],
      );
    } else {
      appState.fetchRssEntries();
      return (Text('No Entries Available'));
    }
  }
}

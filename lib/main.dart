import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MainApp());
}

Future<void> openBrowser(url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri)) {
    throw Exception('Could not launch $uri');
  }
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
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.cyan, background: Colors.transparent),
            ),
            home: App()));
  }
}

class AppState extends ChangeNotifier {
  var urls = [
    'https://godotengine.org/rss.xml',
    'https://news.ycombinator.com/rss'
  ];

  var rssEntries = <RssItem>[];

  void fetchRssEntries() async {
    rssEntries = [];
    for (var feed in urls) {
      var res = await http.get(Uri.parse(feed));
      var rssResults = RssFeed.parse(res.body);
      print('${res.statusCode}: ${rssResults}');
      for (var entry in rssResults.items!) {
        rssEntries.add(entry);
      }
    }
    rssEntries.sort((a, b) => -a.pubDate!.compareTo(b.pubDate!));
    notifyListeners();
  }
}

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = FeedPage();
        break;
      default:
        throw UnimplementedError('no widget for ${selectedIndex}');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
          body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              destinations: [
                NavigationRailDestination(
                  label: const Text('Home'),
                  icon: const Icon(Icons.rss_feed),
                ),
                NavigationRailDestination(
                    icon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
          ),
          Expanded(child: page)
        ],
      ));
    });
  }
}

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final style =
        theme.textTheme.bodyLarge!.copyWith(color: theme.colorScheme.onPrimary);
    var appState = context.watch<AppState>();
    var rssEntries = appState.rssEntries;

    if (rssEntries.isNotEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.only(left: 40.0, top: 20.0),
          child: ListView(
            children: [
              for (var entry in rssEntries)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    key: entry.guid != null
                        ? Key(entry.guid!)
                        : Key(entry.link!),
                    child: Row(
                      children: [
                        entry.source != null
                            ? Flexible(
                                flex: 1,
                                child: SizedBox(
                                  width: 300,
                                  child: Text(entry.source.toString(),
                                      style: style,
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.center),
                                ),
                              )
                            : Flexible(
                                flex: 1,
                                child: SizedBox(
                                  width: 300,
                                  child: Text(entry.link.toString(),
                                      style: style,
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.center),
                                )),
                        const SizedBox(width: 20),
                        Flexible(
                            flex: 1,
                            child: SizedBox(
                              width: 800,
                              child: Text(
                                entry.title.toString(),
                                style: style,
                                overflow: TextOverflow.clip,
                              ),
                            )),
                        const SizedBox(width: 20),
                        Flexible(
                          flex: 1,
                          child: SizedBox(
                            width: 100,
                            child: Text(
                              '${entry.pubDate!.day}/${entry.pubDate!.month}/${entry.pubDate!.year}',
                              style: style,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => {openBrowser(entry.link)},
                  ),
                )
            ],
          ),
        ),
      );
    } else {
      appState.fetchRssEntries();
      return Container(
          color: Theme.of(context).colorScheme.primary,
          child: (Text('No Entries Available', style: style)));
    }
  }
}

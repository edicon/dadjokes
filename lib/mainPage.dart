import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:share/share.dart';

const dadJokeApi = "https://icanhazdadjoke.com/";
const httpHeaders = const {
  'User-Agent': 'DadJokes (https://github.com/timsneath/dadjokes)',
  'Accept': 'application/json',
};

const jokeTextStyle = const TextStyle(
    fontFamily: 'Patrick Hand',
    fontSize: 36,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal);

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  Future<String> _response;
  String _displayedJoke = '';

  @override
  initState() {
    super.initState();
    _refreshAction();
  }

  _refreshAction() {
    setState(() {
      _response = http.read(dadJokeApi, headers: httpHeaders);
    });
  }

  _aboutAction() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
              title: Text('About Dad Jokes'),
              content: Text(
                  'Dad jokes is brought to you by Tim Sneath (@timsneath), '
                  'proud dad of Naomi, Esther, and Silas. May your children '
                  'groan like mine do.\n\nDad jokes come from '
                  'https://icanhazdadjoke.com with thanks.'));
        });
  }

  _shareAction() {
    if (_displayedJoke.isNotEmpty) {
      Share.share(_displayedJoke);
    }
  }

  FutureBuilder<String> _jokeBody() {
    return FutureBuilder<String>(
      future: _response,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const ListTile(
              leading: Icon(Icons.sync_problem),
              title: Text('No connection'),
            );
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            if (snapshot.hasError) {
              return const Center(
                child: ListTile(
                  leading: Icon(Icons.error),
                  title: Text('Network error'),
                  subtitle: Text(
                      'Sorry - this isn\'t funny, we know, but something went '
                      'wrong when connecting to the Internet. Check your '
                      'network connection and try again.'),
                ),
              );
            } else {
              final decoded = json.decode(snapshot.data);
              if (decoded['status'] == 200) {
                _displayedJoke = decoded['joke'];
                return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Dismissible(
                      key: const Key("joke"),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        _refreshAction();
                      },
                      child: AutoSizeText(_displayedJoke, style: jokeTextStyle),
                    ));
              } else {
                return ListTile(
                  leading: const Icon(Icons.sync_problem),
                  title: Text('Unexpected error: ${snapshot.data}'),
                );
              }
            }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'assets/icon.png',
          fit: BoxFit.scaleDown,
        ),
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            tooltip: 'About Dad Jokes',
            onPressed: _aboutAction,
          ),
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'Share joke',
            onPressed: _shareAction,
          )
        ],
      ),
      body: Center(
        child: SafeArea(child: _jokeBody()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshAction,
        icon: Icon(Icons.mood),
        label: Text('NEW JOKE'),
      ),
    );
  }
}

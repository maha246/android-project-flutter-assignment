

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hello_me/authentication_service.dart';
import 'package:provider/provider.dart';
import 'authentication_service.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:io';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
                body: Center(
                    child: Text(snapshot.error.toString(),
                        textDirection: TextDirection.ltr)));
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return MyApp();
          }
          return Center(child: CircularProgressIndicator());
        },
      );
  }
}


// #docregion MyApp
class MyApp extends StatelessWidget {
  // #docregion build
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => authService.instance(),
        child: Consumer<authService>(
          builder: (context, login, _) => MaterialApp(
            title: 'Startup Name Generator',
            theme: ThemeData(          // Add the 5 lines from here...
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            home: RandomWords(),
          ),
        )
    );
  }// #enddocregion build
} // #enddocregion MyApp

// #docregion RWS-var
class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18.0);
  var auth;
  var draggable = true;
  var myController = SnappingSheetController();


  // #enddocregion RWS-var

  // #docregion _buildSuggestions
  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return const Divider();
          /*2*/

          final index = i ~/ 2; /*3*/
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10)); /*4*/
          }
          return _buildRow(_suggestions[index]);
        });
  }

  // #enddocregion _buildSuggestions

  // #docregion _buildRow
  Widget _buildRow(WordPair pair) {
    final alreadySavedLocally = _saved.contains(pair);
    final alreadySavedCLoud = (auth.status == Status.Authenticated &&
        auth.favorites.contains(pair));
    var alreadySaved = alreadySavedLocally || alreadySavedCLoud;
    if (alreadySavedLocally && !alreadySavedCLoud) auth.insertPair(pair);

    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon( // NEW from here...
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.deepPurple : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () { // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            auth.removePair(pair);
          } else {
            _saved.add(pair);
            auth.insertPair(pair);
          }
        });
      },
    );
  }

  // #enddocregion _buildRow

  // #docregion RWS-build
  @override
  Widget build(BuildContext context) {
    auth = Provider.of<authService>(context, listen: false);
    var doThis = _pushLogin;
    var suitableIcon = Icons.login;
    //TODO: check the user or the status
    //auth.user != null
    if (auth.status == Status.Authenticated) {
      doThis = _pushLogOut;
      suitableIcon = Icons.exit_to_app;
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Startup Name Generator'),
          actions: [
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: _pushSaved,
              tooltip: 'Saved Suggestions',
            ),
            IconButton(
              icon: Icon(suitableIcon),
              onPressed: doThis,
              tooltip: 'Login',
            ),
          ],
        ),
        body:Material(
        child:InkWell(
          child: SnappingSheet(
            child: _buildSuggestions(),
            lockOverflowDrag: true,
            controller: myController,
            snappingPositions: [
              SnappingPosition.pixels(
                  positionPixels: 60,
                  snappingCurve: Curves.bounceOut,
                  snappingDuration: Duration(milliseconds: 350)),
              SnappingPosition.factor(
                  positionFactor: 1.1,
                  snappingCurve: Curves.easeInBack,
                  snappingDuration: Duration(milliseconds: 350)),
            ],
            sheetBelow: auth.status == Status.Authenticated ?
            SnappingSheetContent(
              draggable: true,
              child: Container(
                color: Colors.white,
                child: ListView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      Column(children: [

                        Row(children: <Widget>[
                          Expanded(
                            child: Container(
                              color: Colors.blueGrey[200],
                              height: 60,
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                            "  Welcome back, " +
                                                auth.getMail(),
                                            style: TextStyle(
                                                fontSize: 16.0)),
                                      )),
                                  IconButton(
                                    icon: Icon(Icons.keyboard_arrow_up, color: Colors.black,),
                                    onPressed: null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                        Row(children:[
                          FutureBuilder(
                            future: auth.getImage(),
                            builder: (BuildContext context,
                                AsyncSnapshot<String> snapshot) {
                              return CircleAvatar(
                                radius: 40.0,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: snapshot.data != null
                                    ? NetworkImage(snapshot.data.toString())
                                    : null,
                              );
                            },
                          ),
                        Column(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(auth.getMail(),
                                      style: TextStyle(
                                          fontSize: 18))),
                              MaterialButton(
                                onPressed: () async {
                                  FilePickerResult? res =
                                  await FilePicker.platform
                                      .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['png', 'jpg', 'gif', 'bmp', 'jpeg', 'webp'],
                                  );
                                  File file;
                                  if (res != null) {
                                    file =
                                        File(res.files.single.path.toString());
                                    auth.uploadNewImage(file);
                                  } else {
                                    // User canceled the picker
                                  }
                                },
                                textColor: Colors.white,
                                padding: EdgeInsets.only(left: 7.0, top: 3.0, bottom: 10.0, right: 12.0),
                                child: Container(

                                  color: Colors.blue,
                                  padding: const EdgeInsets.fromLTRB(13, 3, 13, 3),
                                  child: const Text('Change Avatar',
                                      style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ])
                        ]),
                      ]),
                    ]),
              ),
              //heightBehavior: SnappingSheetHeight.fit(),
            ):null,
              
            ),

            onTap: (){
                if (draggable == false) {
                  draggable = true;
                  myController.snapToPosition(SnappingPosition.factor(
                    positionFactor: 0.235,
                  ));
                } else {
                  draggable = false;
                  myController.snapToPosition(SnappingPosition.factor(
                      positionFactor: 0.089,
                      snappingCurve: Curves.easeInBack,
                      snappingDuration: Duration(milliseconds: 1)));
                }
              }

        ))
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          //var _auth = Provider.of<authService>(context, listen: false);
          var _favs = _saved;
          if (auth.status == Status.Authenticated) {
            _favs = _saved.union(auth.favorites);
          } else {
            _favs = _saved;
          }
          final tiles = _favs.map(
                (pair) {
              return Dismissible(
                child: ListTile(
                    title: Text(
                      pair.asPascalCase,
                      style: _biggerFont,
                    )),
                background: Container(
                  child: Row(
                    children: const <Widget>[
                      Icon(Icons.delete, color: Colors.white,),
                      Text('Delete Suggestion', style: TextStyle(color: Colors
                          .white),)
                    ],
                  ),
                  color: Colors.deepPurple,
                ),

                key: ValueKey<WordPair>(pair),
                onDismissed: (DismissDirection direction) {
                  setState(() {
                    _saved.remove(pair);
                    auth.removePair(pair);
                  });
                },
                confirmDismiss: (DismissDirection direction) async {
                  return await showDialog<bool>(
                    context: context,
                    barrierDismissible: true, // user must tap button!
                    builder: (BuildContext context) {
                      return AlertDialog(

                        title: const Text('Delete Suggestion'),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text('Are you sure you want to delete ${pair
                                  .asPascalCase} from your saved suggestions?'),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.fromLTRB(
                                  12, 10, 12, 10),
                              primary: Colors.white,
                              textStyle: const TextStyle(fontSize: 17.0),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Yes'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.fromLTRB(
                                  12, 10, 12, 10),
                              primary: Colors.white,
                              textStyle: const TextStyle(fontSize: 17.0),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: const Text('No'),
                          ),
                        ],
                      );
                    },
                  );
                  //const snackBar =  SnackBar(content: Text('Deletion is not implemented yet'));
                  //ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },

              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  void _pushLogOut() async {
    draggable = false;
    myController.snapToPosition(SnappingPosition.factor(positionFactor: 0.089));

    await auth.signOut();
    const snackbar = SnackBar(content: Text('Successfully logged out'));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
    _saved.clear();
  }

  void _pushLogin() {
    //final auth = Provider.of<authService>(context, listen: false);
    TextEditingController _email = TextEditingController(text: "");
    TextEditingController _pass = TextEditingController(text: "");
    TextEditingController _secondPass = TextEditingController(text: "");

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Login'),
              ),
              body: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 10,
                      ),
                      const Text(
                          "Welcome to Startup Names Generators, please log in below"),
                      Container(
                        height: 20,
                      ),
                      TextField(
                        controller: _email,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: "Email",
                        ),
                      ),
                      Container(
                        height: 20,
                      ),
                      TextField(
                        controller: _pass,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                        ),
                      ),
                      Container(
                        height: 20,
                      ),
                      auth.status == Status.Authenticating
                          ? Center(child: CircularProgressIndicator())
                          : Material(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.deepPurple,
                          child: MaterialButton(
                            padding: EdgeInsets.all(10),
                            minWidth: MediaQuery.of(context).size.width,
                            child: const Text(
                                'Log in', style: TextStyle(color: Colors
                                .white)),
                            onPressed: () async {
                              await auth.signIn(_email.text.trim(), _pass.text
                                  .trim());
                              //TODO: user or status?
                              if (auth.status == Status.Unauthenticated) {
                                const snackBar = SnackBar(content: Text(
                                    'There was an error logging into the app'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    snackBar);
                              }
                              else {
                                Navigator.of(context).pop();
                              }
                            },

                          )
                      ),
                      Container(height: 10,),
                      auth.status == Status.Authenticating
                          ? Center(child:null)
                          :Material(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.blue,
                          child: MaterialButton(
                            padding: EdgeInsets.all(10),
                            minWidth: MediaQuery.of(context).size.width,
                            child: const Text('New user? Click to sign up',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (BuildContext context) {
                                    return _getPassConfirm(_email, _pass, _secondPass);
                                  }
                              );
                            },

                          )
                      ),
                    ],
                  )
              )
          );
        },
      ),
    );
  }

  _getPassConfirm(email, pass, secondPass) {
    var validPass = true;
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: Container(
        height: 200,
        color: Colors.white,
        child: Center(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            //mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                  'Please confirm your password below:'),
              Container(height: 20),
              Container(
                width: 350,
                child: TextField(
                  controller: secondPass,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),
              Container(height: 20),
              Material(
                color: Colors.blue,
                child: MaterialButton(
                    child:Container(
                      color: Colors.blue,
                      padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
                      child: const Text('Confirm',
                      style: TextStyle(fontSize: 13, color: Colors.white))),
                    onPressed: () async {
                      if (secondPass.text == pass.text) {
                        //do that
                        // await user.signOut();
                        auth.signUp(email.text, pass.text);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          validPass = false;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords must match')));
                          Navigator.pop(context);
                          FocusScope.of(context)
                              .requestFocus(FocusNode());
                        });
                      }
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }


}
// #enddocregion RWS-build
// #docregion RWS-var

// #enddocregion RWS-var

class RandomWords extends StatefulWidget {
  @override
  State<RandomWords> createState() => _RandomWordsState();
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Appka',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Super Appka'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Post {
  String id;
  String title;
  String content;
}

class _MyHomePageState extends State<MyHomePage> {
  List<Post> posts = [];
  final _formKey = GlobalKey<FormState>();

  FirebaseUser _user;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseReference = Firestore.instance;

  void _loginWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    print("zalogowano jako " + user.displayName);

    databaseReference.collection('posts').limit(50).snapshots().listen((event) {
      posts = [];

      event.documents.reversed.forEach((element) {
        Post post = Post();
        post.id = element.documentID;
        post.title = element['title'];
        post.content = element['content'];
        posts.add(post);
      });

      setState(() {
        posts = posts.toList();
      });
    });

    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: _buildUserWidget(_user),
                onPressed: () {
                  _loginWithGoogle();
                },
              )
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(widget.title),
            actions: _isLoggedIn(),
          ),
          body: _blogPosts());
    }
  }

  Widget _buildUserWidget(FirebaseUser user) {
    if (user == null) {
      return Text("Zaloguj przez Google");
    } else {
      return Row(
        children: [Text(user.displayName), Image.network(user.photoUrl)],
      );
    }
  }

  Widget _blogPosts() {
    return Column(children: [
      SizedBox(
          width: double.infinity,
          child: RaisedButton(
              onPressed: _addNewPostDialog,
              color: Colors.orange,
              textColor: Colors.white,
              child: const Text('Dodaj nowy post',
                  style: TextStyle(fontSize: 20)))),
      Expanded(
          child: ListView.separated(
        separatorBuilder: (BuildContext ctx, int index) {
          return Divider(color: Colors.black);
        },
        shrinkWrap: true,
        itemBuilder: _listItem,
        itemCount: posts.length,
      ))
    ]);
  }

  Widget _listItem(BuildContext ctx, int index) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: Colors.white,
        child: ListTile(
          title: Text(posts[index].title),
          subtitle: Text(posts[index].content),
          trailing: Column(
            children: <Widget>[
              Expanded(
                child: FlatButton(
                  textColor: Colors.red,
                  child: Text('Usuń'),
                  onPressed: () => {
                      _deletePost(posts[index].id)
                  }
                )
              )
            ]
          )
        ));
  }

  void _addNewPostDialog() {
    String title = '';
    String content = '';

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Nowy post"),
            content: new Column(children: <Widget>[
              Expanded(
                  child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                    labelText: 'Tytuł', hintText: 'Nowy post na blogu!'),
                onChanged: (value) {
                  title = value;
                },
              )),
              Expanded(
                  child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                    labelText: 'Treść', hintText: 'Super fajne studia'),
                onChanged: (value) {
                  content = value;
                },
              ))
            ]),
            actions: [
              FlatButton(
                child: Text("Dodaj"),
                onPressed: () {
                  _addPost(title, content);
                  title = "";
                  content = "";

                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void _addPost(String title, String content) async {
    if (title != "" && content != "") {
      print("dodaje ${title}");
      DocumentReference ref = await databaseReference.collection("posts").add({
        "title": title,
        "content": content,
      });
    }
  }

  void _deletePost(String id) async {
    print("usuwam ${id}");
    await databaseReference.collection("posts").document(id).delete();
  }

  List<Widget> _isLoggedIn() {
    if (_user == null) {
      return [Text("Guest")];
    } else {
      return [
        Image.network("${_user.photoUrl}")
      ];
    }
  }
}

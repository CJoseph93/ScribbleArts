import 'package:flutter/material.dart';
import 'package:flutter_app/auth.dart';
import 'painter.dart';
import 'dart:typed_data';
import 'dart:ui';
import 'package:rating_dialog/rating_dialog.dart';
import 'dart:io';
import 'package:image/image.dart' as I;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Scribble Arts',
      home: new ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  @override
  _ExamplePageState createState() => new _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {

  bool _notInRoom;
  bool _sentImage;
  Future<FirebaseUser> _user;
  bool _loggedIn;
  bool _finished;
  String _filepath;
  PainterController _controller;

  @override
  void initState() {
    super.initState();
    _notInRoom=true;
    _sentImage=false;
    _loggedIn=true;
    _finished=false;
    _filepath = "badPath/new.png";
    _controller=_newController();
  }

  Future<String> createAlertDialog(BuildContext context) {

    TextEditingController customController = TextEditingController();

    return showDialog(context: context, builder: (context) {
      return AlertDialog (
        title: Text ("Join a Room"),
        content: TextField(
          controller: customController,
        ),
        actions: <Widget>[
          MaterialButton (
            elevation: 5.0,
            child: Text('Submit'),
            onPressed:() {
              Navigator.of(context).pop(customController.text.toString());
            },
          )
        ],
      );
    });
  }

  Future<String> createRatingDialog(BuildContext context) {

    showDialog(
        context: context,
        barrierDismissible: true, // set to false if you want to force a rating
        builder: (context) {
          return RatingDialog(
            icon: const FlutterLogo(
                size: 5,
                colors: Colors.blue), // set your own image/icon widget
            title: "Rate their picture!",
            description:
            "",
            submitButton: "SUBMIT",
            accentColor: Colors.red, // optional
            onSubmitPressed: (int rating) {
              print("onSubmitPressed: rating = $rating");
              // TODO: open the app's page on Google Play / Apple App Store
            },
            onAlternativePressed: () {
              print("onAlternativePressed: do something");
              // TODO: maybe you want the user to contact you instead of rating a bad review
            },
          );
        });
  }

  PainterController _newController(){
    PainterController controller=new PainterController();
    controller.thickness=5.0;
    controller.backgroundColor=Colors.white;
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if(_finished){
      actions = <Widget>[
        new IconButton(
          icon: new Icon(Icons.content_copy),
          tooltip: 'New Sketch',
          onPressed: ()=>setState((){
            _finished=false;
            _controller=_newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        _loggedIn ? new MaterialButton(
          onPressed: () {
            _user = authService.googleSignIn();
            _loggedIn=false;
            setState(() {});
          },
          color: Colors.white,
          textColor: Colors.black,
          child: Text('Login')
        ):
        new MaterialButton(
            onPressed: () {
              authService.signOut();
              _loggedIn=true;
              setState(() {});
            },
            color: Colors.red,
            textColor: Colors.black,
            child: Text('logout')
        ),
        new IconButton(
          icon: new Icon(Icons.cloud_download),
          onPressed: () async {
            var url = await FirebaseStorage.instance.ref().child(_filepath  + "/" + "myImage1.png").getDownloadURL();
            setState(() {
              _controller.backgroundImage = Image.network(url);
              _controller.backgroundColor=Colors.transparent;
            });
          },
        ),
         _notInRoom ? new IconButton(
            icon: new Icon(Icons.keyboard_return),
            onPressed: () {
              createAlertDialog(context).then((onValue) {
                _filepath=onValue;
              });
              _notInRoom=false;
              setState(() {});
            },
          ):
          new IconButton(
              icon: new Icon(Icons.star),
              onPressed: () async {
                createRatingDialog(context).then((onValue) {

                });
               },
          ),
        new IconButton(
            icon: new Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed:  _controller.undo
        ),
        new IconButton(
            icon: new Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed:  _controller.clear
        ),
        new IconButton(
            icon: new Icon(Icons.check),
            onPressed: () async {
              setState(() {
                _finished = true;
                _sentImage = true;
              });
              Uint8List bytes = await _controller.exportAsPNGBytes();
              final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://scribble-arts.appspot.com/');
              StorageUploadTask _uploadTask;
              String filePath = _filepath  + "/" + "myImage1.png";
              _uploadTask = _storage.ref().child(filePath).putData(bytes);
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text('View your image'),
                  ),
                  body: Container(
                    child: Image.memory(bytes),
                  ),
                );
              }));
            }),
      ];
    }

    return new Scaffold(
        appBar: new AppBar(
            title: const Text('Scribble Arts'),
            actions:actions,
            bottom: new PreferredSize(
              child: new DrawBar(_controller),
              preferredSize: new Size(MediaQuery.of(context).size.width,30.0),
            )
        ),
        body: Stack (
         children: <Widget>[
         Container(
//          decoration: BoxDecoration(
//            image: DecorationImage(
//              image: AssetImage("assets/cory.jpg"),
//              fit: BoxFit.cover,
//            ),
//          ),
          child:new Center(
            child:new AspectRatio(
                aspectRatio: 1.0,
                child: new Painter( _controller)
            )
          )
        ),
        ]
        ),
      );

  }

}

class DrawBar extends StatelessWidget {

  final PainterController _controller;

  DrawBar(this._controller);

  @override
  Widget build(BuildContext context) {
    return  new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Flexible(
            child: new StatefulBuilder(
                builder: (BuildContext context,StateSetter setState){
                  return new Container(
                      child: new Slider(
                        value:  _controller.thickness,
                        onChanged: (double value)=>setState((){
                          _controller.thickness=value;
                        }),
                        min: 1.0,
                        max: 20.0,
                        activeColor: Colors.white,
                      )
                  );
                }
            )
        ),
        new ColorPickerButton( _controller, false),
        new ColorPickerButton( _controller, true),
      ],
    );
  }
}


class ColorPickerButton extends StatefulWidget {

  final PainterController _controller;
  final bool _background;

  ColorPickerButton(this._controller,this._background);

  @override
  _ColorPickerButtonState createState() => new _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return new IconButton(
        icon: new Icon(_iconData,color: _color),
        tooltip: widget._background?'Change background color':'Change draw color',
        onPressed: _pickColor
    );
  }

  void _pickColor(){
    Color pickerColor=_color;
    Navigator.of(context).push(
        new MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context){
              return new Scaffold(
                  appBar: new AppBar(
                    title: const Text('Pick color'),
                  ),
                  body: new Container(
                      alignment: Alignment.center,
                      child: new ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c)=>pickerColor=c,
                      )
                  )
              );
            }
        )
    ).then((_){
      setState((){
        _color=pickerColor;
      });
    });
  }

  Color get _color=>widget._background?widget._controller.backgroundColor:widget._controller.drawColor;

  IconData get _iconData=>widget._background?Icons.format_color_fill:Icons.brush;

  set _color(Color color){
    if(widget._background){
      widget._controller.backgroundColor=color;
    } else {
      widget._controller.drawColor=color;
    }
  }
}

class UserProfile extends StatefulWidget {
  @override
  UserProfileState createState() => UserProfileState();
}

class UserProfileState extends State<UserProfile> {
  Map<String, dynamic> _profile;
  bool _loading = false;

  @override
  initState() {
    super.initState();
    authService.profile
      .listen((state) => setState(() => _profile = state));

    authService.loading
        .listen((state) => setState(() => _loading = state));
  }
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Container(
        padding:EdgeInsets.all(20),
        child: Text(_profile.toString())
      ),
      Text(_loading.toString())
    ]);;
  }
}
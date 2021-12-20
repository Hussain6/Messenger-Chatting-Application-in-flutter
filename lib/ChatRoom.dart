import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

// ignore: must_be_immutable
class ChatRoom extends StatelessWidget {
  Map<String, dynamic>? userMap;
  String chatRoomId;

  ChatRoom({Key? key, required this.chatRoomId, required this.userMap})
      : super(key: key);

  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? imageFile;

  Future getImage() async {
    ImagePicker _picker = ImagePicker();
    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = Uuid().v1();
    int status = 1;
    await _firestore
        .collection("chatroom")
        .doc(chatRoomId)
        .collection("chats")
        .doc(fileName)
        .set({
      "sendby": _auth.currentUser!.displayName,
      "message": "",
      "type": "img",
      "time": FieldValue.serverTimestamp()
    });

    var ref =
        FirebaseStorage.instance.ref().child('images').child('$fileName.jpg');
    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      await _firestore
          .collection("chatroom")
          .doc(chatRoomId)
          .collection("chats")
          .doc(fileName)
          .delete();
      status = 0;
    });

    if (status == 1) {
      String ImageUrl = await uploadTask.ref.getDownloadURL();
      await _firestore
          .collection("chatroom")
          .doc(chatRoomId)
          .collection("chats")
          .doc(fileName)
          .update({"message": ImageUrl});
      print(ImageUrl);
    }
  }

  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> messages = {
        "sendby": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time": FieldValue.serverTimestamp()
      };
      _message.clear();
      await _firestore
          .collection("chatroom")
          .doc(chatRoomId)
          .collection("chats")
          .add(messages);
    } else {
      print("Enter Soe text");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: StreamBuilder<DocumentSnapshot>(
          stream:
              _firestore.collection("users").doc(userMap!["uid"]).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return Column(
                children: [
                  Text(userMap!["name"]),
                  Text(
                    snapshot.data!["status"],
                    style: TextStyle(fontSize: 14),
                  )
                ],
              );
            } else {
              return Container(
                color: Colors.amber,
              );
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: size.height / 1.25,
              width: size.width,
              child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection("chatroom")
                      .doc(chatRoomId)
                      .collection("chats")
                      .orderBy("time", descending: false)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.data != null) {
                      return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic>? map =
                                snapshot.data!.docs[index].data()
                                    as Map<String, dynamic>;
                            return messages(size, map, context);
                          });
                    } else {
                      return Container();
                    }
                  }),
              //      color: Colors.amber,
            ),
            Container(
              height: size.height / 10.75,
              width: size.width,
              alignment: Alignment.center,
              //color: Colors.black,
              child: Container(
                  width: size.width / 1,
                  height: size.height / 12,
                  child: Row(
                    children: [
                      Container(
                        width: size.width / 1.2,
                        height: size.height / 12,
                        child: TextField(
                          style: TextStyle(color: Colors.black),
                          controller: _message,
                          decoration: InputDecoration(
                              fillColor: Colors.orange,
                              filled: true,
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    getImage();
                                  },
                                  icon: Icon(
                                    Icons.image,
                                    color: Colors.black,
                                  )),
                              hintText: "Type Message",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            onSendMessage();
                          },
                          icon: Icon(
                            Icons.send,
                            color: Colors.white,
                          ))
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    return map["type"] == "text"
        ? Container(
            width: size.width,
            alignment: map["sendby"] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.orange),
              child: Text(
                map["message"],
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ))
        : InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ShowImage(imageUrl: map["message"]))),
            child: Container(
              height: size.height / 2.5,
              width: size.width,
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              alignment: map["sendby"] == _auth.currentUser!.displayName
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                alignment: map["message"] != "" ? null : Alignment.center,
                height: size.height / 2.5,
                width: size.width / 2,
                decoration: BoxDecoration(border: Border.all()),
                child: map["message"] != ""
                    ? Image.network(
                        map["message"],
                        fit: BoxFit.cover,
                      )
                    : CircularProgressIndicator(),
              ),
            ),
          );
  }
}

class ShowImage extends StatelessWidget {
  final String imageUrl;
  const ShowImage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}

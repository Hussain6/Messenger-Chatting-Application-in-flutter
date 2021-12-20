import 'package:chatting/add_members.dart';
import 'package:chatting/group_chat_room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class GroupChatHomeScreen extends StatefulWidget {
  const GroupChatHomeScreen({Key? key}) : super(key: key);

  @override
  _GroupChatHomeScreenState createState() => _GroupChatHomeScreenState();
}

class _GroupChatHomeScreenState extends State<GroupChatHomeScreen> {
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    getAvailableGroups();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List groupList = [];

  void getAvailableGroups() async {
    String uid = _auth.currentUser!.uid;
    await _firestore
        .collection("users")
        .doc(uid)
        .collection("groups")
        .get()
        .then((value) {
      setState(() {
        groupList = value.docs;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Groups"),
      ),
      body: isLoading
          ? Container(
              height: size.height,
              width: size.width,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: groupList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GroupChatRoom(
                                  groupName: groupList[index]["name"],
                                  groupChatId: groupList[index]["id"],
                                )));
                  },
                  leading: Icon(
                    Icons.groups,
                    color: Colors.orange,
                  ),
                  title: Container(
                    child: Text(
                      groupList[index]["name"],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddMembersInGroup()));
        },
        child: Icon(
          Icons.edit,
          color: Colors.black,
        ),
        tooltip: "Create Group",
      ),
    );
  }
}

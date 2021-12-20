import 'package:chatting/HomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddMembersInGrouplater extends StatefulWidget {
  final String groupId, groupName;
  final List membersList;
  const AddMembersInGrouplater(
      {required this.membersList,
      required this.groupId,
      required this.groupName,
      Key? key})
      : super(key: key);

  @override
  _AddMembersInGroupState createState() => _AddMembersInGroupState();
}

bool isLoading = false;
final TextEditingController _search = TextEditingController();
FirebaseFirestore _firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;
Map<String, dynamic>? userMap = {"0": "0"};
List memberList = [];

class _AddMembersInGroupState extends State<AddMembersInGrouplater> {
  void onAddMembers() async {
    memberList.add({
      "name": userMap!["name"],
      "email": userMap!["email"],
      "uid": userMap!["uid"],
      "isAdmin": false
    });

    await _firestore
        .collection("groups")
        .doc(widget.groupId)
        .update({"members": memberList});

    await _firestore
        .collection("users")
        .doc(userMap!["uid"])
        .collection("groups")
        .doc(widget.groupId)
        .set({"name": widget.groupName, "id": widget.groupId});
    _search.clear();
    Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  void onSearch() async {
    setState(() {
      userMap = {"0": "0"};
      isLoading = true;
    });
    try {
      await _firestore
          .collection("users")
          .where("email", isEqualTo: _search.text)
          .get()
          .then((value) {
        setState(() {
          userMap = value.docs[0].data();
          isLoading = false;
        });
      });
    } catch (e) {
      print(e);
      print("Error from Search");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    memberList = widget.membersList;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Add Members"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: size.height / 30,
            ),
            Container(
              height: size.height / 12,
              width: size.width,
              alignment: Alignment.center,
              child: Container(
                height: size.height / 12,
                width: size.width / 1.1,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                      fillColor: Colors.orange,
                      filled: true,
                      hintText: "Search",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20))),
                ),
              ),
            ),
            isLoading
                ? Container(
                    height: size.height / 12,
                    width: size.width / 12,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  )
                : ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.orange)),
                    onPressed: () {
                      onSearch();
                    },
                    child: Text(
                      "Search",
                      style: TextStyle(color: Colors.black),
                    )),
            userMap!["0"] != "0"
                ? ListTile(
                    onTap: () {
                      onAddMembers();
                    },
                    leading: Icon(
                      Icons.account_circle,
                      color: Colors.white,
                    ),
                    title: Text(userMap!["name"],
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(userMap!["email"],
                        style: TextStyle(color: Colors.white)),
                    trailing: Icon(Icons.add),
                  )
                : SizedBox()
          ],
        ),
      ),
    );
  }
}

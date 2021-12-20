import 'package:chatting/create_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddMembersInGroup extends StatefulWidget {
  const AddMembersInGroup({Key? key}) : super(key: key);

  @override
  State<AddMembersInGroup> createState() => _AddMembersInGroupState();
}

class _AddMembersInGroupState extends State<AddMembersInGroup> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> membersList = [];
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();
  Map<String, dynamic>? userMap = {"0": "0"};

  @override
  void initState() {
    super.initState();
    getCurrentUserDetails();
  }

  void getCurrentUserDetails() async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get()
        .then((map) {
      setState(() {
        membersList.add({
          "name": map["name"],
          "email": map["email"],
          "uid": map["uid"],
          "isAdmin": true,
        });
      });
    });
  }

  void onResultTap() {
    bool isAlreadyExist = false;
    for (int i = 0; i < membersList.length; i++) {
      if (membersList[i]["uid"] == userMap!["uid"]) {
        isAlreadyExist = true;
      }
    }
    if (isAlreadyExist == false) {
      setState(() {
        membersList.add({
          "name": userMap!["name"],
          "email": userMap!["email"],
          "uid": userMap!["uid"],
          "isAdmin": false
        });
        userMap = {"0": "0"};
      });
    }
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

  void onRemoveAt(int Index) {
    if (membersList[Index]["uid"] != _auth.currentUser!.uid) {
      setState(() {
        membersList.removeAt(Index);
      });
    }
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
            Flexible(
                child: ListView.builder(
                    itemCount: membersList.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {
                          onRemoveAt(index);
                        },
                        leading:
                            Icon(Icons.account_circle, color: Colors.white),
                        title: Text(membersList[index]["name"],
                            style: TextStyle(color: Colors.white)),
                        subtitle: Text(membersList[index]["email"],
                            style: TextStyle(color: Colors.white)),
                        trailing: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      );
                    })),
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
                      onResultTap();
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
      floatingActionButton: membersList.length >= 2
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              child: Icon(
                Icons.forward,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CreateGroup(
                              membersList: membersList,
                            )));
              },
            )
          : SizedBox(),
    );
  }
}

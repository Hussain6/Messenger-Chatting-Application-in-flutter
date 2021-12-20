import 'package:chatting/HomeScreen.dart';
import 'package:chatting/add_members.dart';
import 'package:chatting/add_members_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInfo extends StatefulWidget {
  final groupId, groupName;
  const GroupInfo({required this.groupName, required this.groupId, Key? key})
      : super(key: key);

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List membersList = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    getGroupMembers();
  }

  bool checkAdmin() {
    bool isAdmin = false;
    membersList.forEach((element) {
      if (element["uid"] == _auth.currentUser!.uid) {
        isAdmin = true;
      }
    });
    return isAdmin;
  }

  void onLeavingGroup() async {
    if (checkAdmin()) {
      setState(() {
        isLoading = true;
      });
      String uid = _auth.currentUser!.uid;
      for (int i = 0; i < membersList.length; i++) {
        if (membersList[i]["uid"] == uid) {
          membersList.removeAt(i);
        }
      }

      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .update({"members": membersList});

      await _firestore
          .collection("users")
          .doc(uid)
          .collection("groups")
          .doc(widget.groupId)
          .delete();
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => HomeScreen()), (route) => false);
    } else {
      print("Cannot Remove you are admin of group");
    }
  }

  void showRemoveDialog(int index) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            content: ListTile(
              onTap: () => removeUser(index),
              title: Text("Remove this Member"),
            ),
          );
        });
  }

  void removeUser(int index) async {
    if (checkAdmin() && _auth.currentUser!.uid != membersList[index]["uid"]) {
      String uid = membersList[index]["uid"];
      membersList.removeAt(index);
      setState(() {
        isLoading = true;
      });
      await _firestore
          .collection("groups")
          .doc(widget.groupId)
          .update({"members": membersList});

      await _firestore
          .collection("users")
          .doc(uid)
          .collection("groups")
          .doc(widget.groupId)
          .delete();

      setState(() {
        isLoading = false;
      });
    } else {
      print("Cannot Remove");
    }
  }

  void getGroupMembers() async {
    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .get()
        .then((value) {
      setState(() {
        membersList = value["members"];
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return isLoading
        ? Container(
            height: size.height,
            width: size.width,
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          )
        : SafeArea(
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(
                          color: Colors.white,
                        )),
                    Container(
                      height: size.height / 8,
                      width: size.width / 1.1,
                      child: Row(
                        children: [
                          Container(
                            height: size.height / 11,
                            width: size.width / 11,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.grey),
                            child: Icon(
                              Icons.group,
                              color: Colors.white,
                              size: size.width / 10,
                            ),
                          ),
                          SizedBox(
                            width: size.width / 20,
                          ),
                          Expanded(
                            child: Container(
                                child: Text(
                              widget.groupName,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width / 16,
                                  fontWeight: FontWeight.w500),
                            )),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: size.height / 20,
                    ),
                    Container(
                        width: size.width / 1.1,
                        child: Text(
                          "${membersList.length} Members",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width / 20,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                    SizedBox(
                      height: size.height / 20,
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AddMembersInGrouplater(
                                      groupId: widget.groupId,
                                      groupName: widget.groupName,
                                      membersList: membersList,
                                    )));
                      },
                      leading: Icon(
                        Icons.add,
                        color: Colors.red,
                      ),
                      title: Text(
                        "Add Members",
                        style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.red),
                      ),
                    ),
                    Flexible(
                        child: ListView.builder(
                            itemCount: membersList.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ListTile(
                                onTap: () => showRemoveDialog(index),
                                leading: Icon(
                                  Icons.account_circle,
                                  color: Colors.white,
                                ),
                                title: Text(
                                  membersList[index]["name"],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: size.width / 22,
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  membersList[index]["email"],
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: Text(
                                  membersList[index]["isAdmin"] ? "Admin" : "",
                                  style: TextStyle(
                                      fontSize: size.width / 25,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red),
                                ),
                              );
                            })),
                    ListTile(
                      onTap: () {
                        onLeavingGroup();
                      },
                      leading: Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      title: Text(
                        "Leave Group",
                        style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.red),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
  }
}

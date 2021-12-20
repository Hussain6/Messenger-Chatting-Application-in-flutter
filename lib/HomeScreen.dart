import 'package:chatting/ChatRoom.dart';
import 'package:chatting/Methods.dart';
import 'package:chatting/group_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();
  Map<String, dynamic>? userMap = {"0": "0"};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  void setStatus(String status) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({"status": status});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }

  String chatRoomId(String user1, String user2) {
    int sum1 = 0;
    int sum2 = 0;
    for (int i = 0; i < user1.length; i++) {
      sum1 = user1[i].codeUnits[0] + sum1;
    }
    for (int i = 0; i < user2.length; i++) {
      sum2 = user2[i].codeUnits[0] + sum2;
    }
    if (sum1 > sum2) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  void onSearch() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Messenger Chatting"),
        actions: [
          IconButton(
              onPressed: () {
                logOut(context);
              },
              icon: Icon(Icons.logout)),
        ],
      ),
      body: isLoading
          ? Center(
              child: Container(
                height: size.height / 20,
                width: size.width / 10,
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
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
                      style: TextStyle(color: Colors.black),
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
                ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.orange)),
                    onPressed: () {
                      onSearch();
                    },
                    child:
                        Text("Search", style: TextStyle(color: Colors.black))),
                userMap!["0"] != "0"
                    ? GestureDetector(
                        onTap: () {
                          String roomId = chatRoomId(
                              _auth.currentUser!.displayName!,
                              userMap!["name"]);
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatRoom(
                                    chatRoomId: roomId,
                                    userMap: userMap,
                                  )));
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.verified_user_rounded),
                          ),
                          title: Text(
                            userMap!["name"],
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          subtitle: Text(userMap!["email"],
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      )
                    : ListTile(
                        title: Text("No Result Found"),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          child: Icon(
            Icons.group,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => GroupChatHomeScreen()));
          }),
    );
  }
}

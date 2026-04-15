import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final labelController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  void openNoteBox({String? docId, String? title, String? content, String? label}) {
    titleController.text = title ?? '';
    contentController.text = content ?? '';
    labelController.text = label ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? "Add Note" : "Update Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(hintText: "Title")),
            TextField(controller: contentController, decoration: const InputDecoration(hintText: "Content")),
            TextField(controller: labelController, decoration: const InputDecoration(hintText: "Label (e.g. Work, Personal)")),
          ],
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              if (docId == null) {
                firestoreService.addNote(titleController.text, contentController.text, labelController.text);
              } else {
                firestoreService.updateNote(docId, titleController.text, contentController.text, labelController.text);
              }
              Navigator.pop(context);
            },
            child: Text(docId == null ? "Create" : "Update"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Firebase Notes'),
        actions: [IconButton(onPressed: logout, icon: const Icon(Icons.logout))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List notesList = snapshot.data!.docs;

          return GridView.builder(
            itemCount: notesList.length,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              DocumentSnapshot document = notesList[index];
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              String docId = document.id;
              String title = data['title'] ?? '';
              String content = data['content'] ?? '';
              String label = data['label'] ?? 'No Label';

              // --- LOGIKA MENAMPILKAN TANGGAL ---
              Timestamp? timestamp = data['createdAt']; // Mengambil field createdAt dari Firestore
              String formattedDate = "";
              if (timestamp != null) {
                DateTime dateTime = timestamp.toDate();
                formattedDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
              }

              return Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              // Menampilkan Tanggal di bawah judul
                              Text(formattedDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text(content, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)),
                                child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.blue)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => openNoteBox(docId: docId, title: title, content: content, label: label),
                            icon: const Icon(Icons.edit, size: 20),
                          ),
                          IconButton(
                            onPressed: () => firestoreService.deleteNote(docId),
                            icon: const Icon(Icons.delete, size: 20),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
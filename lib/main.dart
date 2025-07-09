import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Parser',
      home: TaskInputScreen(),
    );
  }
}

class TaskInputScreen extends StatefulWidget {
  const TaskInputScreen({super.key});

  @override
  _TaskInputScreenState createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String,dynamic>> _tasks = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();


  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task Coach")),
      body: Padding(padding: const EdgeInsets.all(16.0),
      child: Center(
  
            child: LayoutBuilder(
              builder: (context, constraints) {
              double maxWidth = constraints.maxWidth < 700 ? constraints.maxWidth * 0.9 :600;
              return SizedBox(
                width: maxWidth,
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _tasks.length,
                      itemBuilder:(context,index) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color.fromARGB(255, 93, 147, 255)),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color.fromARGB(255, 202, 219, 255),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _tasks[index]['done'], 
                                  onChanged: (value) {
                                    setState(() {
                                      _tasks[index]['done'] = value!;
                                    });
                                  },
                                  ),
                                
                              ),
                              SizedBox(width: 12),
                              Expanded(child: Text(
                                _tasks[index]['title'],
                                style: TextStyle(
                                  decoration: _tasks[index]['done']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                  color: _tasks[index]['done'] ? Colors.grey : Colors.black,
                                  fontSize: 16,

                                  ),
                                ),
                              ),
                              IconButton(onPressed: () {
                                setState(() {
                                  _tasks.removeAt(index);
                                });
                                
                              }, icon: Icon(Icons.delete, color: const Color.fromARGB(255, 127, 152, 178),))
                            ]
                          )

                        );
                      },
                  ),
                  ),
                  
                  TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 1,
                  cursorColor: Color.fromARGB(255, 152, 17, 24),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'What do you need to do today?',
                    
                  ),
                  onSubmitted:(value) {
                    if(value.trim().isNotEmpty) {
                      setState(() {
                        _tasks.add({
                          "title": value.trim(),
                          "done": false,
                        });
                      _controller.clear();
                      _focusNode.requestFocus();
                      });
                      Future.delayed(Duration(milliseconds: 100), () {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    });
                    }
                  },

                ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child:  
                  ElevatedButton(
                    onPressed: () async {
                      final inputText = _controller.text.trim(); // 👈 read first!
                      if (inputText.isNotEmpty) {
                        // setState(() {
                        //   _tasks.add({
                        //     "title": inputText,
                        //     "done": false,
                        //   });
                        //   _controller.clear();
                       

                        print("📝 Input text: $inputText");

                        final aiTasks = await fetchTasksFromAI(inputText); // use the saved value!

                        setState(() {
                          _tasks.addAll(aiTasks);
                          _controller.clear();
                          _focusNode.requestFocus();

                        });

                        // Scroll to bottom to show new tasks
                        Future.delayed(Duration(milliseconds: 100), () {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        });
                      }
                    },
                    child: Text("Coachalize Tasks!"),

                  )

                  
                  )
        

                ],
                ),
                
              );
            },
            ),
        


      ),
      ),
    );
  }


  Future<List<Map<String, dynamic>>> fetchTasksFromAI(String inputText) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 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',
      },
      body: jsonEncode({
        "model": "llama3-70b-8192",
        "messages": [
          {
            "role": "system",
            "content": "You are a helpful assistant that extracts short, clear tasks from a sentence. Respond in only a JSON list of task objects with a title field, like: [{\"title\": \"Buy milk\"}, {\"title\": \"Call mom\"}]"
          },
          {
            "role": "user",
            "content": inputText
          }
        ],
        "temperature": 0.3
      }),
    );

    if (response.statusCode == 200) {
      print("🔵 Raw response: ${response.body}");

      final Map<String, dynamic> json = jsonDecode(response.body);
      final content = json["choices"][0]["message"]["content"];

      print("🎯 Extracted content: $content");

      // Parse the content again because it's a stringified list
      final List<dynamic> parsed = jsonDecode(content);

      // Ensure each item is a Map with a "title"
      return parsed.map<Map<String, dynamic>>((item) {
        return {"title": item["title"], "done": false};
      }).toList();
    } else {
      print("❌ Error: ${response.statusCode} - ${response.body}");
      throw Exception("Failed to fetch tasks from AI");
    }
  }

}
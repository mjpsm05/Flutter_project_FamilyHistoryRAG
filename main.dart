import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FamilyHistoryApp());
}

class FamilyHistoryApp extends StatelessWidget {
  const FamilyHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family History RAG Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

// Authentication Screen
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  
  // API URL - Replace with your actual backend URL when deployed
  final String apiUrl = "http://0.0.0.0:5001";
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    
    if (username != null) {
      // User already logged in, navigate to chat screen
      _navigateToChatScreen(username);
    }
  }
  
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "password": _passwordController.text,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        // Save login info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username']);
        
        // Navigate to chat screen
        _navigateToChatScreen(data['username']);
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _navigateToChatScreen(String username) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(username: username),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family History RAG Chatbot'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.family_restroom,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                              _login();  // Call login when Enter is pressed
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                              _login();  // Call login when Enter is pressed
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Login', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const ExpansionTile(
                  title: Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome to the Family History RAG Chatbot!',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                              'This chatbot allows you to ask questions about your family\'s history, and it will respond based on the information stored in the database.'),
                          SizedBox(height: 16),
                          Text('How to Use:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('1. Login with your username and password.'),
                          Text('2. Ask questions about your family history.'),
                          Text('3. Log out when you\'re done.'),
                          SizedBox(height: 16),
                          Text('Created by Mazamesso Meba',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Message Model
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  Message({
    required this.text, 
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Chat Screen
class ChatScreen extends StatefulWidget {
  final String username;
  
  const ChatScreen({super.key, required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  // API URL - Replace with your actual backend URL when deployed
  final String apiUrl = "http://0.0.0.0:5001";
  
  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      Message(
        text: "Welcome ${widget.username}! How can I help you with your family history today?",
        isUser: false,
      )
    );
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    // Add user message to chat
    setState(() {
      _messages.add(Message(text: message, isUser: true));
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/query'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": message,
          "username": widget.username,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _messages.add(Message(text: data['response'], isUser: false));
        });
      } else {
        setState(() {
          _messages.add(Message(
            text: data['message'] ?? "Sorry, I couldn't find an answer to that question.",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(Message(
          text: "Network error. Please check your connection and try again.",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }
  
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  void _clearChat() {
  setState(() {
    _messages.clear();  // Clear chat history
    _messages.add(
      Message(
        text: "Welcome ${widget.username}! How can I help you with your family history today?",
        isUser: false,
      ),
    );  // Add a new welcome message
  });
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family History - ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
        )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Start a conversation!'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(message: message);
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your family history...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      minLines: 1,
                      maxLines: 1, //allow only one line of input
                      keyboardType: TextInputType.text, //prevent multiline input
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (value) {
                        if (_messageController.text.isNotEmpty) {
                          _sendMessage();  // Call _sendMessage when Enter is pressed
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: Colors.blue,
                    elevation: 2,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Message Bubble Component
class MessageBubble extends StatelessWidget {
  final Message message;
  
  const MessageBubble({super.key, required this.message});
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
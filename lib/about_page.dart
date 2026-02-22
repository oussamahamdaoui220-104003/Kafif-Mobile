import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // 🔷 Floating Gradient App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'About BlindAssist',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Body content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [

                  _appCard(),

                  const SizedBox(height: 20),
                  _sectionTitle("Key Features"),

                  _featureCard(Icons.camera_alt, "Automatic Scanning", "Hands-free camera capture"),
                  _featureCard(Icons.memory, "Offline AI Model", "No internet required"),
                  _featureCard(Icons.volume_up, "Voice Output", "Speaks the result aloud"),
                  _featureCard(Icons.accessibility_new, "Blind-Friendly", "Large touch zones + TTS"),

                  const SizedBox(height: 24),
                  _sectionTitle("Disclaimer"),

                  _disclaimerCard(),

                  const SizedBox(height: 24),
                  _sectionTitle("Project Credits"),

                  _infoCard(Icons.person, "Student", "Oussama Hamdaoui"),
                  _infoCard(Icons.school, "Supervisor", "Dr. Chtouki Youssra"),
                  _infoCard(Icons.description, "Project Type", "Capstone Project"),
                  _infoCard(Icons.link, "GitHub", "https://github.com/your-username/blindassist"),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔷 Title Card
  Widget _appCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.deepPurple.shade100,
            child: Icon(Icons.monetization_on, size: 30, color: Colors.deepPurple),
          ),
          title: Text(
            'BlindAssist',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('AI for Moroccan currency recognition'),
        ),
      ),
    );
  }

  // 🟣 Feature Card
  Widget _featureCard(IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green[800]),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  // 🟠 Disclaimer Card
  Widget _disclaimerCard() {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade200,
          child: Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
        ),
        title: Text("Student Project", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "BlindAssist is a student capstone project. It may misclassify currency and should not be used for financial validation.",
        ),
      ),
    );
  }

  // 🔹 Info Cards (GitHub, Credits)
  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue[800]),
        ),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  // 🔸 Section Title
  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }
}

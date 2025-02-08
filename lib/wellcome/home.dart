import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// The initial list view showing Document IDs from the 'ppm' collection.
class WelcomeView extends StatelessWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents List'),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('ppm').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                return Card(
                  color: Colors.grey[800],
                  child: ListTile(
                    title: Text(
                      doc.id,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // When tapping the document, navigate to its real-time detail view.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailRealTimeView(documentId: doc.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The detailed view that shows real-time updates for a particular document.
class DetailRealTimeView extends StatelessWidget {
  final String documentId;
  const DetailRealTimeView({Key? key, required this.documentId})
      : super(key: key);

  /// Helper method to format a Firestore Timestamp.
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      // Format date & time (e.g., "February 6, 2025 at 2:27:48PM")
      String formattedDate =
          DateFormat("MMMM d, yyyy 'at' h:mm:ssa").format(dateTime);
      // Get the timezone offset in hours and minutes.
      final offset = dateTime.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60);
      // Format the timezone offset as "UTC+5:30" or "UTC-4:00"
      String formattedOffset =
          "UTC${hours >= 0 ? '+' : '-'}${hours.abs()}:${minutes.toString().padLeft(2, '0')}";
      return "$formattedDate $formattedOffset";
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document: $documentId'),
        backgroundColor: Colors.grey[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          // Listen to real-time updates for the selected document.
          stream: FirebaseFirestore.instance
              .collection('ppm')
              .doc(documentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text(
                'No data available',
                style: TextStyle(color: Colors.white),
              );
            }

            // Retrieve the document data.
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final soundDb = data['dB'] ?? 'N/A';
            final coPpm = data['ppm'] ?? 'N/A';
            final lastUpdated = _formatTimestamp(data['time']);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display the last updated time.
                  Text(
                    'Last Updated: $lastUpdated',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      // Card for Sound (dB)
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: Colors.blueGrey[800],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.volume_up,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Sound (dB)',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$soundDb',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Card for CO Gas (ppm)
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: Colors.deepOrange[800],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.smoke_free,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'CO Gas (ppm)',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$coPpm',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

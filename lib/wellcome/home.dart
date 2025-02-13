import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// Main view: Displays a list of unique names (one tile per name).
class WelcomeView extends StatelessWidget {
  const WelcomeView({Key? key}) : super(key: key);

  // Helper function to format Firestore Timestamps.
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      String formattedDate =
          DateFormat("MMMM d, yyyy 'at' h:mm:ssa").format(dateTime);
      final offset = dateTime.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60);
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

            // Group documents by unique name (using doc ID if no name is provided).
            final Map<String, DocumentSnapshot> uniqueDocs = {};
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? doc.id;
              if (!uniqueDocs.containsKey(name)) {
                uniqueDocs[name] = doc;
              }
            }
            final uniqueNames = uniqueDocs.keys.toList();

            return ListView.builder(
              itemCount: uniqueNames.length,
              itemBuilder: (context, index) {
                final name = uniqueNames[index];
                final doc = uniqueDocs[name]!;
                final data = doc.data() as Map<String, dynamic>;
                final soundDb = data['dB'] ?? 'N/A';
                final coPpm = data['ppm'] ?? 'N/A';
                final timeFormatted = formatTimestamp(data['time']);

                return Card(
                  color: Colors.grey[800],
                  child: ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      // Navigate to the detail view that shows graphs for all documents with this name.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailGroupView(name: name),
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

/// Detail view: Displays two graphs (dB vs time and ppm vs time) for all documents sharing the same name,
/// using only data from the last 24 hours.
class DetailGroupView extends StatelessWidget {
  final String name;
  const DetailGroupView({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define the cutoff DateTime for the last 24 hours.
    DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));

    return Scaffold(
      appBar: AppBar(
        title: Text('Graphs for "$name"'),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: const Color.fromARGB(255, 36, 36, 36),
      body: StreamBuilder<QuerySnapshot>(
        // Query all documents with the tapped name.
        stream: FirebaseFirestore.instance
            .collection('ppm')
            .where('name', isEqualTo: name)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No data available for this name',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Extract and sort the data points from the last 24 hours.
          List<Map<String, dynamic>> points = [];
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['time'] != null &&
                data['dB'] != null &&
                data['ppm'] != null) {
              Timestamp ts = data['time'];
              DateTime dt = ts.toDate();
              if (dt.isBefore(cutoff))
                continue; // Only include data from last 24 hours.
              double dbValue;
              double ppmValue;
              try {
                dbValue = (data['dB'] is num)
                    ? (data['dB'] as num).toDouble()
                    : double.tryParse(data['dB'].toString()) ?? 0.0;
                ppmValue = (data['ppm'] is num)
                    ? (data['ppm'] as num).toDouble()
                    : double.tryParse(data['ppm'].toString()) ?? 0.0;
              } catch (e) {
                dbValue = 0.0;
                ppmValue = 0.0;
              }
              points.add({
                'time': dt,
                'db': dbValue,
                'ppm': ppmValue,
              });
            }
          }
          // Sort points by time.
          points.sort((a, b) => a['time'].compareTo(b['time']));
          if (points.isEmpty) {
            return const Center(
                child: Text(
              'No valid data available in the last 24 hours',
              style: TextStyle(color: Colors.white),
            ));
          }

          // Use the earliest timestamp in the points as the reference.
          int minTimestamp = points.first['time'].millisecondsSinceEpoch;

          // Build lists of FlSpot for dB and ppm.
          List<FlSpot> dbSpots = points.map((p) {
            double x =
                (p['time'].millisecondsSinceEpoch - minTimestamp) / 1000.0;
            double y = p['db'];
            return FlSpot(x, y);
          }).toList();

          List<FlSpot> ppmSpots = points.map((p) {
            double x =
                (p['time'].millisecondsSinceEpoch - minTimestamp) / 1000.0;
            double y = p['ppm'];
            return FlSpot(x, y);
          }).toList();

          // Check if any point is in the "high" range for dB (> 11) or ppm (> 40)
          final bool showWarning =
              points.any((p) => p['db'] > 11 || p['ppm'] > 40);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conditionally show a warning banner.
                  if (showWarning)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      color: Colors.red,
                      child: const Text(
                        "Warning: High values detected! (dB > 11 or ppm > 40)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // dB vs Time Chart and Legend.
                  TimeSeriesChart(
                    title: 'dB vs Time',
                    spots: dbSpots,
                    minTimestamp: minTimestamp,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 10, height: 10, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text("11 < dB - high",
                          style: TextStyle(color: Colors.red)),
                      const SizedBox(width: 16),
                      Container(width: 10, height: 10, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text("11 > dB - low",
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // ppm vs Time Chart and Legend.
                  TimeSeriesChart(
                    title: 'ppm vs Time',
                    spots: ppmSpots,
                    minTimestamp: minTimestamp,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 10, height: 10, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text("40 < ppm - high",
                          style: TextStyle(color: Colors.red)),
                      const SizedBox(width: 16),
                      Container(width: 10, height: 10, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text("40 > ppm - low",
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A reusable widget that draws a time series line chart using fl_chart.
/// The x-axis is computed as seconds elapsed from [minTimestamp].
class TimeSeriesChart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final int minTimestamp; // in milliseconds

  const TimeSeriesChart({
    Key? key,
    required this.title,
    required this.spots,
    required this.minTimestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Text('No data for $title',
          style: const TextStyle(color: Colors.white));
    }
    double minX = spots.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    double maxX = spots.map((e) => e.x).reduce((a, b) => a > b ? a : b);
    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double yRange = maxY - minY;
    double yPadding = yRange * 0.1;
    if (yPadding == 0) {
      yPadding = 1.0;
    }
    // Ensure the x-axis interval is not zero.
    double xInterval = (maxX - minX) > 0 ? (maxX - minX) / 5 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY - yPadding,
              maxY: maxY + yPadding,
              lineTouchData: LineTouchData(enabled: true),
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) {
                      // Convert the x value (in seconds offset) back to a DateTime.
                      int timestamp = minTimestamp + (value * 1000).toInt();
                      DateTime dt =
                          DateTime.fromMillisecondsSinceEpoch(timestamp);
                      return Text(DateFormat('HH:mm:ss').format(dt),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

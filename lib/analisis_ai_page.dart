import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalisisAiPage extends StatefulWidget {
  const AnalisisAiPage({super.key});

  @override
  State<AnalisisAiPage> createState() => _AnalisisAiPageState();
}

class _AnalisisAiPageState extends State<AnalisisAiPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text("Analisis Sentimen AI",
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // INI PENTING: Menarik semua hasil prediksi MODEL AI abang dari koleksi comments
        stream:
            FirebaseFirestore.instance.collectionGroup('comments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final commentDocs = snapshot.data!.docs;

          // --- MENGHITUNG DATA DARI MODEL AI ABANG ---
          int posCount = 0;
          int netCount = 0;
          int negCount = 0;

          for (var doc in commentDocs) {
            // Kita ambil field 'sentiment' yang sudah diisi oleh Model AI Flask abang
            String sentimentResult =
                (doc['sentiment'] ?? 'netral').toString().toLowerCase();

            if (sentimentResult == 'positif' || sentimentResult == 'positive') {
              posCount++;
            } else if (sentimentResult == 'negatif' ||
                sentimentResult == 'negative') {
              negCount++;
            } else {
              netCount++;
            }
          }

          int total = posCount + netCount + negCount;
          double pPos = total > 0 ? (posCount / total) : 0;
          double pNet = total > 0 ? (netCount / total) : 0;
          double pNeg = total > 0 ? (negCount / total) : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _sectionCard(
                  title: "Distribusi Sentimen (Hasil Model AI)",
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Donut Chart Visual
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                  sections: [
                                    _pieSection(
                                        posCount.toDouble(), Colors.green),
                                    _pieSection(
                                        netCount.toDouble(), Colors.orange),
                                    _pieSection(
                                        negCount.toDouble(), Colors.red),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Legend dengan Persentase
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _legendItem("Positif", pPos, Colors.green),
                                _legendItem("Netral", pNet, Colors.orange),
                                _legendItem("Negatif", pNeg, Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // KESIMPULAN BERDASARKAN OUTPUT MODEL
                      _buildConclusionCard(pPos, pNet, pNeg),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInfoBanner(),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET KESIMPULAN ---
  Widget _buildConclusionCard(double pos, double net, double neg) {
    String msg = "";
    IconData icon = Icons.check_circle_outline;
    Color color = Colors.green;

    if (pos > neg && pos > net) {
      msg =
          "Model AI mendeteksi mayoritas masyarakat memberikan respon POSITIF. Kinerja instansi dinilai sangat baik.";
      icon = Icons.sentiment_very_satisfied_rounded;
      color = Colors.green;
    } else if (neg > pos && neg > net) {
      msg =
          "Model AI mendeteksi tingkat ketidakpuasan (NEGATIF) yang tinggi. Diperlukan evaluasi segera pada laporan-laporan tersebut.";
      icon = Icons.warning_amber_rounded;
      color = Colors.red;
    } else {
      msg =
          "Respon masyarakat terpantau NETRAL. Masyarakat sedang menunggu tindak lanjut nyata dari laporan yang dikirim.";
      icon = Icons.sentiment_neutral_rounded;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Kesimpulan Sistem",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(msg,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
              child: Text(
                  "Data di atas adalah hasil pemrosesan Natural Language Processing (NLP) secara realtime.",
                  style: TextStyle(fontSize: 10, color: Colors.blue))),
        ],
      ),
    );
  }

  // --- HELPERS ---
  PieChartSectionData _pieSection(double val, Color col) {
    return PieChartSectionData(
        value: val, color: col, radius: 15, showTitle: false);
  }

  Widget _legendItem(String label, double percent, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: col),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text("${(percent * 100).toStringAsFixed(0)}%",
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Divider(height: 30),
        child,
      ]),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Belum ada data sentimen dari Model AI."));
  }
}

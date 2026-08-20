// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fl_chart/fl_chart.dart';

// class StatistikPage extends StatefulWidget {
//   const StatistikPage({super.key});

//   @override
//   State<StatistikPage> createState() => _StatistikPageState();
// }

// class _StatistikPageState extends State<StatistikPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF6F7FB),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         centerTitle: true,
//         title: Text("Analisis Statistik",
//             style:
//                 GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('reports').snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData)
//             return const Center(child: CircularProgressIndicator());

//           final reports = snapshot.data!.docs;
//           int total = reports.length;

//           // --- LOGIKA HITUNG STATUS ---
//           int menunggu = reports
//               .where((d) =>
//                   d['status'].toString().toLowerCase().contains('menunggu'))
//               .length;
//           int diproses = reports
//               .where((d) =>
//                   d['status'].toString().toLowerCase().contains('proses'))
//               .length;
//           int selesai = reports
//               .where((d) =>
//                   d['status'].toString().toLowerCase().contains('selesai'))
//               .length;

//           // --- LOGIKA HITUNG SENTIMEN (AI) ---
//           int positif = reports
//               .where((d) =>
//                   d['system_status'].toString().toLowerCase().contains('valid'))
//               .length;
//           int netral = reports
//               .where((d) =>
//                   d['system_status'].toString().toLowerCase().contains('cek'))
//               .length;
//           int negatif = reports
//               .where((d) => d['system_status']
//                   .toString()
//                   .toLowerCase()
//                   .contains('urgent'))
//               .length;

//           return SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 // ==========================================
//                 // 1. GRAFIK BATANG (BAR CHART)
//                 // ==========================================
//                 _sectionCard(
//                   title: "Grafik Status Laporan",
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Penanganan Laporan",
//                           style: TextStyle(fontSize: 12, color: Colors.grey)),
//                       const SizedBox(height: 30),
//                       SizedBox(
//                         height: 250,
//                         child: BarChart(
//                           BarChartData(
//                             alignment: BarChartAlignment.spaceAround,
//                             maxY: total > 0
//                                 ? (total.toDouble() + (total * 0.2))
//                                 : 10,
//                             gridData: FlGridData(
//                               show: true,
//                               drawVerticalLine: false,
//                               getDrawingHorizontalLine: (value) => FlLine(
//                                 color: Colors.grey.withOpacity(0.1),
//                                 strokeWidth: 1,
//                               ),
//                             ),
//                             borderData: FlBorderData(show: false),
//                             titlesData: FlTitlesData(
//                               leftTitles: AxisTitles(
//                                 sideTitles: SideTitles(
//                                   showTitles: true,
//                                   reservedSize: 30,
//                                   getTitlesWidget: (value, meta) => Text(
//                                     value.toInt().toString(),
//                                     style: const TextStyle(
//                                         color: Colors.grey, fontSize: 10),
//                                   ),
//                                 ),
//                               ),
//                               topTitles: const AxisTitles(
//                                   sideTitles: SideTitles(showTitles: false)),
//                               rightTitles: const AxisTitles(
//                                   sideTitles: SideTitles(showTitles: false)),
//                               bottomTitles: AxisTitles(
//                                 sideTitles: SideTitles(
//                                   showTitles: true,
//                                   reservedSize: 60,
//                                   getTitlesWidget: (val, meta) {
//                                     switch (val.toInt()) {
//                                       case 0:
//                                         return _barLabel("Menunggu", menunggu,
//                                             total, meta.axisSide);
//                                       case 1:
//                                         return _barLabel("Diproses", diproses,
//                                             total, meta.axisSide);
//                                       case 2:
//                                         return _barLabel("Selesai", selesai,
//                                             total, meta.axisSide);
//                                       default:
//                                         return const SizedBox();
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ),
//                             barGroups: [
//                               _makeGroupData(
//                                   0, menunggu.toDouble(), Colors.orange),
//                               _makeGroupData(
//                                   1, diproses.toDouble(), Colors.blue),
//                               _makeGroupData(
//                                   2, selesai.toDouble(), Colors.green),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // // ==========================================
//                 // // 2. GRAFIK DONUT (SENTIMEN AI)
//                 // // ==========================================
//                 // _sectionCard(
//                 //   title: "Grafik Sentimen (AI)",
//                 //   child: Row(
//                 //     children: [
//                 //       Expanded(
//                 //         flex: 4,
//                 //         child: SizedBox(
//                 //           height: 140,
//                 //           child: PieChart(
//                 //             PieChartData(
//                 //               centerSpaceRadius: 40,
//                 //               sectionsSpace: 2,
//                 //               sections: [
//                 //                 _pieSection(positif.toDouble(), Colors.green),
//                 //                 _pieSection(netral.toDouble(), Colors.orange),
//                 //                 _pieSection(negatif.toDouble(), Colors.red),
//                 //                 if (total == 0)
//                 //                   _pieSection(1, Colors.grey[100]!),
//                 //               ],
//                 //             ),
//                 //           ),
//                 //         ),
//                 //       ),
//                 //       const SizedBox(width: 15),
//                 //       Expanded(
//                 //         flex: 6,
//                 //         child: Column(
//                 //           mainAxisAlignment: MainAxisAlignment.center,
//                 //           children: [
//                 //             _legendItem(
//                 //                 "Positif", positif, total, Colors.green),
//                 //             _legendItem("Netral", netral, total, Colors.orange),
//                 //             _legendItem("Negatif", negatif, total, Colors.red),
//                 //           ],
//                 //         ),
//                 //       ),
//                 //     ],
//                 //   ),
//                 // ),
//                 // const SizedBox(height: 50),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // --- HELPERS BAR CHART ---
//   BarChartGroupData _makeGroupData(int x, double y, Color col) {
//     return BarChartGroupData(
//       x: x,
//       barRods: [
//         BarChartRodData(
//           toY: y,
//           color: col,
//           width: 30,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
//           backDrawRodData: BackgroundBarChartRodData(
//             show: true,
//             toY: 0,
//             color: Colors.grey[50],
//           ),
//         )
//       ],
//     );
//   }

//   Widget _barLabel(String label, int val, int total, AxisSide side) {
//     double percent = total > 0 ? (val / total) * 100 : 0;
//     return SideTitleWidget(
//       axisSide: side,
//       space: 12,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(label,
//               style: GoogleFonts.poppins(
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87)),
//           Text("${percent.toStringAsFixed(0)}%",
//               style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey)),
//         ],
//       ),
//     );
//   }

//   // --- HELPERS PIE CHART ---
//   PieChartSectionData _pieSection(double val, Color col) {
//     return PieChartSectionData(
//       value: val,
//       color: col,
//       radius: 12,
//       showTitle: false,
//     );
//   }

//   Widget _legendItem(String label, int val, int total, Color col) {
//     double percent = total > 0 ? (val / total) * 100 : 0;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         children: [
//           Container(
//               width: 7,
//               height: 7,
//               decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
//           const SizedBox(width: 10),
//           Expanded(
//               child: Text(label,
//                   style: GoogleFonts.poppins(
//                       fontSize: 11, color: Colors.black54))),
//           Text("${percent.toStringAsFixed(0)}%",
//               style: GoogleFonts.poppins(
//                   fontSize: 11,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87)),
//         ],
//       ),
//     );
//   }

//   Widget _sectionCard({required String title, required Widget child}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.02),
//               blurRadius: 20,
//               offset: const Offset(0, 5)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                   color: Colors.black87)),
//           const SizedBox(height: 20),
//           child,
//         ],
//       ),
//     );
//   }
// }

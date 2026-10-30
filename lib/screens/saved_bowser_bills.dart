import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// REMOVED permission_handler import

import '../models/bowser_bill_model.dart';
import '../db/database_helper.dart';
import 'own_bowser_bill.dart';
import 'edit_bowser_bill.dart';

class SavedBowserBillsScreen extends StatefulWidget {
  const SavedBowserBillsScreen({super.key});

  @override
  State<SavedBowserBillsScreen> createState() => _SavedBowserBillsScreenState();
}

class _SavedBowserBillsScreenState extends State<SavedBowserBillsScreen> {
  late Future<List<BowserBillModel>> _billsFuture;
  List<BowserBillModel> _allBills = [];
  List<BowserBillModel> _filteredBills = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() {
    _billsFuture = DatabaseHelper().getBowserBills().then((bills) {
      _allBills = bills;
      _filteredBills = _allBills;
      _filterBills();
      return bills;
    });
  }

  void _filterBills() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBills = _allBills;
      } else {
        _filteredBills = _allBills.where((bill) {
          final matchesVehicle = bill.vehicleNo.toLowerCase().contains(query);
          final matchesTransporter = (bill.transporterName?.toLowerCase().contains(query)) ?? false;
          return matchesVehicle || matchesTransporter;
        }).toList();
      }
    });
  }

  Future<void> _deleteBill(int id) async {
    await DatabaseHelper().deleteBowserBill(id);
    _allBills.removeWhere((bill) => bill.id == id);
    _filterBills();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bowser Bill deleted successfully!'), backgroundColor: Colors.green));
    }
  }

  // --- UNIFIED SINGLE BILL PDF FORMAT ---
  Future<void> _exportBillAsPdf(BowserBillModel bill, String filename) async {
    final pdf = pw.Document();
    final byte = await rootBundle.load('assets/images/logo.png');
    final imageData = byte.buffer.asUint8List();
    final image = pw.MemoryImage(imageData);

    String date = bill.createdAt.split('T').first;
    String vehicleNo = bill.vehicleNo;
    String transporterName = bill.transporterName ?? 'N/A';
    String loadWeight = '${bill.loadWeight} MT';
    String unloadWeight = '${bill.unloadWeight} MT';
    String total = 'Rs. ${(bill.totalRent + bill.primeMoverRent).toStringAsFixed(2)}';
    
    List<List<String>> tableData = [
      ['Total Rent', 'Rs. ${bill.rent} / unit', 'Rs. ${bill.totalRent.toStringAsFixed(2)}'],
      ['Prime Mover Rent', 'Rs. ${bill.carRent} / unit', 'Rs. ${bill.primeMoverRent.toStringAsFixed(2)}'],
      ['Bowzer Rent', 'Calculation', 'Rs. ${bill.bowzerRent.toStringAsFixed(2)}'],
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Center(
            child: pw.Stack(
              children: [
                pw.Center(child: pw.Opacity(opacity: 0.05, child: pw.Image(image, height: 600, width: 600))),
                pw.Container(
                  padding: const pw.EdgeInsets.all(30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header (No Bill Type)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Image(image, height: 50), 
                              pw.SizedBox(height: 8),
                              pw.Text('CHIRAGH GAS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                              pw.SizedBox(height: 4),
                              pw.Text('Efficient Transport, Trusted Service', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('Date: $date', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            ],
                          )
                        ]
                      ),
                      pw.SizedBox(height: 20),
                      pw.Divider(color: PdfColors.deepPurple, thickness: 2),
                      pw.SizedBox(height: 20),
                      
                      // Info Grid
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                              pw.SizedBox(height: 4),
                              pw.Text('Transporter: $transporterName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Vehicle No: $vehicleNo', style: pw.TextStyle(fontSize: 14)),
                            ]
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('WEIGHTS:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                              pw.SizedBox(height: 4),
                              pw.Text('Load: $loadWeight', style: pw.TextStyle(fontSize: 12)),
                              pw.Text('Unload: $unloadWeight', style: pw.TextStyle(fontSize: 12)),
                            ]
                          )
                        ]
                      ),
                      pw.SizedBox(height: 30),
                      
                      // Table
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey300),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2),
                          1: const pw.FlexColumnWidth(3),
                          2: const pw.FlexColumnWidth(2),
                        },
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                            children: [
                              _buildTableCellPdf('Description', isHeader: true),
                              _buildTableCellPdf('Details', isHeader: true),
                              _buildTableCellPdf('Amount', isHeader: true),
                            ]
                          ),
                          ...tableData.map((row) => pw.TableRow(
                            children: [
                              _buildTableCellPdf(row[0]),
                              _buildTableCellPdf(row[1]),
                              _buildTableCellPdf(row[2]),
                            ]
                          )),
                        ]
                      ),
                      
                      pw.SizedBox(height: 30),
                      
                      // Total Box
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.deepPurple50,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: PdfColors.deepPurple200)
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('TOTAL AMOUNT TO PAY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.SizedBox(height: 4),
                              pw.Text(total, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                            ]
                          )
                        )
                      ),
                      
                      pw.SizedBox(height: 60),
                      
                      // Signatures
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            children: [
                              pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1)))),
                              pw.SizedBox(height: 4),
                              pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                            ]
                          ),
                          pw.Column(
                            children: [
                              pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1)))),
                              pw.SizedBox(height: 4),
                              pw.Text('Receiver Signature', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                            ]
                          )
                        ]
                      )
                    ]
                  )
                )
              ]
            )
          );
        }
      )
    );

    final bytes = await pdf.save();
    await _savePdfToFile(bytes, filename);
  }

  // Helper widget for the table cell
  pw.Widget _buildTableCellPdf(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text, 
        style: pw.TextStyle(
          fontSize: 12, 
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        )
      )
    );
  }
  pw.Widget _buildInfoItemPdf(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  // --- FIXED PDF SAVE LOGIC ---
  Future<void> _savePdfToFile(Uint8List bytes, String filename) async {
    try {
      // This new method handles everything: picking folder, naming, and saving.
      // It works flawlessly on Desktop (Linux/Windows/Mac) without needing Permission checks.
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Bowser Bill PDF',
        fileName: '$filename.pdf',
        bytes: bytes, // For Web support
      );

      if (outputFile == null) {
        // User cancelled the dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF export cancelled')));
        }
        return;
      }

      // For Desktop platforms, we might need to manually write the bytes
      if (!Platform.isAndroid && !Platform.isIOS) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to: $outputFile'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showExportDialog(BowserBillModel bill) {
    final controller = TextEditingController(text: 'Bowser_${bill.vehicleNo}');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Bill as PDF'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Filename'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _exportBillAsPdf(bill, name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Bowser Bills'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => Navigator.pop(context), // <-- Goes back to the MainLayout
),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterBills(),
              decoration: InputDecoration(
                labelText: 'Search by Vehicle or Transporter',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BowserBillModel>>(
              future: _billsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (_filteredBills.isEmpty) return const Center(child: Text('No bowser bills found.'));

                return ListView.builder(
                  itemCount: _filteredBills.length,
                  itemBuilder: (context, index) {
                    final bill = _filteredBills[index];
                    return Dismissible(
                      key: Key(bill.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.shade700,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              title: const Text("Confirm Deletion", style: TextStyle(fontWeight: FontWeight.bold)),
                              content: const Text("Are you sure you want to delete this bowser bill permanently?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  child: const Text("Delete"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) => _deleteBill(bill.id!),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping, color: Colors.deepPurple, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Vehicle No: ${bill.vehicleNo}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                ],
                              ),
                              if (bill.transporterName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 28),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.business, color: Colors.blueGrey, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Transporter: ${bill.transporterName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('⬇️ Load: ${bill.loadWeight} MT', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                  Text('⬆️ Unload: ${bill.unloadWeight} MT', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                              const Divider(thickness: 1.5, height: 25),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSummaryItem('Total Rent', bill.totalRent, Colors.blue),
                                  _buildSummaryItem('Prime Mover', bill.primeMoverRent, Colors.orange),
                                  _buildSummaryItem('Bowzer Rent', bill.bowzerRent, Colors.green),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showExportDialog(bill),
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    label: const Text('Export PDF', style: TextStyle(color: Colors.red)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final updated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditBowserBillScreen(bill: bill),
                                        ),
                                      );
                                      if (updated == true) {
                                        _loadBills();
                                      }
                                    },
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                    label: const Text('Edit', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        Text('Rs ${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
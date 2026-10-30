import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// REMOVED permission_handler import

import '../models/bills_model.dart';
import '../db/database_helper.dart';
import 'edit_bills.dart';
import 'home.dart';

class SavedBillsScreen extends StatefulWidget {
  const SavedBillsScreen({super.key});

  @override
  State<SavedBillsScreen> createState() => _SavedBillsScreenState();
}

class _SavedBillsScreenState extends State<SavedBillsScreen> {
  late Future<List<BillModel>> _billsFuture;
  List<BillModel> _allBills = [];
  List<BillModel> _filteredBills = [];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedUnloadingDate;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() {
    _billsFuture = DatabaseHelper().getBills().then((bills) {
      _allBills = bills;
      _filteredBills = _allBills;
      _filterBills();
      return bills;
    });
  }

  void _filterBills() {
    final query = _searchController.text.toLowerCase();
    final date = _selectedUnloadingDate;

    setState(() {
      if (query.isEmpty && date == null) {
        _filteredBills = _allBills;
      } else {
        _filteredBills = _allBills.where((bill) {
          final matchesVehicle = bill.vehicleNo.toLowerCase().contains(query);
          final matchesTransporter = (bill.transporterName?.toLowerCase().contains(query)) ?? false;
          final matchesSearch = matchesVehicle || matchesTransporter;

          final matchesDate = date == null || bill.unloadingDate.contains(date);

          return matchesSearch && matchesDate;
        }).toList();
      }
    });
  }

  Future<void> _pickUnloadingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedUnloadingDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _filterBills();
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedUnloadingDate = null;
    });
    _filterBills();
  }

  Future<void> _deleteBill(int id) async {
    await DatabaseHelper().deleteBill(id);
    _allBills.removeWhere((bill) => bill.id == id);
    _filterBills();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- UNIFIED SINGLE BILL PDF FORMAT ---
  Future<void> _exportBillAsPdf(BillModel bill, String filename) async {
    final pdf = pw.Document();
    final byte = await rootBundle.load('assets/images/logo.png');
    final imageData = byte.buffer.asUint8List();
    final image = pw.MemoryImage(imageData);

    String date = bill.unloadingDate;
    String vehicleNo = bill.vehicleNo;
    String transporterName = bill.transporterName ?? 'N/A';
    String loadWeight = '${bill.loadingWeight} MT';
    String unloadWeight = '${bill.unloadingWeight} MT';
    String total = 'Rs. ${bill.toPay.toStringAsFixed(2)}';
    
    List<List<String>> tableData = [
      ['Base Rent (per MT)', 'Rs. ${bill.ratePerMt}', 'Rs. ${bill.tripAmount.toStringAsFixed(2)}'],
      ['Route', '${bill.loadingStation} -> ${bill.unloadingStation}', '-'],
    ];
    
    if (bill.gainLoss != 0) {
      tableData.add(['Gain/Loss', '${bill.gainLoss} KG @ Rs. ${bill.gainLossRate}', 'Rs. ${(bill.gainLoss * bill.gainLossRate).toStringAsFixed(2)}']);
    }

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
                      // pw.Row(
                      //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     pw.Column(
                      //       children: [
                      //         pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1)))),
                      //         pw.SizedBox(height: 4),
                      //         pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      //       ]
                      //     ),
                      //     pw.Column(
                      //       children: [
                      //         pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1)))),
                      //         pw.SizedBox(height: 4),
                      //         pw.Text('Receiver Signature', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      //       ]
                      //     )
                      //   ]
                      // )
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
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // --- FIXED PDF SAVE LOGIC (No Permission required on Desktop) ---
  Future<void> _savePdfToFile(Uint8List bytes, String filename) async {
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Normal Bill PDF',
        fileName: '$filename.pdf',
        bytes: bytes, // Needed for Web support
      );

      if (outputFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF export cancelled')),
          );
        }
        return;
      }

      // For Desktop platforms, manually write the bytes to the selected path
      if (!Platform.isAndroid && !Platform.isIOS) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: $outputFile'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportDialog(BillModel bill) {
    final controller = TextEditingController(text: 'Bill_${bill.vehicleNo}');
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
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

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text('Saved Bills'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => Navigator.pop(context), // <-- Goes back to the MainLayout
),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: FutureBuilder<List<BillModel>>(
        future: _billsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterBills(),
                  decoration: InputDecoration(
                    labelText: 'Search by Vehicle No or Transporter',
                    hintText: 'e.g., ABC-123 or Ali Transport',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.black,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickUnloadingDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedUnloadingDate == null
                              ? 'Filter by Unloading Date'
                              : 'Unloading: $_selectedUnloadingDate',
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedUnloadingDate != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() => _selectedUnloadingDate = null);
                            _filterBills();
                          },
                          tooltip: 'Clear Date Filter',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _filteredBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flag,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No matching bills found.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredBills.length,
                        itemBuilder: (context, index) {
                          final bill = _filteredBills[index];
                          return Dismissible(
                            key: Key(bill.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    title: const Text(
                                      "Confirm Deletion",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: const Text(
                                      "Are you sure you want to delete this bill permanently?",
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              _deleteBill(bill.id!);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_shipping,
                                          color: Colors.deepPurple,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Vehicle No: ${bill.vehicleNo}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (bill.transporterName != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          left: 28,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.business,
                                              color: Colors.blueGrey,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Transporter: ${bill.transporterName}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rent : ₹ ${bill.ratePerMt}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoItem(
                                          '📦 Loading Date',
                                          bill.loadingDate,
                                        ),
                                        _buildInfoItem(
                                          '🏁 Unloading Date',
                                          bill.unloadingDate,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoItem(
                                          '⬇️ Load Weight',
                                          '${bill.loadingWeight} MT',
                                        ),
                                        _buildInfoItem(
                                          '⬆️ Unload Weight',
                                          '${bill.unloadingWeight} MT',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildInfoItem(
                                          '📍 From',
                                          bill.loadingStation,
                                        ),
                                        _buildInfoItem(
                                          '📍 To',
                                          bill.unloadingStation,
                                        ),
                                      ],
                                    ),
                                    if (bill.gainLoss != 0)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10),
                                        child: Text(
                                          'Gain/Loss: ${bill.gainLoss} KG * ${bill.gainLossRate} = ₹ ${bill.gainLoss * bill.gainLossRate}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    const Divider(thickness: 1.5, height: 25),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.payments,
                                          color: Colors.green,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Total To Pay: ₹ ${bill.toPay.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showExportDialog(bill),
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'Export PDF',
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final updated = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditBillScreen(bill: bill),
                                              ),
                                            );
                                            if (updated == true) _loadBills();
                                          },
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
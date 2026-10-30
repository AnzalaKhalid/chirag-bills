import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../db/database_helper.dart';
import '../models/transporter_model.dart';
import '../models/bills_model.dart';
import '../models/bowser_bill_model.dart'; 
import 'edit_bills.dart'; 
import 'edit_bowser_bill.dart'; 

class TransportersScreen extends StatefulWidget {
  const TransportersScreen({super.key});

  @override
  State<TransportersScreen> createState() => _TransportersScreenState();
}

class _TransportersScreenState extends State<TransportersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late Future<List<TransporterModel>> _transportersFuture;

  @override
  void initState() {
    super.initState();
    _loadTransporters();
  }

  void _loadTransporters() {
    setState(() {
      _transportersFuture = DatabaseHelper().getTransporters();
    });
  }

  void _addTransporter() async {
    if (!_formKey.currentState!.validate()) return;

    final transporter = TransporterModel(
      name: _nameController.text.trim(),
      phone: '', 
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await DatabaseHelper().insertTransporter(transporter);
      _nameController.clear();
      _loadTransporters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transporter Added Successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding transporter: $e');
    }
  }

  void _openLedger(TransporterModel transporter) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TransporterLedgerScreen(transporter: transporter)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Transporters'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Transporter Name', 
                            prefixIcon: Icon(Icons.business), 
                            border: OutlineInputBorder()
                          ),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _addTransporter,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<TransporterModel>>(
                future: _transportersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No transporters added yet.'));

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final t = snapshot.data![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.deepPurple, 
                            child: Icon(Icons.local_shipping, color: Colors.white)
                          ),
                          title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu_book, color: Colors.blue), 
                                tooltip: 'View Ledger', 
                                onPressed: () => _openLedger(t)
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  await DatabaseHelper().deleteTransporter(t.id!);
                                  _loadTransporters();
                                },
                              ),
                            ],
                          ),
                          onTap: () => _openLedger(t),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LEDGER SCREEN
// ============================================================================

class TransporterLedgerScreen extends StatefulWidget {
  final TransporterModel transporter;
  const TransporterLedgerScreen({super.key, required this.transporter});

  @override
  State<TransporterLedgerScreen> createState() => _TransporterLedgerScreenState();
}

class _TransporterLedgerScreenState extends State<TransporterLedgerScreen> {
  late Future<List<dynamic>> _combinedBillsFuture;
  List<dynamic> _allBills = [];
  List<dynamic> _filteredBills = [];
  
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() {
    _combinedBillsFuture = _fetchCombinedBills().then((bills) {
      _allBills = bills;
      _filteredBills = _allBills;
      _filterBills();
      return bills;
    });
  }

  Future<List<dynamic>> _fetchCombinedBills() async {
    final normalBills = await DatabaseHelper().getBillsByTransporter(widget.transporter.id!);
    final bowserBills = await DatabaseHelper().getBowserBillsByTransporter(widget.transporter.id!);

    List<dynamic> combined = [...normalBills, ...bowserBills];

    // Sort by date (Newest first)
    combined.sort((a, b) {
      String dateA = a is BillModel ? a.unloadingDate : (a as BowserBillModel).createdAt;
      String dateB = b is BillModel ? b.unloadingDate : (b as BowserBillModel).createdAt;
      return dateB.compareTo(dateA);
    });

    return combined;
  }

  void _filterBills() {
    final query = _searchController.text.toLowerCase();
    final date = _selectedDate;

    setState(() {
      if (query.isEmpty && date == null) {
        _filteredBills = _allBills;
      } else {
        _filteredBills = _allBills.where((bill) {
          final matchesVehicle = bill.vehicleNo.toLowerCase().contains(query);
          
          String dateStr = bill is BillModel ? bill.unloadingDate : (bill as BowserBillModel).createdAt;
          final matchesDate = date == null || dateStr.contains(date);

          return matchesVehicle && matchesDate;
        }).toList();
      }
    });
  }

  Future<void> _pickDate() async {
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _filterBills();
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedDate = null;
    });
    _filterBills();
  }

  Future<void> _deleteBill(dynamic bill) async {
    if (bill is BillModel) {
      await DatabaseHelper().deleteBill(bill.id!);
    } else if (bill is BowserBillModel) {
      await DatabaseHelper().deleteBowserBill(bill.id!);
    }
    _allBills.remove(bill); 
    _filterBills();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill deleted successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  // --- EXPORT FULL LEDGER (STATEMENT FORMAT) ---
  Future<void> _exportLedgerAsPdf() async {
    final pdf = pw.Document();
    final byte = await rootBundle.load('assets/images/logo.png');
    final imageData = byte.buffer.asUint8List();
    final image = pw.MemoryImage(imageData);

    double totalAmount = 0;
    for (var bill in _filteredBills) {
      if (bill is BillModel) {
        totalAmount += bill.toPay;
      } else if (bill is BowserBillModel) {
        totalAmount += (bill.totalRent + bill.primeMoverRent);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Image(image, height: 60),
                  pw.SizedBox(height: 10),
                  pw.Text('CHIRAGH GAS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                  pw.SizedBox(height: 5),
                  pw.Text('Transporter Ledger Statement', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Transporter: ${widget.transporter.name}', style: pw.TextStyle(fontSize: 14, color: PdfColors.blueGrey700, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Date Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Vehicle No', 'Load Wt', 'Unload Wt', 'Details', 'Amount (Rs.)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8), // Date
                1: const pw.FlexColumnWidth(2.0), // Vehicle
                2: const pw.FlexColumnWidth(1.5), // Load
                3: const pw.FlexColumnWidth(1.5), // Unload
                4: const pw.FlexColumnWidth(3.5), // Details
                5: const pw.FlexColumnWidth(1.8), // Amount
              },
              data: _filteredBills.map((bill) {
                if (bill is BillModel) {
                  return [
                    bill.unloadingDate,
                    bill.vehicleNo,
                    '${bill.loadingWeight} MT',
                    '${bill.unloadingWeight} MT',
                    'Base Rent: Rs. ${bill.ratePerMt}\n(${bill.loadingStation} -> ${bill.unloadingStation})',
                    bill.toPay.toStringAsFixed(2),
                  ];
                } else {
                  final b = bill as BowserBillModel;
                  return [
                    b.createdAt.split('T').first,
                    b.vehicleNo,
                    '${b.loadWeight} MT',
                    '${b.unloadWeight} MT',
                    'Rent: Rs. ${b.rent}\nCar Rent: Rs. ${b.carRent}',
                    (b.totalRent + b.primeMoverRent).toStringAsFixed(2),
                  ];
                }
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Total Bills: ${_filteredBills.length}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Grand Total: Rs. ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await _savePdfToFile(bytes, 'Ledger_${widget.transporter.name.replaceAll(' ', '_')}');
  }

  // --- EXPORT SINGLE BILL (INVOICE FORMAT) ---
  Future<void> _exportBillPdf(dynamic bill, String filename) async {
    final pdf = pw.Document();
    final byte = await rootBundle.load('assets/images/logo.png');
    final imageData = byte.buffer.asUint8List();
    final image = pw.MemoryImage(imageData);

    final isNormal = bill is BillModel;
    
    String vehicleNo = bill.vehicleNo;
    String transporterName = bill.transporterName ?? 'N/A';
    String date = isNormal ? bill.unloadingDate : (bill as BowserBillModel).createdAt.split('T').first;
    String loadWeight = isNormal ? '${bill.loadingWeight} MT' : '${(bill as BowserBillModel).loadWeight} MT';
    String unloadWeight = isNormal ? '${bill.unloadingWeight} MT' : '${(bill as BowserBillModel).unloadWeight} MT';
    String total = isNormal ? 'Rs. ${bill.toPay.toStringAsFixed(2)}' : 'Rs. ${((bill as BowserBillModel).totalRent + (bill as BowserBillModel).primeMoverRent).toStringAsFixed(2)}';
    
    List<List<String>> tableData = [];
    
    if (isNormal) {
      tableData.add(['Base Rent (per MT)', 'Rs. ${bill.ratePerMt}', 'Rs. ${bill.tripAmount.toStringAsFixed(2)}']);
      tableData.add(['Route', '${bill.loadingStation} -> ${bill.unloadingStation}', '-']);
      if (bill.gainLoss != 0) {
        tableData.add(['Gain/Loss', '${bill.gainLoss} KG @ Rs. ${bill.gainLossRate}', 'Rs. ${(bill.gainLoss * bill.gainLossRate).toStringAsFixed(2)}']);
      }
    } else {
      final b = bill as BowserBillModel;
      tableData.add(['Total Rent', 'Rs. ${b.rent} / unit', 'Rs. ${b.totalRent.toStringAsFixed(2)}']);
      tableData.add(['Prime Mover Rent', 'Rs. ${b.carRent} / unit', 'Rs. ${b.primeMoverRent.toStringAsFixed(2)}']);
      tableData.add(['Bowzer Rent', 'Calculation', 'Rs. ${b.bowzerRent.toStringAsFixed(2)}']);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Center(
            child: pw.Stack(
              children: [
                // Watermark
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
                              _buildTableCell('Description', isHeader: true),
                              _buildTableCell('Details', isHeader: true),
                              _buildTableCell('Amount', isHeader: true),
                            ]
                          ),
                          ...tableData.map((row) => pw.TableRow(
                            children: [
                              _buildTableCell(row[0]),
                              _buildTableCell(row[1]),
                              _buildTableCell(row[2]),
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

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
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

  Future<void> _savePdfToFile(Uint8List bytes, String filename) async {
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: '$filename.pdf',
        bytes: bytes,
      );

      if (outputFile == null) return;

      if (!Platform.isAndroid && !Platform.isIOS) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved to: $outputFile'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e'), backgroundColor: Colors.red));
    }
  }

  void _showExportDialog(dynamic bill) {
    final controller = TextEditingController(text: 'Bill_${bill.vehicleNo}');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Bill as PDF'),
          content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Filename')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _exportBillPdf(bill, name);
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
        title: Text('${widget.transporter.name} - Ledger'), 
        backgroundColor: Colors.deepPurple, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Ledger as PDF',
            onPressed: _exportLedgerAsPdf,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _combinedBillsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          double totalAmount = 0;
          for (var bill in _filteredBills) {
            if (bill is BillModel) {
              totalAmount += bill.toPay;
            } else if (bill is BowserBillModel) {
              totalAmount += (bill.totalRent + bill.primeMoverRent);
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterBills(),
                  decoration: InputDecoration(
                    labelText: 'Search by Vehicle No',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_selectedDate == null ? 'Filter by Date' : 'Date: $_selectedDate'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() => _selectedDate = null);
                            _filterBills();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.deepPurple.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Text('Total Bills: ${_filteredBills.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Total Amount: Rs. ${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                ),
              ),
              
              Expanded(
                child: _filteredBills.isEmpty
                    ? const Center(child: Text('No matching bills found.'))
                    : ListView.builder(
                        itemCount: _filteredBills.length,
                        itemBuilder: (context, index) {
                          final bill = _filteredBills[index];
                          bool isNormal = bill is BillModel;

                          return Dismissible(
                            key: Key('${isNormal ? 'normal' : 'bowser'}_${bill.id}'),
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
                                    title: const Text("Confirm Deletion"),
                                    content: const Text("Are you sure you want to delete this bill permanently?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) => _deleteBill(bill),
                            child: isNormal
                                ? _buildNormalBillCard(bill as BillModel)
                                : _buildBowserBillCard(bill as BowserBillModel),
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

  Widget _buildNormalBillCard(BillModel bill) {
    return Card(
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
                const Icon(Icons.receipt_long, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                Text('Normal Bill - ${bill.vehicleNo}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Rent : Rs. ${bill.ratePerMt}', style: const TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('📦 Loading Date', bill.loadingDate),
                _buildInfoItem('🏁 Unloading Date', bill.unloadingDate),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('⬇️ Load Weight', '${bill.loadingWeight} MT'),
                _buildInfoItem('⬆️ Unload Weight', '${bill.unloadingWeight} MT'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('📍 From', bill.loadingStation),
                _buildInfoItem('📍 To', bill.unloadingStation),
              ],
            ),
            if (bill.gainLoss != 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Gain/Loss: ${bill.gainLoss} KG * ${bill.gainLossRate} = Rs. ${bill.gainLoss * bill.gainLossRate}', style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
              ),
            const Divider(thickness: 1.5, height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments, color: Colors.green, size: 22),
                    const SizedBox(width: 6),
                    Text('Total To Pay: Rs. ${bill.toPay.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showExportDialog(bill),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: const Text('Export PDF', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditBillScreen(bill: bill)));
                        if (updated == true) _loadBills();
                      },
                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                      label: const Text('Edit', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBowserBillCard(BowserBillModel bill) {
    return Card(
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
                const Icon(Icons.local_shipping, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('Bowser Bill - ${bill.vehicleNo}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
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
                    final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditBowserBillScreen(bill: bill)));
                    if (updated == true) _loadBills();
                  },
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  label: const Text('Edit', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        Text('Rs. ${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
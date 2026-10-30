import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/bills_model.dart';
import '../models/transporter_model.dart';
import 'saved_bills.dart';

class BillMakingApp extends StatefulWidget {
  const BillMakingApp({super.key});

  @override
  State<BillMakingApp> createState() => _BillMakingAppState();
}

class _BillMakingAppState extends State<BillMakingApp> {
  final _formKey = GlobalKey<FormState>();

  final vehicleNoController = TextEditingController();
  final loadingWeightController = TextEditingController();
  final unloadingWeightController = TextEditingController();
  final ratePerMtController = TextEditingController();
  final gainLossController = TextEditingController();
  final gainLossRateController = TextEditingController();

  String? loadingDate;
  String? unloadingDate;
  String? loadingStation;
  String? unloadingStation;
  double? totalAmount;

  List<TransporterModel> _transporters = [];
  TransporterModel? _selectedTransporter;

  final List<String> loadingStationOptions = ['250B', 'MAND', 'KARACHI'];
  final List<String> unloadingStationOptions = ['KHI', 'HYD', 'PUNJAB', 'MITTI', 'DADU', 'QUETTA', 'GAMBAT', 'DHOLAT PUR'];

  @override
  void initState() {
    super.initState();
    _loadTransporters();
  }

  void _loadTransporters() async {
    final transporters = await DatabaseHelper().getTransporters();
    if (mounted) {
      setState(() {
        _transporters = transporters;
      });
    }
  }

  @override
  void dispose() {
    vehicleNoController.dispose();
    loadingWeightController.dispose();
    unloadingWeightController.dispose();
    ratePerMtController.dispose();
    gainLossController.dispose();
    gainLossRateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isLoadingDate}) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme), child: child!);
      },
    );
    if (date != null) {
      setState(() {
        final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        if (isLoadingDate) {
          loadingDate = formatted;
        } else {
          unloadingDate = formatted;
        }
      });
    }
  }

  void calculateAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicleNo = vehicleNoController.text;
    final loadingWeight = double.tryParse(loadingWeightController.text) ?? 0;
    final unloadingWeight = double.tryParse(unloadingWeightController.text) ?? 0;
    final ratePerMt = double.tryParse(ratePerMtController.text) ?? 0;
    final gainLoss = double.tryParse(gainLossController.text) ?? 0;
    final gainLossRate = double.tryParse(gainLossRateController.text) ?? 0;

    double tripAmount = (gainLoss != 0 ? loadingWeight : unloadingWeight) * ratePerMt;
    double toPay = tripAmount;

    if (gainLoss > 0) {
      toPay += gainLoss * gainLossRate;
    } else if (gainLoss < 0) {
      toPay -= (-gainLoss) * gainLossRate;
    }

    final bill = BillModel(
      transporterId: _selectedTransporter?.id,
      vehicleNo: vehicleNo,
      loadingDate: loadingDate!,
      unloadingDate: unloadingDate!,
      loadingWeight: loadingWeight,
      loadingStation: loadingStation!,
      ratePerMt: ratePerMt,
      unloadingWeight: unloadingWeight,
      unloadingStation: unloadingStation!,
      gainLoss: gainLoss,
      gainLossRate: gainLossRate,
      tripAmount: tripAmount,
      remainingAmount: toPay,
      toPay: toPay,
    );

    await DatabaseHelper().insertBill(bill);

    setState(() => totalAmount = toPay);

    _formKey.currentState!.reset();
    vehicleNoController.clear();
    loadingWeightController.clear();
    unloadingWeightController.clear();
    ratePerMtController.clear();
    gainLossController.clear();
    gainLossRateController.clear();
    setState(() {
      loadingDate = null;
      unloadingDate = null;
      loadingStation = null;
      unloadingStation = null;
      _selectedTransporter = null;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bill Saved Successfully", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      // CHANGED: Navigator.push instead of pushReplacement
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBillsScreen()));
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget sectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5))),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        // REMOVED the back button (leading) here
        title: Text('Normal Bills', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        actions: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: colorScheme.primary, size: 32),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // CHANGED: Navigator.push instead of pushReplacement
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBillsScreen()));
                },
                style: TextButton.styleFrom(foregroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('Saved Bills', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          final vehicleLoadingCard = Expanded(
            child: sectionCard('Transporter & Vehicle Details', [
              DropdownButtonFormField<TransporterModel>(
                decoration: inputDecoration('Select Transporter'),
                items: _transporters.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (val) => setState(() => _selectedTransporter = val),
                validator: (val) => val == null ? 'Required' : null,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                dropdownColor: colorScheme.surface,
                initialValue: _selectedTransporter,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: vehicleNoController,
                decoration: inputDecoration('Vehicle No'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorScheme.outline)),
                tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                title: Text(loadingDate == null ? 'Pick Loading Date' : 'Loading Date: $loadingDate', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                trailing: Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
                onTap: () => _pickDate(isLoadingDate: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: loadingWeightController,
                decoration: inputDecoration('Loading Weight (ton)'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: loadingStation,
                decoration: inputDecoration('Loading Station'),
                items: loadingStationOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => loadingStation = val),
                validator: (val) => val == null ? 'Required' : null,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                dropdownColor: colorScheme.surface,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ratePerMtController,
                decoration: inputDecoration('Rate per Ton'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
            ]),
          );

          final unloadingCard = Expanded(
            child: sectionCard('Unloading Details', [
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorScheme.outline)),
                tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                title: Text(unloadingDate == null ? 'Pick Unloading Date' : 'Unloading Date: $unloadingDate', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                trailing: Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
                onTap: () => _pickDate(isLoadingDate: false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: unloadingWeightController,
                decoration: inputDecoration('Unloading Weight (ton)'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: unloadingStation,
                decoration: inputDecoration('Unloading Station'),
                items: unloadingStationOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => unloadingStation = val),
                validator: (val) => val == null ? 'Required' : null,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                dropdownColor: colorScheme.surface,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: gainLossController,
                decoration: inputDecoration('Gain (+) / Loss (-) in kg'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: gainLossRateController,
                decoration: inputDecoration('Rate per kg for Gain/Loss'),
                keyboardType: TextInputType.number,
              ),
            ]),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  isWide
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [vehicleLoadingCard, const SizedBox(width: 20), unloadingCard])
                      : Column(children: [vehicleLoadingCard, unloadingCard]),
                  const SizedBox(height: 30),
                  FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Calculate and Save Bill'),
                    onPressed: calculateAndSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (totalAmount != null)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Container(
                        key: ValueKey(totalAmount),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outlineVariant)),
                        child: Text(
                          'Total Amount to Pay: Rs. ${totalAmount!.toStringAsFixed(2)}',
                          style: textTheme.headlineSmall?.copyWith(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
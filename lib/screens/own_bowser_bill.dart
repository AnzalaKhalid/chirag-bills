import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transporter_model.dart';
import '../models/bowser_bill_model.dart';
import 'saved_bowser_bills.dart';

class OwnBowserBillScreen extends StatefulWidget {
  const OwnBowserBillScreen({super.key});

  @override
  State<OwnBowserBillScreen> createState() => _OwnBowserBillScreenState();
}

class _OwnBowserBillScreenState extends State<OwnBowserBillScreen> {
  final _formKey = GlobalKey<FormState>();

  final vehicleNoController = TextEditingController();
  final loadWeightController = TextEditingController();
  final unloadWeightController = TextEditingController();
  final rentController = TextEditingController();
  final carRentController = TextEditingController();

  List<TransporterModel> _transporters = [];
  TransporterModel? _selectedTransporter;

  double? totalRent;
  double? primeMoverRent;
  double? bowzerRent;
  double? lastRent;
  double? lastCarRent;

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
    loadWeightController.dispose();
    unloadWeightController.dispose();
    rentController.dispose();
    carRentController.dispose();
    super.dispose();
  }

  void calculateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTransporter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Transporter'), backgroundColor: Colors.red));
      return;
    }

    final vehicleNo = vehicleNoController.text;
    final loadWeight = double.tryParse(loadWeightController.text) ?? 0;
    final unloadWeight = double.tryParse(unloadWeightController.text) ?? 0;
    final rent = double.tryParse(rentController.text) ?? 0;
    final carRent = double.tryParse(carRentController.text) ?? 0;

    final calculatedTotalRent = unloadWeight * rent;
    final calculatedPrimeMoverRent = unloadWeight * carRent;
    final calculatedBowzerRent = calculatedTotalRent - carRent; 

    final bill = BowserBillModel(
      transporterId: _selectedTransporter?.id,
      vehicleNo: vehicleNo,
      loadWeight: loadWeight,
      unloadWeight: unloadWeight,
      rent: rent,
      carRent: carRent,
      totalRent: calculatedTotalRent,
      primeMoverRent: calculatedPrimeMoverRent,
      bowzerRent: calculatedBowzerRent,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper().insertBowserBill(bill);

    setState(() {
      totalRent = calculatedTotalRent;
      primeMoverRent = calculatedPrimeMoverRent;
      bowzerRent = calculatedBowzerRent;
      lastRent = rent;
      lastCarRent = carRent;
    });

    _formKey.currentState!.reset();
    vehicleNoController.clear();
    loadWeightController.clear();
    unloadWeightController.clear();
    rentController.clear();
    carRentController.clear();
    setState(() => _selectedTransporter = null);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bowser Bill Saved Successfully", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      // CHANGED: Navigator.push instead of pushReplacement
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBowserBillsScreen()));
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
        // REMOVED back button
        title: Text('Own Bowser Bill', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () {
              // CHANGED: Navigator.push instead of pushReplacement
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedBowserBillsScreen()));
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: Text('Saved Bills', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          final detailsCard = Expanded(
            child: sectionCard('Vehicle & Transporter', [
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
              TextFormField(
                controller: loadWeightController,
                decoration: inputDecoration('Load Weight'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: unloadWeightController,
                decoration: inputDecoration('Unload Weight'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
            ]),
          );

          final rentCard = Expanded(
            child: sectionCard('Rent Details', [
              TextFormField(
                controller: rentController,
                decoration: inputDecoration('Rent'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: carRentController,
                decoration: inputDecoration('Car Rent'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
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
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [detailsCard, const SizedBox(width: 20), rentCard])
                      : Column(children: [detailsCard, rentCard]),
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
                  
                  if (totalRent != null)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Container(
                        key: ValueKey(totalRent),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 2),
                          boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            Text('Calculation Summary', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildOutputBox(context, title: 'Total Rent', subTitle: 'Rent: Rs. $lastRent', amount: totalRent!, color: Colors.blue)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildOutputBox(context, title: 'Prime Mover Rent', subTitle: 'Car Rent: Rs. $lastCarRent', amount: primeMoverRent!, color: Colors.orange)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildOutputBox(context, title: 'Bowzer Rent', subTitle: 'Rent - Car Rent: Rs. ${(lastRent! - lastCarRent!).toStringAsFixed(2)}', amount: bowzerRent!, color: Colors.green)),
                              ],
                            ),
                          ],
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

  Widget _buildOutputBox(BuildContext context, {required String title, required String subTitle, required double amount, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(subTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 12),
          Text('Rs. ${amount.toStringAsFixed(2)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
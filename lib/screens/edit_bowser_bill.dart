import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transporter_model.dart';
import '../models/bowser_bill_model.dart';

class EditBowserBillScreen extends StatefulWidget {
  final BowserBillModel bill;
  const EditBowserBillScreen({super.key, required this.bill});

  @override
  State<EditBowserBillScreen> createState() => _EditBowserBillScreenState();
}

class _EditBowserBillScreenState extends State<EditBowserBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController vehicleNoController;
  late TextEditingController loadWeightController;
  late TextEditingController unloadWeightController;
  late TextEditingController rentController;
  late TextEditingController carRentController;

  List<TransporterModel> _transporters = [];
  TransporterModel? _selectedTransporter;

  @override
  void initState() {
    super.initState();
    vehicleNoController = TextEditingController(text: widget.bill.vehicleNo);
    loadWeightController = TextEditingController(text: widget.bill.loadWeight.toString());
    unloadWeightController = TextEditingController(text: widget.bill.unloadWeight.toString());
    rentController = TextEditingController(text: widget.bill.rent.toString());
    carRentController = TextEditingController(text: widget.bill.carRent.toString());
    _loadTransporters();
  }

  void _loadTransporters() async {
    final transporters = await DatabaseHelper().getTransporters();
    if (mounted) {
      setState(() {
        _transporters = transporters;
        // Find the currently selected transporter
        try {
          _selectedTransporter = _transporters.firstWhere((t) => t.id == widget.bill.transporterId);
        } catch (e) {
          _selectedTransporter = null;
        }
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

  void _updateBill() async {
    if (!_formKey.currentState!.validate()) return;

    final unloadWeight = double.tryParse(unloadWeightController.text) ?? 0;
    final rent = double.tryParse(rentController.text) ?? 0;
    final carRent = double.tryParse(carRentController.text) ?? 0;

    final totalRent = unloadWeight * rent;
    final primeMoverRent = unloadWeight * carRent;
    final bowzerRent = totalRent - carRent;

    final updatedBill = BowserBillModel(
      id: widget.bill.id,
      transporterId: _selectedTransporter?.id,
      vehicleNo: vehicleNoController.text,
      loadWeight: double.tryParse(loadWeightController.text) ?? 0,
      unloadWeight: unloadWeight,
      rent: rent,
      carRent: carRent,
      totalRent: totalRent,
      primeMoverRent: primeMoverRent,
      bowzerRent: bowzerRent,
      createdAt: widget.bill.createdAt,
    );

    await DatabaseHelper().updateBowserBill(updatedBill);

    if (mounted) {
      Navigator.pop(context, true); // Return true to refresh the ledger
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bowser Bill'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<TransporterModel>(
                decoration: const InputDecoration(labelText: 'Transporter', border: OutlineInputBorder()),
                items: _transporters.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (val) => setState(() => _selectedTransporter = val),
                validator: (val) => val == null ? 'Required' : null,
                initialValue: _selectedTransporter,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: vehicleNoController,
                decoration: const InputDecoration(labelText: 'Vehicle No', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: loadWeightController,
                      decoration: const InputDecoration(labelText: 'Load Weight', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: unloadWeightController,
                      decoration: const InputDecoration(labelText: 'Unload Weight', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: rentController,
                      decoration: const InputDecoration(labelText: 'Rent', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: carRentController,
                      decoration: const InputDecoration(labelText: 'Car Rent', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: _updateBill,
                icon: const Icon(Icons.save),
                label: const Text('Update Bill'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
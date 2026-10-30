import 'package:flutter/material.dart';
import '../models/bills_model.dart';
import '../db/database_helper.dart';

class EditBillScreen extends StatefulWidget {
  final BillModel bill;

  const EditBillScreen({super.key, required this.bill});

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _vehicleController;
  late TextEditingController _rateController;
  late TextEditingController _loadingDateController;
  late TextEditingController _unloadingDateController;
  late TextEditingController _loadingWeightController;
  late TextEditingController _unloadingWeightController;
  late TextEditingController _loadingStationController;
  late TextEditingController _unloadingStationController;
  late TextEditingController _gainLossController;
  late TextEditingController _gainLossRateController;
  late TextEditingController _toPayController;

  @override
  void initState() {
    super.initState();
    _vehicleController = TextEditingController(text: widget.bill.vehicleNo);
    _rateController = TextEditingController(
      text: widget.bill.ratePerMt.toString(),
    );
    _loadingDateController = TextEditingController(
      text: widget.bill.loadingDate,
    );
    _unloadingDateController = TextEditingController(
      text: widget.bill.unloadingDate,
    );
    _loadingWeightController = TextEditingController(
      text: widget.bill.loadingWeight.toString(),
    );
    _unloadingWeightController = TextEditingController(
      text: widget.bill.unloadingWeight.toString(),
    );
    _loadingStationController = TextEditingController(
      text: widget.bill.loadingStation,
    );
    _unloadingStationController = TextEditingController(
      text: widget.bill.unloadingStation,
    );
    _gainLossController = TextEditingController(
      text: widget.bill.gainLoss.toString(),
    );
    _gainLossRateController = TextEditingController(
      text: widget.bill.gainLossRate.toString(),
    );
    _toPayController = TextEditingController();

    // Initial calculation
    calculateTotal();
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _rateController.dispose();
    _loadingDateController.dispose();
    _unloadingDateController.dispose();
    _loadingWeightController.dispose();
    _unloadingWeightController.dispose();
    _loadingStationController.dispose();
    _unloadingStationController.dispose();
    _gainLossController.dispose();
    _gainLossRateController.dispose();
    _toPayController.dispose();
    super.dispose();
  }

  void calculateTotal() {
    final loadingWeight = double.tryParse(_loadingWeightController.text) ?? 0;
    final unloadingWeight =
        double.tryParse(_unloadingWeightController.text) ?? 0;
    final ratePerMt = double.tryParse(_rateController.text) ?? 0;
    final gainLoss = double.tryParse(_gainLossController.text) ?? 0;
    final gainLossRate = double.tryParse(_gainLossRateController.text) ?? 0;

    double tripAmount =
        (gainLoss != 0 ? loadingWeight : unloadingWeight) * ratePerMt;
    double toPay = tripAmount;

    if (gainLoss > 0) {
      toPay += gainLoss * gainLossRate;
    } else if (gainLoss < 0) {
      toPay -= (-gainLoss) * gainLossRate;
    }

    _toPayController.text = toPay.toStringAsFixed(2);
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedBill = widget.bill.copyWith(
        vehicleNo: _vehicleController.text,
        ratePerMt: double.parse(_rateController.text),
        loadingDate: _loadingDateController.text,
        unloadingDate: _unloadingDateController.text,
        loadingWeight: double.parse(_loadingWeightController.text),
        unloadingWeight: double.parse(_unloadingWeightController.text),
        loadingStation: _loadingStationController.text,
        unloadingStation: _unloadingStationController.text,
        gainLoss: double.parse(_gainLossController.text),
        gainLossRate: double.parse(_gainLossRateController.text),
        toPay: double.parse(_toPayController.text),
      );

      await DatabaseHelper().updateBill(updatedBill);
      Navigator.pop(context, true);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool readOnly = false,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType:
            isNumber
                ? TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
        onChanged: (_) => onChanged?.call(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bill')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_vehicleController, 'Vehicle No'),
              _buildTextField(
                _rateController,
                'Rate Per MT',
                isNumber: true,
                onChanged: calculateTotal,
              ),
              _buildTextField(_loadingDateController, 'Loading Date'),
              _buildTextField(_unloadingDateController, 'Unloading Date'),
              _buildTextField(
                _loadingWeightController,
                'Loading Weight',
                isNumber: true,
                onChanged: calculateTotal,
              ),
              _buildTextField(
                _unloadingWeightController,
                'Unloading Weight',
                isNumber: true,
                onChanged: calculateTotal,
              ),
              _buildTextField(_loadingStationController, 'Loading Station'),
              _buildTextField(_unloadingStationController, 'Unloading Station'),
              _buildTextField(
                _gainLossController,
                'Gain/Loss',
                isNumber: true,
                onChanged: calculateTotal,
              ),
              _buildTextField(
                _gainLossRateController,
                'Gain/Loss Rate',
                isNumber: true,
                onChanged: calculateTotal,
              ),
              _buildTextField(
                _toPayController,
                'To Pay',
                isNumber: true,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

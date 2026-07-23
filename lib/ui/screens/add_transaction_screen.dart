import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/core/utils/transaction_parser.dart';
import 'package:catatkas/core/models/transaction_item.dart';
import 'package:catatkas/core/models/product_item.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/ui/widgets/custom_text_field.dart';
import 'package:catatkas/ui/widgets/primary_button.dart';
import 'package:catatkas/core/utils/currency_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionItem? existingItem;

  const AddTransactionScreen({super.key, this.existingItem});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _quickInputController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isJual = true;
  bool _isQuickInputMode = true;
  bool _showAdvancedFields = false;
  List<ProductItem> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();

    if (widget.existingItem != null) {
      _isJual = widget.existingItem!.isJual;
      _isQuickInputMode = false;
      _nameController.text = widget.existingItem!.name;
      _qtyController.text = widget.existingItem!.qty.toString();
      _unitController.text = widget.existingItem!.unit;
      _priceController.text = widget.existingItem!.price.toInt().toString();

      if (widget.existingItem!.qty != 1.0 || (widget.existingItem!.unit != 'pcs' && widget.existingItem!.unit != '')) {
        _showAdvancedFields = true;
      }
    } else {
      _qtyController.text = '1';
      _unitController.text = 'pcs';
    }

    _quickInputController.addListener(_onQuickInputChanged);
  }

  void _onQuickInputChanged() {
    if (!_isQuickInputMode) return;
    final detected = TransactionParser.detectIsJual(_quickInputController.text);
    if (detected != null && detected != _isJual) {
      setState(() {
        _isJual = detected;
      });
    }
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _availableProducts = products;
    });
  }

  @override
  void dispose() {
    _quickInputController.removeListener(_onQuickInputChanged);
    _quickInputController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final isDirty = _quickInputController.text.isNotEmpty || _nameController.text.isNotEmpty;
    if (!isDirty) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Batal Menyimpan?', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text('Data yang Anda ketik akan hilang.', style: TextStyle(fontSize: 15.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('TIDAK', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('YA, KELUAR', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingItem != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(isEditMode ? 'Edit Transaksi' : 'Catat Transaksi'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            // Tab Switcher Mode (Ketik Cepat vs Isi Manual)
            if (!isEditMode)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isQuickInputMode = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: _isQuickInputMode ? AppTheme.maroon : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Ketik Cepat',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: _isQuickInputMode ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isQuickInputMode = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: !_isQuickInputMode ? AppTheme.maroon : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Isi Manual',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: !_isQuickInputMode ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector Jenis Transaksi (Pemasukan vs Pengeluaran)
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isJual = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: _isJual ? AppTheme.green : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14.r),
                                  boxShadow: _isJual ? [
                                    BoxShadow(color: AppTheme.green.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))
                                  ] : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_upward_rounded, color: _isJual ? Colors.white : AppTheme.textMuted, size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text('PEMASUKAN', style: TextStyle(
                                      fontSize: 14.sp, 
                                      fontWeight: FontWeight.bold, 
                                      color: _isJual ? Colors.white : AppTheme.textMuted
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isJual = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: !_isJual ? AppTheme.red : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14.r),
                                  boxShadow: !_isJual ? [
                                    BoxShadow(color: AppTheme.red.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))
                                  ] : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_downward_rounded, color: !_isJual ? Colors.white : AppTheme.textMuted, size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Text('PENGELUARAN', style: TextStyle(
                                      fontSize: 14.sp, 
                                      fontWeight: FontWeight.bold, 
                                      color: !_isJual ? Colors.white : AppTheme.textMuted
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // TAMPILAN BERDASARKAN MODE (Ketik Cepat vs Isi Manual)
                    if (_isQuickInputMode) _buildQuickInputMode() else _buildManualMode(),

                    SizedBox(height: 28.h),

                    // Tombol Simpan (Ringkas & Teks Putih Konsisten)
                    PrimaryButton(
                      label: isEditMode ? 'UPDATE TRANSAKSI' : 'SIMPAN TRANSAKSI',
                      icon: Icons.check_circle_rounded,
                      onPressed: _handleSimpan,
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInputMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppTheme.maroon.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppTheme.maroon.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppTheme.maroon, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Ketik bebas, otomatis terdeteksi:\n• "pembelian 3 gram telur 200rb"\n• "penjualan bawang goreng 100 ons 250rb"',
                  style: TextStyle(fontSize: 12.sp, color: AppTheme.textDark, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _quickInputController,
          hintText: 'Ketik pesan transaksi di sini...',
          maxLines: 3,
        ),

        // Live Preview Deteksi Transaksi
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _quickInputController,
          builder: (context, value, child) {
            if (value.text.trim().isEmpty) return const SizedBox.shrink();
            try {
              final item = TransactionParser.parse(value.text, defaultIsJual: _isJual);
              final isExpense = !item.isJual;
              final statusBg = isExpense ? AppTheme.redSoft : AppTheme.greenSoft;
              final statusColor = isExpense ? AppTheme.red : AppTheme.green;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(top: 14.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: statusColor,
                      size: 24.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tercatat: ${isExpense ? "PENGELUARAN" : "PEMASUKAN"}',
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13.sp),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${item.name} (${item.qty} ${item.unit}) • ${CurrencyFormatter.format(item.price)}',
                            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } catch (_) {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildManualMode() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Autocomplete<ProductItem>(
            initialValue: TextEditingValue(text: _nameController.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<ProductItem>.empty();
              }
              return _availableProducts.where((ProductItem option) {
                return option.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            displayStringForOption: (ProductItem option) => option.name,
            onSelected: (ProductItem selection) {
              _nameController.text = selection.name;
              _priceController.text = selection.defaultPrice.toInt().toString();
              _unitController.text = selection.defaultUnit;
              _qtyController.text = '1';
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                onChanged: (val) {
                  _nameController.text = val;
                },
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: AppTheme.maroon, width: 2),
                  ),
                  labelText: 'Nama Barang',
                  labelStyle: TextStyle(fontSize: 14.sp, color: AppTheme.textMuted),
                  prefixIcon: Icon(Icons.shopping_bag_outlined, size: 20.sp),
                ),
              );
            },
          ),
          SizedBox(height: 14.h),

          CustomTextField(
            controller: _priceController,
            labelText: 'Total Harga (Rp)',
            keyboardType: TextInputType.number,
          ),

          if (!_showAdvancedFields) ...[
            SizedBox(height: 10.h),
            TextButton.icon(
              onPressed: () {
                setState(() => _showAdvancedFields = true);
              },
              icon: Icon(Icons.add_circle_outline, color: AppTheme.maroon, size: 18.sp),
              label: Text('Atur Jumlah & Satuan', style: TextStyle(color: AppTheme.maroon, fontSize: 14.sp, fontWeight: FontWeight.bold)),
            ),
          ],

          if (_showAdvancedFields) ...[
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _qtyController,
                    labelText: 'Jumlah',
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller: _unitController,
                    labelText: 'Satuan (kg/pcs)',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleSimpan() async {
    try {
      TransactionItem item;

      if (_isQuickInputMode) {
        if (_quickInputController.text.trim().isEmpty) {
          throw const FormatException("Pesan tidak boleh kosong.");
        }
        item = TransactionParser.parse(
          _quickInputController.text,
          defaultIsJual: _isJual,
        );
      } else {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          throw const FormatException("Nama barang tidak boleh kosong.");
        }

        final qtyStr = _showAdvancedFields ? _qtyController.text : '1';
        final unitStr = _showAdvancedFields ? _unitController.text : 'pcs';

        final qty = double.tryParse(qtyStr.replaceAll(',', '.')) ?? 1.0;
        final unit = unitStr.trim().isEmpty ? "pcs" : unitStr.trim();

        String priceStr = _priceController.text;
        priceStr = priceStr.replaceAll('.', '');
        priceStr = priceStr.replaceAll(',', '.');
        final price = double.tryParse(priceStr) ?? 0.0;

        if (price <= 0) {
          throw const FormatException("Harga tidak boleh nol.");
        }

        item = TransactionItem(
          id: widget.existingItem?.id,
          isJual: _isJual,
          name: name,
          qty: qty,
          unit: unit,
          price: price,
          timestamp: widget.existingItem?.timestamp ?? DateTime.now(),
        );
      }

      if (widget.existingItem != null) {
        await DatabaseHelper.instance.updateTransaction(item);
      } else {
        await DatabaseHelper.instance.insertTransaction(item);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          content: Text('${item.name} berhasil disimpan!',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      String errorMessage = "Terjadi kesalahan.";
      if (e is FormatException) {
        errorMessage = e.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          content: Text(errorMessage, style: TextStyle(fontSize: 14.sp)),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }
}

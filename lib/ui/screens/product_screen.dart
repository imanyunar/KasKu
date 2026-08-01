import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/core/models/product_item.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/ui/widgets/custom_text_field.dart';
import 'package:catatkas/core/utils/currency_formatter.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<ProductItem> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  void _showAddDialog({ProductItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final priceController = TextEditingController(
        text: existingItem?.defaultPrice.toInt().toString() ?? '');
    final unitController = TextEditingController(text: existingItem?.defaultUnit ?? 'pcs');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            existingItem == null ? 'Tambah Produk Langganan' : 'Edit Produk',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  labelText: 'Nama Barang (Misal: Beras)',
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: priceController,
                  labelText: 'Harga Standar (Rp)',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: unitController,
                  labelText: 'Satuan (kg/pcs)',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('BATAL', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.maroon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                
                String priceStr = priceController.text.replaceAll('.', '');
                priceStr = priceStr.replaceAll(',', '.');
                final price = double.tryParse(priceStr) ?? 0;
                
                final unit = unitController.text.trim();

                if (name.isNotEmpty && price > 0) {
                  final newItem = ProductItem(
                    id: existingItem?.id,
                    name: name,
                    defaultPrice: price,
                    defaultUnit: unit,
                  );
                  
                  if (existingItem != null) {
                    await DatabaseHelper.instance.updateProduct(newItem);
                  } else {
                    await DatabaseHelper.instance.insertProduct(newItem);
                  }
                  
                  if (context.mounted) Navigator.pop(context);
                  _loadProducts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nama produk dan harga tidak boleh kosong/nol!', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                      backgroundColor: AppTheme.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                existingItem == null ? 'SIMPAN' : 'UPDATE',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(ProductItem item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Hapus Produk?', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text(
          'Hapus "${item.name}" dari daftar langganan?',
          style: TextStyle(fontSize: 15.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ya, Hapus', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await DatabaseHelper.instance.deleteProduct(item.id!);
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 54.sp, color: Colors.grey.shade300),
                      SizedBox(height: 12.h),
                      Text(
                        'Belum ada produk langganan.',
                        style: TextStyle(fontSize: 14.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Klik tombol di bawah untuk menambah.',
                        style: TextStyle(fontSize: 13.sp, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.r),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showAddDialog(existingItem: item),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 38.r,
                                  height: 38.r,
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(Icons.inventory_2_rounded, color: AppTheme.gold, size: 18.sp),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${CurrencyFormatter.format(item.defaultPrice)} / ${item.defaultUnit}',
                                        style: TextStyle(fontSize: 12.sp, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade300, size: 18.sp),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDelete(item),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.maroon.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
            onPressed: () => _showAddDialog(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, size: 22.sp, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  'TAMBAH PRODUK',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

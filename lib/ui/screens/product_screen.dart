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
          title: Text(existingItem == null ? 'Tambah Produk Langganan' : 'Edit Produk', 
                      style: TextStyle(fontSize: 22.sp)),
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
              child: Text('Batal', style: TextStyle(fontSize: 18.sp)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.maroon, foregroundColor: AppTheme.gold),
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
                }
              },
              child: Text(existingItem == null ? 'SIMPAN' : 'UPDATE', style: TextStyle(fontSize: 18.sp)),
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
        title: Text('Hapus Produk?', style: TextStyle(fontSize: 22.sp)),
        content: Text('Hapus "${item.name}" dari daftar langganan?', style: TextStyle(fontSize: 18.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(fontSize: 18.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ya, Hapus', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await DatabaseHelper.instance.deleteProduct(item.id!);
      _loadProducts();
    }
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Produk'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[400]),
                      SizedBox(height: 16.h),
                      Text(
                        'Belum ada produk langganan.',
                        style: TextStyle(fontSize: 22.sp, color: Colors.black54),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Klik tombol di bawah untuk menambah.',
                        style: TextStyle(fontSize: 16.sp, color: Colors.black38),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.0.r),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _showAddDialog(existingItem: item),
                        borderRadius: BorderRadius.circular(8.r),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.0.r),
                          title: Text(item.name, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                          subtitle: Text('${_formatCurrency(item.defaultPrice)} / ${item.defaultUnit}', style: TextStyle(fontSize: 18.sp)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.grey, size: 32),
                            onPressed: () => _confirmDelete(item),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.maroon,
        foregroundColor: AppTheme.gold,
        onPressed: () => _showAddDialog(),
        icon: Icon(Icons.add, size: 28),
        label: Text('TAMBAH PRODUK', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:catatkas/core/theme.dart';
import 'package:catatkas/core/models/transaction_item.dart';
import 'package:catatkas/core/database/database_helper.dart';
import 'package:catatkas/core/utils/currency_formatter.dart';
import 'package:catatkas/core/utils/pdf_helper.dart';
import 'package:catatkas/ui/screens/add_transaction_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'BULAN INI';
  bool _isLoading = true;

  List<TransactionItem> _transactions = [];
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  double _labaBersih = 0;

  late DateTime _currentStart;
  late DateTime _currentEnd;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
    _loadData();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    if (_selectedFilter == 'HARI INI') {
      _currentStart = DateTime(now.year, now.month, now.day);
      _currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilter == 'MINGGU INI') {
      _currentStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      _currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilter == 'BULAN INI') {
      _currentStart = DateTime(now.year, now.month, 1);
      _currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilter == 'SEMUA') {
      _currentStart = DateTime(2000, 1, 1);
      _currentEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _updateDateRange();

    final db = await DatabaseHelper.instance.database;
    final startStr = _currentStart.toIso8601String();
    final endStr = _currentEnd.toIso8601String();

    List<Map<String, dynamic>> result;
    if (_selectedFilter == 'SEMUA') {
      result = await db.query('transactions', orderBy: 'timestamp DESC');
    } else {
      result = await db.query(
        'transactions',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'timestamp DESC',
      );
    }

    final list = result.map((json) => TransactionItem.fromMap(json)).toList();

    double pemasukan = 0;
    double pengeluaran = 0;
    for (var item in list) {
      if (item.isJual) {
        pemasukan += item.price;
      } else {
        pengeluaran += item.price;
      }
    }

    setState(() {
      _transactions = list;
      _totalPemasukan = pemasukan;
      _totalPengeluaran = pengeluaran;
      _labaBersih = pemasukan - pengeluaran;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }

  bool _isCustomMode() {
    return _selectedFilter != 'HARI INI' &&
        _selectedFilter != 'MINGGU INI' &&
        _selectedFilter != 'BULAN INI' &&
        _selectedFilter != 'SEMUA';
  }

  Future<void> _exportPdf() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ada data transaksi pada periode ini.', style: TextStyle(fontSize: 16.sp)),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Membuat PDF... Tunggu sebentar.', style: TextStyle(fontSize: 16.sp)),
          duration: const Duration(seconds: 2),
        ),
      );

      final result = await PdfHelper.generateReportPdf(_selectedFilter, _currentStart, _currentEnd);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Buka PDF secara langsung menggunakan viewer bawaan HP / BlueStacks
      await OpenFilex.open(result.internalPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          backgroundColor: AppTheme.green,
          duration: const Duration(seconds: 4),
          content: Text('PDF Berhasil Dibuat & Tersimpan di Download',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          action: SnackBarAction(
            label: 'BAGIKAN',
            textColor: Colors.white,
            onPressed: () {
              try {
                Share.shareXFiles([XFile(result.internalPath)], text: 'Laporan Keuangan CatatKas - $_selectedFilter');
              } catch (_) {}
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.split('Exception:').last.trim();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: $errorMsg', style: TextStyle(fontSize: 16.sp)),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      );
    }
  }

  Future<void> _confirmDelete(TransactionItem item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Hapus Data?', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${item.name}"?',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ya, Hapus', style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && item.id != null) {
      await DatabaseHelper.instance.deleteTransaction(item.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          content: Text('Data berhasil dihapus', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.green,
        ),
      );
      _loadData();
    }
  }

  void _editTransaction(TransactionItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTransactionScreen(existingItem: item)),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Riwayat & Laporan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: AppTheme.maroon, size: 26.sp),
            tooltip: 'Cetak / Bagikan PDF',
            onPressed: _exportPdf,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Filter Chips Periode (Horizontal Scrollable)
              _buildFilterSection(),
              SizedBox(height: 20.h),

              // 2. Kartu Ringkasan Laporan (Responsive & Compact PDF Icon Button)
              _buildSummaryCard(),
              SizedBox(height: 24.h),

              // 3. Header Daftar Transaksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Transaksi',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: Text(
                      '${_transactions.length} Data',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // 4. List Transaksi
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_transactions.isEmpty)
                _buildEmptyState()
              else
                ..._buildGroupedList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ['HARI INI', 'MINGGU INI', 'BULAN INI', 'SEMUA'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...filters.map((filter) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildFilterChip(filter),
              )),
          _buildFilterChip(_isCustomMode() ? _selectedFilter : 'PILIH TANGGAL', isCustomButton: true),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, {bool isCustomButton = false}) {
    final isSelected = _selectedFilter == text || (isCustomButton && _isCustomMode());

    return GestureDetector(
      onTap: () async {
        if (isCustomButton) {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: DateTimeRange(start: _currentStart, end: _currentEnd),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.maroon,
                    onPrimary: Colors.white,
                    onSurface: AppTheme.textDark,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _currentStart = picked.start;
              _currentEnd = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);

              String startStr =
                  "${picked.start.day.toString().padLeft(2, '0')}/${picked.start.month.toString().padLeft(2, '0')}";
              String endStr =
                  "${picked.end.day.toString().padLeft(2, '0')}/${picked.end.month.toString().padLeft(2, '0')}";

              if (picked.start.isAtSameMomentAs(picked.end)) {
                _selectedFilter = startStr;
              } else {
                _selectedFilter = "$startStr - $endStr";
              }
            });
            _loadData();
          }
        } else {
          setState(() {
            _selectedFilter = text;
          });
          _loadData();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.maroon : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? AppTheme.maroon : Colors.grey.withOpacity(0.2)),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.maroon.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCustomButton) ...[
              Icon(Icons.calendar_month_rounded, size: 16.sp, color: isSelected ? Colors.white : AppTheme.textMuted),
              SizedBox(width: 6.w),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Keuangan',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              InkWell(
                onTap: _exportPdf,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppTheme.maroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: AppTheme.maroon, size: 18.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'PDF',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppTheme.maroon),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1),
          SizedBox(height: 16.h),

          // Pemasukan & Pengeluaran (Auto-Scaling fitted text)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, color: AppTheme.green, size: 16.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'Pemasukan',
                          style: TextStyle(fontSize: 13.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      height: 26.h,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatCurrency(_totalPemasukan),
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppTheme.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 42.h, color: Colors.grey.withOpacity(0.2)),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded, color: AppTheme.red, size: 16.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'Pengeluaran',
                          style: TextStyle(fontSize: 13.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      height: 26.h,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatCurrency(_totalPengeluaran),
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppTheme.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          const Divider(height: 1),
          SizedBox(height: 16.h),

          // Laba / Rugi Bersih
          Row(
            children: [
              Text(
                'Untung / Rugi Bersih',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SizedBox(
                  height: 28.h,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _labaBersih >= 0
                          ? '+ ${_formatCurrency(_labaBersih)}'
                          : '- ${_formatCurrency(_labaBersih.abs())}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: _labaBersih >= 0 ? AppTheme.green : AppTheme.red,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
              ),
              child: Icon(Icons.folder_open_rounded, size: 64.sp, color: Colors.grey.shade300),
            ),
            SizedBox(height: 16.h),
            Text(
              'Belum ada transaksi pada periode ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.maroon,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
              icon: Icon(Icons.add_circle_rounded, size: 20.sp),
              label: Text('CATAT TRANSAKSI', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList() {
    List<Widget> items = [];
    String lastDate = '';

    for (int i = 0; i < _transactions.length; i++) {
      var item = _transactions[i];
      final date = item.timestamp;
      final dateStr =
          '${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year}';

      if (dateStr != lastDate) {
        items.add(
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 8.h, left: 4.w),
            child: Text(
              dateStr,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            ),
          ),
        );
        lastDate = dateStr;
      }

      final timeStr =
          '${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}';

      final qtyDisplay = item.qty % 1 == 0 ? item.qty.toInt().toString() : item.qty.toString();

      items.add(
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editTransaction(item),
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(16.0.r),
                child: Row(
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: item.isJual ? AppTheme.green.withOpacity(0.1) : AppTheme.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          item.isJual ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: item.isJual ? AppTheme.green : AppTheme.red,
                          size: 22.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '$qtyDisplay ${item.unit} • $timeStr',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 22.h,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatCurrency(item.price),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: item.isJual ? AppTheme.green : AppTheme.red,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20.sp),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmDelete(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return items;
  }
}

import 'package:flutter/material.dart';

import 'package:motora/features/dealership/data/dealership_application_service.dart';
import 'package:motora/features/dealership/presentation/pages/dealership_dashboard_page.dart';

class DealershipApplicationPage extends StatefulWidget {
  const DealershipApplicationPage({super.key});

  @override
  State<DealershipApplicationPage> createState() =>
      _DealershipApplicationPageState();
}

class _DealershipApplicationPageState
    extends State<DealershipApplicationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _service = DealershipApplicationService();

  bool _loading = false;
  bool _checking = true;

  Map<String, dynamic>? _existingApplication;

  static const Color background = Color(0xFF101114);
  static const Color surface = Color(0xFF1E2024);
  static const Color accent = Color(0xFFF8ED00);

  @override
  void initState() {
    super.initState();
    _checkApplication();
  }

  Future<void> _checkApplication() async {
    if (mounted) {
      setState(() => _checking = true);
    }

    try {
      final application = await _service.getMyApplication();

      if (!mounted) return;

      setState(() {
        _existingApplication = application;
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _checking = false);
      _showMessage('تعذر تحميل حالة الطلب: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _service.submitApplication(
        dealershipName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('تم إرسال طلب إنشاء المعرض بنجاح');

      await _checkApplication();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DealershipDashboardPage(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: surface,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'هذا الحقل مطلوب';
            }

            if (label == 'رقم الهاتف' &&
                value != null &&
                value.trim().length < 7) {
              return 'أدخل رقم هاتف صحيحاً';
            }

            return null;
          },
          decoration: InputDecoration(
            hintText: 'أدخل $label',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: accent),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: accent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingApplication() {
    final status =
        _existingApplication?['status']?.toString() ?? 'pending';

    final adminNotes =
        _existingApplication?['admin_notes']?.toString() ?? '';

    String title;
    String message;
    Color color;
    IconData icon;

    switch (status) {
      case 'approved':
        title = 'تمت الموافقة على طلبك';
        message = 'أصبح معرضك معتمداً في MOTORA. يمكنك الآن فتح لوحة التحكم وإدارة سياراتك.';
        color = Colors.greenAccent;
        icon = Icons.check_circle_outline_rounded;
        break;

      case 'rejected':
        title = 'تم رفض الطلب';
        message = adminNotes.isNotEmpty
            ? adminNotes
            : 'يمكنك التواصل مع إدارة المنصة لمعرفة التفاصيل.';
        color = Colors.redAccent;
        icon = Icons.cancel_outlined;
        break;

      default:
        title = 'طلبك قيد المراجعة';
        message =
            'ستتم مراجعة بيانات المعرض من قبل إدارة MOTORA. يمكنك تحديث الحالة لمعرفة آخر المستجدات.';
        color = accent;
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 55,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.7,
            ),
          ),

          // طلب معتمد: فتح لوحة تحكم المعرض
          if (status == 'approved') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openDashboard,
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text(
                  'فتح لوحة تحكم المعرض',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],

          // الطلب المرفوض
          if (status == 'rejected') ...[
            const SizedBox(height: 18),
            const Text(
              'يرجى مراجعة إدارة المنصة قبل تقديم طلب جديد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          ],

          // الطلب قيد المراجعة: تحديث الحالة
          if (status == 'pending') ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _checking ? null : _checkApplication,
                icon: _checking
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: accent,
                      ),
                label: const Text(
                  'تحديث حالة الطلب',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: accent.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إنشاء حساب معرض',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _checking
          ? const Center(
              child: CircularProgressIndicator(color: accent),
            )
          : _existingApplication != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildExistingApplication(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'انضم إلى معارض MOTORA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'أرسل بيانات معرضك، وبعد مراجعة الطلب والموافقة عليه ستتمكن من إضافة سياراتك وإدارتها.',
                          style: TextStyle(
                            color: Colors.white60,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildField(
                          label: 'اسم المعرض',
                          controller: _nameController,
                          icon: Icons.storefront_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          label: 'رقم الهاتف',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          label: 'عنوان المعرض',
                          controller: _addressController,
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          label: 'وصف المعرض',
                          controller: _descriptionController,
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          required: false,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor:
                                  accent.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 23,
                                    height: 23,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'إرسال طلب المعرض',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
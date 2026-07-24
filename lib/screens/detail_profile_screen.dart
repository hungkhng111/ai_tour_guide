import 'dart:io'; // 🟢 Thêm thư viện này để xử lý File ảnh
import 'package:ai_tour_guide/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // 🟢 Thêm thư viện Image Picker

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  bool _showBanner = false;
  bool _isSuccessBanner = false;
  String _bannerMessage = '';
  Key _bannerKey = UniqueKey(); 

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hometownController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  String _selectedCountryCode = '+84';
  final List<String> _genderOptions = ['Chưa cập nhật', 'Nam', 'Nữ', 'Khác'];
  final List<String> _countryCodes = ['+84', '+1', '+44', '+81', '+82', '+86'];


  // 🟢 BIẾN CHỨA LINK AVATAR VÀ TRẠNG THÁI UPLOAD
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = AuthService().currentUserId;
      if (userId == null) throw 'Chưa đăng nhập';

      final data = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          String fullPhone = data['phone'] ?? '';
          if (fullPhone.isNotEmpty) {
            bool foundCode = false;
            for (var code in _countryCodes) {
              if (fullPhone.startsWith(code)) {
                _selectedCountryCode = code;
                _phoneController.text = fullPhone.substring(code.length);
                foundCode = true;
                break;
              }
            }
            if (!foundCode) _phoneController.text = fullPhone;
          }
          _hometownController.text = data['hometown'] ?? '';
          _selectedGender = data['gender'];
          _avatarUrl = data['avatar_url']; // 🟢 Lấy link ảnh từ Database
          if (data['date_of_birth'] != null) {
            _selectedDate = DateTime.tryParse(data['date_of_birth']);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomBanner(false, 'Lỗi tải dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomBanner(bool isSuccess, String message) {
    setState(() {
      _isSuccessBanner = isSuccess;
      _bannerMessage = message;
      _showBanner = true;
      _bannerKey = UniqueKey();
    });
  }

  // 🟢 HÀM XỬ LÝ CHỌN VÀ UPLOAD ẢNH ĐẠI DIỆN
  Future<void> _changeAvatar() async {
    if (!_isEditing) return;

    final picker = ImagePicker();
    // Mở thư viện ảnh của điện thoại
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return; // Người dùng bấm Hủy không chọn nữa

    setState(() => _isUploadingAvatar = true);

    try {
      final userId = AuthService().currentUserId;
      if (userId == null) throw 'Chưa đăng nhập';

      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      
      // Đặt tên file là ID của user để ghi đè (tiết kiệm dung lượng lưu trữ)
      // Thêm timestamp để ép Flutter tải lại ảnh mới (phá cache)
      final fileName = '${userId}_avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 1. Upload ảnh lên bucket 'avatars'
      await _supabase.storage.from('avatars').upload(
        fileName, 
        file,
        fileOptions: const FileOptions(upsert: true), // Cho phép ghi đè file cũ
      );

      // 2. Lấy đường link public của ảnh vừa up
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // 3. Cập nhật đường link đó vào bảng profiles
      await _supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', userId);

      if (mounted) {
        setState(() {
          _avatarUrl = imageUrl;
          _isUploadingAvatar = false;
        });
        _showCustomBanner(true, 'Cập nhật ảnh đại diện thành công!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _showCustomBanner(false, 'Lỗi tải ảnh: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    List<String> errors = [];
    
    if (_nameController.text.trim().isEmpty) {
      errors.add('• Họ và Tên không được để trống.');
    }
    if (_phoneController.text.trim().length > 15) {
      errors.add('• Số điện thoại không được vượt quá 15 ký tự.');
    }
    
    if (errors.isNotEmpty) {
      _showCustomBanner(false, errors.join('\n'));
      return; 
    }

    setState(() => _isSaving = true);

    try {
      final userId = AuthService().currentUserId;
      if (userId == null) throw 'Chưa đăng nhập';
      
      String finalPhone = _phoneController.text.trim().isEmpty ? '' : '$_selectedCountryCode${_phoneController.text.trim()}';

      await _supabase.from('profiles').upsert({
        'id': userId,
        'full_name': _nameController.text.trim(),
        'phone': finalPhone,
        'hometown': _hometownController.text.trim(),
        'gender': _selectedGender,
        'date_of_birth': _selectedDate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        // 🟢 Cập nhật lại avatar_url phòng trường hợp up ảnh xong bị mất
        'avatar_url': _avatarUrl, 
      });

      if (!mounted) return;
      
      _showCustomBanner(true, 'Thông tin cá nhân của bạn đã được cập nhật!');
      setState(() => _isEditing = false);
      
    } catch (e) {
      if (!mounted) return;
      _showCustomBanner(false, 'Lỗi cập nhật: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.teal),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _loadProfile();
                    _showBanner = false; 
                  }
                });
              },
            )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 🟢 TẠO KHOẢNG TRỐNG (SPACING) Ở TRÊN ĐỂ NÉ BANNER
                        const SizedBox(height: 10),

                        // 🟢 KHỐI GIAO DIỆN AVATAR
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50, // To nhỏ tùy chỉnh
                                backgroundColor: Colors.teal.shade50,
                                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                                child: _avatarUrl == null 
                                    ? const Icon(Icons.person, size: 50, color: Colors.teal) 
                                    : null,
                              ),
                              
                              // 🟢 HIỆN NÚT MÁY ẢNH NẾU ĐANG CHỈNH SỬA
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _isUploadingAvatar ? null : _changeAvatar,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.teal,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: _isUploadingAvatar
                                          ? const SizedBox(
                                              width: 16, height: 16,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // 🟢 TẠO KHOẢNG TRỐNG TRƯỚC KHI VÀO FORM
                        const SizedBox(height: 30),

                        _buildTextField(
                          _nameController, 
                          'Họ và Tên', 
                          Icons.person,
                          editHint: 'Nhập họ và tên của bạn', //placeholder ten
                          ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _phoneController, 
                          'Số điện thoại', 
                          Icons.phone, 
                          keyboardType: TextInputType.phone,
                          editHint: 'Nhập số điện thoại',
                          customPrefix: _buildPhonePrefix(),
                          ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _hometownController, 
                          'Quê quán',
                          Icons.location_on,
                          editHint: 'Tỉnh/Thành phố, Quốc gia',
                          ),
                        const SizedBox(height: 16),
                        
                        IgnorePointer(
                          ignoring: !_isEditing,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            // Giấu luôn cái mũi tên chỉ xuống nếu đang ở chế độ xem
                            icon: _isEditing ? const Icon(Icons.arrow_drop_down, color: Colors.teal) : const SizedBox.shrink(),
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: _isEditing ? FontWeight.normal : FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration('Giới tính', Icons.wc),
                            items: _genderOptions.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            onChanged: _isEditing ? (val) => setState(() => _selectedGender = val) : null, 
                            disabledHint: Text(
                              _selectedGender ?? 'Chưa cập nhật', 
                              style: TextStyle(
                                color: _selectedGender == null ? Colors.grey.shade500 : Colors.black87,
                                fontWeight: _selectedGender == null ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                            // Thêm dòng hint này để khi bấm "Sửa" mà chưa có data, nó vẫn hiện chữ xám
                            hint: Text(
                              'Chưa cập nhật', 
                              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        IgnorePointer(
                          ignoring: !_isEditing,
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: _buildInputDecoration('Ngày sinh', Icons.calendar_today),
                              child: Text(
                                _selectedDate == null ? 'Chưa chọn ngày' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.grey.shade500 : Colors.black87,
                                  fontWeight: _isEditing ? FontWeight.normal : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (_isEditing)
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isSaving ? null : _updateProfile,
                              child: _isSaving
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Lưu thông tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              offset: _showBanner ? Offset.zero : const Offset(0, -1.5),
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastLinearToSlowEaseIn,
              child: SafeArea(
                child: _buildCustomBanner(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _isSuccessBanner ? Colors.green.shade400 : Colors.red.shade400,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: _isSuccessBanner ? Colors.green.shade50 : Colors.red.shade50,
              padding: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _isSuccessBanner ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: _isSuccessBanner ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isSuccessBanner ? 'LƯU THÀNH CÔNG!' : 'CÓ LỖI!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isSuccessBanner ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black38),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _showBanner = false),
                  )
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Text(
                _bannerMessage,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ),
            TweenAnimationBuilder<double>(
              key: _bannerKey,
              tween: Tween<double>(begin: 1.0, end: 0.0),
              duration: const Duration(seconds: 4), 
              onEnd: () {
                if (mounted && _showBanner) {
                  setState(() => _showBanner = false);
                }
              },
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isSuccessBanner ? Colors.green : Colors.red,
                  ),
                  minHeight: 4, 
                );
              },
            ),
          ],
        ),
      ),
    );
  }

Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, String? editHint, Widget? customPrefix}) {
    return IgnorePointer(
      ignoring: !_isEditing,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: !_isEditing,
        // Font chữ nhất quán cho nội dung thật
        style: TextStyle(
          color: Colors.black87,
          fontWeight: _isEditing ? FontWeight.normal : FontWeight.w500, 
        ),
        decoration: _buildInputDecoration(label, icon, editHint: editHint, customPrefix: customPrefix),
      ),
    );
  }

InputDecoration _buildInputDecoration(String label, IconData icon, {String? editHint, Widget? customPrefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _isEditing ? Colors.teal : Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      // ĐIỂM SÁNG GIÁ NHẤT: Ép tiêu đề luôn nổi lên viền trên cùng!
      floatingLabelBehavior: FloatingLabelBehavior.always, 
      
      // Nếu đang xem mà chưa có dữ liệu -> Hiện chữ "Chưa cập nhật"
      // Nếu đang sửa -> Hiện chữ Placeholder (Ví dụ: Nhập họ tên...)
      hintText: _isEditing ? editHint : 'Chưa cập nhật',
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      
      prefixIcon: customPrefix ?? Icon(icon, color: _isEditing ? Colors.teal : Colors.grey.shade400),
      fillColor: _isEditing ? Colors.white : Colors.transparent,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: _isEditing ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: _isEditing ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
    );
  }

  Widget _buildPhonePrefix() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone, color: _isEditing ? Colors.teal : Colors.grey.shade400),
          const SizedBox(width: 8),
          IgnorePointer(
            ignoring: !_isEditing,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                icon: _isEditing ? const Icon(Icons.arrow_drop_down, color: Colors.teal) : const SizedBox.shrink(),
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: _isEditing ? FontWeight.normal : FontWeight.w500,
                  fontSize: 16,
                ),
                items: _countryCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                onChanged: (val) {
                  if (val != null && mounted) setState(() => _selectedCountryCode = val);
                },
              ),
            ),
          ),
          // Dấu gạch dọc phân cách thẩm mỹ
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hometownController.dispose();
    super.dispose();
  }
}
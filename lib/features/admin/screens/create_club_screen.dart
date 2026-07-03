import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _focusAreaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconNameController = TextEditingController(text: 'groups');
  final _colorHexController = TextEditingController(text: '#FFC107');

  Uint8List? _logoBytes;
  Uint8List? _coverBytes;
  final _picker = ImagePicker();

  Future<void> _pickImage(bool isLogo) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isLogo) {
          _logoBytes = bytes;
        } else {
          _coverBytes = bytes;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(createClubNotifierProvider.notifier).createClub(
        name: _nameController.text,
        focusArea: _focusAreaController.text,
        description: _descriptionController.text,
        iconName: _iconNameController.text,
        colorHex: _colorHexController.text,
        logoFile: _logoBytes,
        coverFile: _coverBytes,
      );

      final state = ref.read(createClubNotifierProvider);
      if (!state.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club created successfully!')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createClubNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131F),
        title: const Text('Create New Club', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Club Information'),
              const SizedBox(height: 16),
              _buildTextField('Club Name', _nameController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Focus Area (e.g. AI, Hardware, Web)', _focusAreaController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Description', _descriptionController, maxLines: 4, required: true),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Appearance'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Material Icon Name', _iconNameController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Color Hex Code', _colorHexController)),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Media Assets'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePicker(
                      label: 'Club Logo',
                      bytes: _logoBytes,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImagePicker(
                      label: 'Cover Image',
                      bytes: _coverBytes,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: const Color(0xFF1D100A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Color(0xFF1D100A))
                    : const Text('Create Club', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.tertiary, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: required ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        filled: true,
        fillColor: const Color(0xFF13131F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.tertiary)),
      ),
    );
  }

  Widget _buildImagePicker({required String label, required Uint8List? bytes, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
          image: bytes != null ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover) : null,
        ),
        child: bytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate, color: AppColors.tertiary, size: 32),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: AppColors.tertiary, fontSize: 14)),
                ],
              )
            : null,
      ),
    );
  }
}

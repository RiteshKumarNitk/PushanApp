import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';

class AdminAddProductPage extends StatefulWidget {
  const AdminAddProductPage({super.key});

  @override
  State<AdminAddProductPage> createState() => _AdminAddProductPageState();
}

class _AdminAddProductPageState extends State<AdminAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minQtyCtrl = TextEditingController(text: "1");
  final _unitCtrl = TextEditingController(text: "pack");
  final _categoryCtrl = TextEditingController(text: "Premium Tea");
  
  XFile? _pickedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image Picker Error: $e")));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 1. Upload Image (Assuming 'product-images' bucket exists)
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final fileExt = _pickedImage!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await SupabaseConfig.client.storage
            .from('product-images')
            .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

        imageUrl = SupabaseConfig.client.storage
            .from('product-images')
            .getPublicUrl(fileName);
      }

      // 2. Insert Product
      await SupabaseConfig.client.from('products').insert({
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'category': _categoryCtrl.text,
        'price_per_unit': double.parse(_priceCtrl.text),
        'min_order_quantity': int.parse(_minQtyCtrl.text),
        'unit_type': _unitCtrl.text,
        'image_url': imageUrl,
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Added Successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                    image: _pickedImage != null 
                        ? DecorationImage(
                            image: FileImage(File(_pickedImage!.path)), 
                            fit: BoxFit.cover
                          )
                        : null,
                  ),
                  child: _pickedImage == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            Text("Tap to add image", style: TextStyle(color: Colors.grey))
                          ],
                        )
                      : null, // Image handled by decoration? Actually XFile.path on Windows works with Image.file. 
                              // DecorationImage takes an ImageProvider. 
                ),
              ),
              if (_pickedImage != null)
                 Center(child: TextButton(onPressed: _pickImage, child: const Text("Change Image"))),
              
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: "Price"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration: const InputDecoration(labelText: "Unit (e.g. pack)"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _minQtyCtrl,
                      decoration: const InputDecoration(labelText: "Min Order Qty"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                   const SizedBox(width: 16),
                   Expanded(
                    child: TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("CREATE PRODUCT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

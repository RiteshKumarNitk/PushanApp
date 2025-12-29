import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../core/app_theme.dart';
import '../../shared/models/product.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
  
  // Variants (We allow editing existing ones and adding new ones)
  // We need to track IDs for existing ones to update them
  late List<Map<String, dynamic>> _variants;

  XFile? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl = TextEditingController(text: widget.product.description);
    _categoryCtrl = TextEditingController(text: widget.product.category);
    
    _variants = widget.product.variants.map((v) {
      return {
        'id': v.id, // Keep ID to update existing
        'name': TextEditingController(text: v.variantName),
        'price': TextEditingController(text: v.price.toStringAsFixed(0)),
        'is_new': false,
        'is_deleted': false, 
      };
    }).toList();

    if (_variants.isEmpty) {
       _addVariant(); // Ensure at least one
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'id': null,
        'name': TextEditingController(),
        'price': TextEditingController(),
        'is_new': true,
        'is_deleted': false, 
      });
    });
  }

  void _removeVariant(int index) {
      setState(() {
        if (_variants[index]['is_new']) {
           _variants.removeAt(index);
        } else {
           // For existing ones, mark as deleted so we can delete from DB
           _variants[index]['is_deleted'] = true;
        }
      });
  }

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.product.imageUrl;

      // 1. Upload New Image (If selected)
      if (_pickedImage != null) {
        try {
          final bytes = await _pickedImage!.readAsBytes();
          final fileExt = _pickedImage!.name.split('.').last;
          final fileName = 'updated_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          
          await SupabaseConfig.client.storage
              .from('product-images')
              .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

          imageUrl = SupabaseConfig.client.storage
              .from('product-images')
              .getPublicUrl(fileName);
        } catch(e) { /* ignore upload errors */ }
      }

      // 2. Update Product Info
      await SupabaseConfig.client.from('products').update({
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'category': _categoryCtrl.text,
        'image_url': imageUrl,
      }).eq('id', widget.product.id);

      // 3. Handle Variants (Upsert/Delete)
      for (var v in _variants) {
        if (v['is_deleted'] == true) {
          if (v['id'] != null) {
            await SupabaseConfig.client.from('product_variants').delete().eq('id', v['id']);
          }
        } else {
          final data = {
            'product_id': widget.product.id,
            'variant_name': (v['name'] as TextEditingController).text,
            'price': double.tryParse((v['price'] as TextEditingController).text) ?? 0,
          };

          if (v['is_new'] == true) {
             await SupabaseConfig.client.from('product_variants').insert(data);
          } else {
             await SupabaseConfig.client.from('product_variants').update(data).eq('id', v['id']);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Updated Successfully!")));
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
  
  Future<void> _deleteProduct() async {
     final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
       title: const Text("Delete Product?"),
       content: const Text("This cannot be undone."),
       actions: [
         TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
         TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
       ],
     ));

     if (confirm != true) return;
     
     setState(() => _isLoading = true);
     try {
       await SupabaseConfig.client.from('products').delete().eq('id', widget.product.id);
       if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Deleted")));
       }
     } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
       setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
        actions: [
          IconButton(onPressed: _deleteProduct, icon: const Icon(Icons.delete, color: Colors.red))
        ],
      ),
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
                        ? DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover)
                        : (widget.product.imageUrl.isNotEmpty 
                             ? DecorationImage(image: NetworkImage(widget.product.imageUrl), fit: BoxFit.cover)
                             : null),
                  ),
                  child: (_pickedImage == null && widget.product.imageUrl.isEmpty)
                      ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
                      : null,
                ),
              ),
              Center(child: TextButton(onPressed: _pickImage, child: const Text("Change Image"))),
              
              const SizedBox(height: 24),
              // Basic Details
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 24),
              
              const Divider(),
              const Text("Variants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Dynamic Variants List
              ..._variants.asMap().entries.where((e) => e.value['is_deleted'] == false).map((entry) {
                final index = entry.key;
                final variant = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: variant['name'],
                          decoration: InputDecoration(
                            labelText: "Size / Name",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                          ),
                          validator: (v) => v!.isEmpty ? 'Req' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: variant['price'],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Price",
                            prefixText: "₹",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                          ),
                          validator: (v) => v!.isEmpty ? 'Req' : null,
                        ),
                      ),
                       IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeVariant(index),
                      ),
                    ],
                  ),
                );
              }).toList(),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Another Variant"),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.royalMaroon),
                ),
              ),

              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("SAVE CHANGES"),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/services/news_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class WeatherUpdateForm extends StatefulWidget {
  final WeatherUpdate? initialUpdate;

  const WeatherUpdateForm({super.key, this.initialUpdate});

  @override
  State<WeatherUpdateForm> createState() => _WeatherUpdateFormState();
}

class _WeatherUpdateFormState extends State<WeatherUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _urlController = TextEditingController();

  final NewsApiService _apiService = NewsApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUpdate != null) {
      _titleController.text = widget.initialUpdate!.title;
      _descController.text = widget.initialUpdate!.description;
      _dateController.text = widget.initialUpdate!.date;
      _urlController.text = widget.initialUpdate!.imageUrl;
    } else {
      _dateController.text = DateTime.now().toIso8601String().split('T').first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 30, maxWidth: 800);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUri = 'data:image/jpeg;base64,$base64String';
        if (mounted) {
          setState(() {
            _urlController.text = dataUri;
          });
        }
      } catch (e) {
        _showError('Error processing image: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_urlController.text.isEmpty) {
        _showError('Please pick an image.');
        return;
      }
      setState(() => _isLoading = true);

      try {
        final update = WeatherUpdate(
          id: widget.initialUpdate?.id ?? '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          date: _dateController.text.trim(),
          imageUrl: _urlController.text.trim(),
        );

        if (widget.initialUpdate == null) {
          await _apiService.createUpdate(update);
        } else {
          await _apiService.editUpdate(update.id, update);
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true means success
        }
      } catch (e) {
        if (mounted) {
          _showError('Error: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialUpdate == null
                          ? 'New Update'
                          : 'Edit Update',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                const Text('Image Attachment',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: _urlController.text.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _urlController.text.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(
                                      _urlController.text.split(',').last),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey),
                                )
                              : Image.network(
                                  _urlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey),
                                ),
                        )
                      : const Center(
                          child:
                              Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pick Image from Device',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF29B6F6),
                    side: const BorderSide(color: Color(0xFF29B6F6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29B6F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Save Update',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

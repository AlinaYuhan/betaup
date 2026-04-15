import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api_client.dart';

/// Bottom sheet for submitting a coach certification application.
/// Pops with `true` on success.
class CoachApplySheet extends StatefulWidget {
  const CoachApplySheet({super.key, required this.client});
  final ApiClient client;

  @override
  State<CoachApplySheet> createState() => _CoachApplySheetState();
}

class _CoachApplySheetState extends State<CoachApplySheet> {
  final _resumeCtrl = TextEditingController();
  XFile? _selectedImage;
  Uint8List? _selectedImagePreviewBytes;
  bool _submitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _resumeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final previewBytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedImage = picked;
      _selectedImagePreviewBytes = previewBytes;
      _errorMsg = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      setState(() => _errorMsg = "请先选择证书图片");
      return;
    }
    setState(() { _submitting = true; _errorMsg = null; });
    try {
      await widget.client.applyForCoach(
        imageFile: _selectedImage!,
        resumeText: _resumeCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() { _errorMsg = e.toString(); _submitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  "申请教练认证",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "提交您的教练资质证书和简介，管理员审核通过后将获得「教练」标识。",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Certificate image picker
          GestureDetector(
            onTap: _submitting ? null : _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedImage != null
                      ? Colors.orange.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: _selectedImagePreviewBytes != null
                          ? Image.memory(
                              _selectedImagePreviewBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Container(
                              color: Colors.black.withValues(alpha: 0.06),
                              alignment: Alignment.center,
                              child: Text(
                                _selectedImage!.name,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 36,
                            color: Colors.grey.shade500),
                        const SizedBox(height: 8),
                        Text("点击上传证书图片",
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Resume text
          TextField(
            controller: _resumeCtrl,
            maxLines: 4,
            maxLength: 400,
            decoration: const InputDecoration(
              labelText: "个人简介（选填）",
              hintText: "介绍您的攀岩教学经历、资质等...",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMsg!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("提交申请"),
            ),
          ),
        ],
      ),
    );
  }
}

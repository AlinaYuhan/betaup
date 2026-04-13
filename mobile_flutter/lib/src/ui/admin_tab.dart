import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../session/app_session.dart';

class AdminTab extends StatefulWidget {
  const AdminTab({super.key});

  @override
  State<AdminTab> createState() => AdminTabState();
}

class AdminTabState extends State<AdminTab> {
  List<CertificationReview> _pending = [];
  bool _loading = true;
  bool _initialized = false;
  String? _error;
  String _serverRoot = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Extract scheme+authority from baseUrl regardless of path suffix.
      final uri = Uri.parse(SessionScope.of(context).api.baseUrl);
      _serverRoot = '${uri.scheme}://${uri.authority}';
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = SessionScope.of(context);
      final list = await session.api.fetchPendingCertifications();
      if (mounted) setState(() { _pending = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _approve(CertificationReview review) async {
    final confirmed = await _confirmDialog(
      context,
      title: "通过申请",
      message: "确认通过 ${review.userName} 的教练认证申请吗？",
      confirmLabel: "通过",
      confirmColor: Colors.green,
    );
    if (confirmed != true || !mounted) return;
    try {
      await SessionScope.of(context).api.approveCertification(review.certificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("已通过认证申请")));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("操作失败：$e")));
      }
    }
  }

  Future<void> _reject(CertificationReview review) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("拒绝申请"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("填写拒绝理由（将通知给 ${review.userName}）"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "拒绝原因...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("拒绝", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (confirmed != true || !mounted) return;
    try {
      await SessionScope.of(context).api.rejectCertification(
        review.certificationId,
        reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("已拒绝认证申请")));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("操作失败：$e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("教练认证审核"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "刷新",
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text("重试")),
                      ],
                    ),
                  ),
                )
          : _pending.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 56, color: Colors.green),
                      SizedBox(height: 16),
                      Text("暂无待审核的认证申请",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _pending.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _ReviewCard(
                          review: _pending[i],
                          serverRoot: _serverRoot,
                          onApprove: () => _approve(_pending[i]),
                          onReject: () => _reject(_pending[i]),
                        ),
                  ),
                ),
    );
  }
}

// ── Confirm dialog helper ────────────────────────────────────────────────────

Future<bool?> _confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  Color confirmColor = Colors.orange,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消")),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// ── Review card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.serverRoot,
    required this.onApprove,
    required this.onReject,
  });
  final CertificationReview review;
  final String serverRoot;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final dateStr = review.appliedAt != null
        ? DateFormat("yyyy-MM-dd HH:mm").format(review.appliedAt!)
        : "—";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.orange,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(review.userEmail,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Text(dateStr,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),

            // Certificate image
            const SizedBox(height: 12),
            if (review.certificateImageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _showFullImage(context, serverRoot + review.certificateImageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    serverRoot + review.certificateImageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.grey.shade800,
                      child: const Center(
                          child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),

            // Resume text
            if (review.resumeText?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(review.resumeText!,
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Colors.red),
                    label: const Text("拒绝",
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text("通过"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

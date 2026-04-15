import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import 'post_media.dart';
import 'post_media_grid.dart';

/// Full post view with comments — used when navigating from a notification.
/// Build [client] from a valid context BEFORE calling showModalBottomSheet.
class PostDetailSheet extends StatefulWidget {
  const PostDetailSheet({
    super.key,
    required this.postId,
    required this.client,
    required this.currentUserId,
  });
  final int postId;
  final ApiClient client;
  final int? currentUserId;

  @override
  State<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<PostDetailSheet> {
  Post? _post;
  List<Comment> _comments = [];
  bool _loadingPost = true;
  bool _submitting = false;
  Comment? _replyTarget;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final post = await widget.client.fetchPost(widget.postId);
      final comments = await widget.client.fetchComments(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _comments = comments;
          _loadingPost = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPost = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final comment = await widget.client.addComment(
        widget.postId,
        content,
        parentId: _replyTarget?.id,
      );
      _controller.clear();
      if (mounted) {
        setState(() {
          _comments.add(comment);
          _replyTarget = null;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _deleteComment(Comment c) async {
    try {
      await widget.client.deleteComment(widget.postId, c.id);
      if (mounted) {
        setState(() => _comments.removeWhere((x) => x.id == c.id));
      }
    } catch (_) {}
  }

  void _setReply(Comment c) {
    setState(() => _replyTarget = c);
    _focusNode.requestFocus();
  }

  Future<void> _showCommentMenu(Comment c) async {
    final isOwn = widget.currentUserId == c.authorId;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text("回复"),
              onTap: () => Navigator.pop(context, "回复"),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("复制"),
              onTap: () => Navigator.pop(context, "复制"),
            ),
            if (isOwn)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("删除", style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, "删除"),
              ),
          ],
        ),
      ),
    );
    if (selected == "回复") {
      _setReply(c);
    } else if (selected == "复制") {
      await Clipboard.setData(ClipboardData(text: c.content));
    } else if (selected == "删除") {
      await _deleteComment(c);
    }
  }

  List<Comment> get _ordered {
    final tops = _comments.where((c) => c.parentId == null).toList();
    final result = <Comment>[];
    for (final top in tops) {
      result.add(top);
      result.addAll(_comments.where((c) => c.parentId == top.id));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPost) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (_post == null) {
      return const SizedBox(
          height: 120, child: Center(child: Text("帖子不存在或已删除")));
    }

    final post = _post!;
    final timeStr = post.createdAt != null
        ? DateFormat("MM-dd HH:mm").format(post.createdAt!)
        : "";
    final ordered = _ordered;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // Post header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha(60),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.orange,
                      child: Text(
                        post.authorName.isNotEmpty
                            ? post.authorName[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(timeStr,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (post.content.isNotEmpty) Text(post.content),
                if (post.allMediaUrls.isNotEmpty && post.mediaKind != null) ...[
                  SizedBox(height: post.content.isNotEmpty ? 12 : 0),
                  if (post.allMediaUrls.length == 1 && post.mediaKind == PostMediaKind.video)
                    PostMediaView(
                      apiBaseUrl: widget.client.baseUrl,
                      mediaUrl: post.allMediaUrls[0],
                      mediaKind: post.mediaKind!,
                      maxHeight: 320,
                    )
                  else
                    PostMediaGridView(
                      apiBaseUrl: widget.client.baseUrl,
                      mediaUrls: post.allMediaUrls,
                      maxHeight: 320,
                    ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${post.likeCount}",
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${post.commentCount}",
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ],
            ),
          ),
          // Comments section header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text("评论 (${_comments.length})",
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          // Comments list
          Expanded(
            child: ordered.isEmpty
                ? const Center(child: Text("还没有评论，来说第一句！"))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: ordered.length,
                    itemBuilder: (_, i) {
                      final c = ordered[i];
                      final isReply = c.parentId != null;
                      return GestureDetector(
                        onTap: () => _setReply(c),
                        onLongPress: () => _showCommentMenu(c),
                        child: Padding(
                          padding: EdgeInsets.only(left: isReply ? 48.0 : 0.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: isReply ? 14 : 20,
                              backgroundColor:
                                  isReply ? Colors.grey : Colors.orange,
                              child: Text(
                                c.authorName.isNotEmpty
                                    ? c.authorName[0].toUpperCase()
                                    : "?",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isReply ? 11 : 14),
                              ),
                            ),
                            title: Text(c.authorName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isReply ? 12 : 13)),
                            subtitle: Text(c.content),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          // Reply banner
          if (_replyTarget != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.orange.withAlpha(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text("回复 ${_replyTarget!.authorName}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orange)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyTarget = null),
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          // Comment input
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: _replyTarget != null
                          ? "回复 ${_replyTarget!.authorName}..."
                          : "写评论...",
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.orange),
                  onPressed: _submitting ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

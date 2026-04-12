import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';
import 'common.dart';
import 'user_profile_sheet.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _allKey = GlobalKey<_FeedListState>();
  final _partnerKey = GlobalKey<_FeedListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPostCreated() {
    debugPrint("[FEED] onPostCreated, allKeyState=${_allKey.currentState}");
    _allKey.currentState?.reload();
    _partnerKey.currentState?.reload();
  }

  Future<void> _showCreatePost() async {
    final session = SessionScope.of(context);
    final client = ApiClient(readToken: () => session.token);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreatePostSheet(client: client),
    );
    if (result == true) _onPostCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("社区"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "全部动态"),
            Tab(text: "找搭子"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePost,
        icon: const Icon(Icons.edit_rounded),
        label: const Text("发动态"),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedList(key: _allKey, type: null),
          _FeedList(key: _partnerKey, type: PostType.findPartner),
        ],
      ),
    );
  }
}

class _FeedList extends StatefulWidget {
  const _FeedList({super.key, required this.type});
  final PostType? type;

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList> {
  List<Post> _posts = [];
  bool _loading = true;
  bool _loaded = false;
  int? _lastProfileVersion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final version = SessionScope.of(context).profileVersion;
    if (!_loaded) {
      _loaded = true;
      _lastProfileVersion = version;
      _load();
    } else if (_lastProfileVersion != version) {
      _lastProfileVersion = version;
      _load();
    }
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    debugPrint("[FEED] _load start, type=${widget.type}");
    setState(() => _loading = true);
    try {
      final session = SessionScope.of(context);
      final client = ApiClient(readToken: () => session.token);
      final posts = await client.fetchPosts(type: widget.type?.rawValue);
      debugPrint("[FEED] _load success, count=${posts.length}");
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("[FEED] _load error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(Post post) async {
    final session = SessionScope.of(context);
    final client = ApiClient(readToken: () => session.token);
    try {
      if (post.likedByMe) {
        await client.unlikePost(post.id);
        if (mounted) {
          setState(() {
            final i = _posts.indexWhere((p) => p.id == post.id);
            if (i >= 0) {
              _posts[i] =
                  post.copyWith(likeCount: post.likeCount - 1, likedByMe: false);
            }
          });
        }
      } else {
        await client.likePost(post.id);
        if (mounted) {
          setState(() {
            final i = _posts.indexWhere((p) => p.id == post.id);
            if (i >= 0) {
              _posts[i] =
                  post.copyWith(likeCount: post.likeCount + 1, likedByMe: true);
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _deletePost(Post post) async {
    final session = SessionScope.of(context);
    final client = ApiClient(readToken: () => session.token);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("删除动态"),
        content: const Text("确定要删除这条动态吗？"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("取消")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await client.deletePost(post.id);
      if (mounted) setState(() => _posts.removeWhere((p) => p.id == post.id));
    } catch (_) {}
  }

  Future<void> _openUserProfile(Post post) async {
    final session = SessionScope.of(context);
    final currentUserId = session.user?.id;
    if (currentUserId == post.authorId) return;
    final client = ApiClient(readToken: () => session.token);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UserProfileSheet(userId: post.authorId, client: client),
    );
    _load();
  }

  Future<void> _openComments(Post post) async {
    final session = SessionScope.of(context);
    final client = ApiClient(readToken: () => session.token);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(
        post: post,
        client: client,
        currentUserId: SessionScope.of(context).user?.id,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_posts.isEmpty) {
      return const Center(child: Text("还没有动态，来发第一条吧！🧗"));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => _PostCard(
          post: _posts[i],
          onLike: () => _toggleLike(_posts[i]),
          onComment: () => _openComments(_posts[i]),
          onAuthorTap: () => _openUserProfile(_posts[i]),
          onDelete: SessionScope.of(context).user?.id == _posts[i].authorId
              ? () => _deletePost(_posts[i])
              : null,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onAuthorTap,
    this.onDelete,
  });
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onAuthorTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final timeStr = post.createdAt != null
        ? DateFormat("MM-dd HH:mm").format(post.createdAt!)
        : "";
    return GestureDetector(
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onAuthorTap,
              child: Row(
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
                  Expanded(
                    child: Column(
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
                  ),
                  if (post.type == PostType.findPartner)
                    const Chip(
                      label: Text("找搭子",
                          style: TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(post.content,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: post.likedByMe ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  onPressed: onLike,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text("${post.likeCount}",
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 20, color: Colors.grey),
                  onPressed: onComment,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text("${post.commentCount}",
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({required this.client});
  final ApiClient client;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _controller = TextEditingController();
  PostType _type = PostType.general;
  bool _submitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    debugPrint("[POST] _submit called, content='$content'");
    if (content.isEmpty) {
      debugPrint("[POST] content is empty, returning");
      return;
    }
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });
    try {
      debugPrint("[POST] calling createPost...");
      final post = await widget.client.createPost(content: content, type: _type);
      debugPrint("[POST] created successfully: id=${post.id}");
      if (!mounted) return;
      if (post.newlyUnlockedBadges.isNotEmpty) {
        await showBadgeUnlockDialog(context, post.newlyUnlockedBadges);
        if (!mounted) return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("[POST] createPost error: $e");
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("发布动态",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: "分享你的攀岩故事、路线心得，或发起找搭子...",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("类型："),
              ChoiceChip(
                label: const Text("普通动态"),
                selected: _type == PostType.general,
                onSelected: (_) => setState(() => _type = PostType.general),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("找搭子"),
                selected: _type == PostType.findPartner,
                onSelected: (_) =>
                    setState(() => _type = PostType.findPartner),
              ),
            ],
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(
              "发布失败：$_errorMsg",
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
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text("发布"),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.post,
    required this.client,
    required this.currentUserId,
  });
  final Post post;
  final ApiClient client;
  final int? currentUserId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Comment> _comments = [];
  bool _loaded = false;
  bool _submitting = false;
  Comment? _replyTarget;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.client.fetchComments(widget.post.id);
      if (mounted) {
        setState(() { _comments = comments; _loaded = true; });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final comment = await widget.client.addComment(
        widget.post.id,
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(Comment c) async {
    try {
      await widget.client.deleteComment(widget.post.id, c.id);
      if (mounted) {
        setState(() => _comments.removeWhere((x) => x.id == c.id));
      }
    } catch (_) {}
  }

  void _setReply(Comment c) {
    setState(() => _replyTarget = c);
    _focusNode.requestFocus();
  }

  /// Long-press menu: 回复 / 复制 / 删除(own only)
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
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("删除",
                    style: TextStyle(color: Colors.red)),
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

  /// Flat ordered list: top-level comments, each followed by its replies.
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
    final ordered = _ordered;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text("评论 (${_comments.length})",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : ordered.isEmpty
                    ? const Center(child: Text("还没有评论，来说第一句！"))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: ordered.length,
                        itemBuilder: (_, i) {
                          final c = ordered[i];
                          final isReply = c.parentId != null;
                          return GestureDetector(
                            // Tap any comment → enter reply mode
                            onTap: () => _setReply(c),
                            // Long press → action menu
                            onLongPress: () => _showCommentMenu(c),
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: isReply ? 48.0 : 0.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: isReply ? 14 : 20,
                                  backgroundColor: isReply
                                      ? Colors.grey
                                      : Colors.orange,
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
          if (_replyTarget != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
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

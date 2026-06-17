import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_theme.dart';
import '../../teachers/models/teacher.dart';
import '../models/training.dart';
import '../providers/training_provider.dart';

class TeacherTrainingScreen extends StatefulWidget {
  final TeacherRecord user;
  const TeacherTrainingScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<TeacherTrainingScreen> createState() => _TeacherTrainingScreenState();
}

class _TeacherTrainingScreenState extends State<TeacherTrainingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _expandedComments = {};
  XFile? _selectedImage;
  bool _isCreatorExpanded = false;
  bool _isUploadingImage = false;
  String _fontStyle = 'sans';

  @override
  void dispose() {
    _searchController.dispose();
    _contentController.dispose();
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingProvider>();
    final posts = provider.teacherPosts();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: provider.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search posts, training, authors...',
              prefixIcon: const Icon(LucideIcons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        _buildCreator(provider),
        Expanded(
          child: StreamBuilder<List<TrainingApplication>>(
            stream: provider.applicationsForTeacher(widget.user.id),
            builder: (context, applicationSnapshot) {
              final applications = applicationSnapshot.data ?? [];
              final appByPost = {
                for (final app in applications) app.postId: app,
              };

              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (posts.isEmpty) {
                return const Center(child: Text('No posts yet.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) => _buildPostCard(
                  provider,
                  posts[index],
                  appByPost[posts[index].id],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreator(TrainingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF0EFEC)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () =>
                  setState(() => _isCreatorExpanded = !_isCreatorExpanded),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 16, child: Text(_initial(widget.user.fullName))),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text('Share something...',
                          style: TextStyle(color: Colors.grey))),
                  Icon(
                      _isCreatorExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.plusCircle,
                      color: AppTheme.primaryColor),
                ],
              ),
            ),
            if (_isCreatorExpanded) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Write here...'),
              ),
              const SizedBox(height: 12),
              _buildImagePickerRow(),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Bullet',
                    icon: const Icon(LucideIcons.list),
                    onPressed: () => _contentController.text =
                        '${_contentController.text}\n- ',
                  ),
                  IconButton(
                    tooltip: 'Link',
                    icon: const Icon(LucideIcons.link),
                    onPressed: () => _contentController.text =
                        '${_contentController.text} https://',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_fontStyle),
                      initialValue: _fontStyle,
                      items: const [
                        DropdownMenuItem(value: 'sans', child: Text('Default')),
                        DropdownMenuItem(
                            value: 'console_mono', child: Text('Console Mono')),
                        DropdownMenuItem(
                            value: 'book_serif', child: Text('Book Serif')),
                        DropdownMenuItem(
                            value: 'playful_blue', child: Text('Playful Blue')),
                        DropdownMenuItem(
                            value: 'warm_gold', child: Text('Warm Gold')),
                      ],
                      onChanged: (value) =>
                          setState(() => _fontStyle = value ?? 'sans'),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage
                        ? null
                        : () => _createSocialPost(provider),
                    icon: const Icon(LucideIcons.send, size: 16),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Post'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(TrainingProvider provider, TrainingPost post,
      TrainingApplication? application,
      {bool allowApplication = true}) {
    final isLiked = post.likes.contains(widget.user.id);
    final commentsExpanded = _expandedComments.contains(post.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFF0EFEC))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showFacultyProfile(provider, post.authorId),
                  child: CircleAvatar(child: Text(_initial(post.authorName))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(post.authorRole,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(DateFormat('MMM dd').format(post.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (post.isTraining)
              _buildTrainingPanel(
                provider,
                post,
                application,
                allowApplication: allowApplication,
              ),
            _buildFormattedContent(post),
            if (post.photoUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                IconButton(
                  icon:
                      Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                  color: isLiked ? AppTheme.primaryColor : null,
                  onPressed: () => provider.toggleLike(post, widget.user.id),
                ),
                Text('${post.likes.length}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(LucideIcons.messageSquare),
                  onPressed: () => setState(() {
                    commentsExpanded
                        ? _expandedComments.remove(post.id)
                        : _expandedComments.add(post.id);
                  }),
                ),
                Text('${post.commentsCount}'),
              ],
            ),
            if (commentsExpanded) _buildComments(provider, post),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingPanel(TrainingProvider provider, TrainingPost post,
      TrainingApplication? application,
      {bool allowApplication = true}) {
    final remaining = post.remainingSeats;
    final isEnrolled = post.traineeIds.contains(widget.user.id);
    final canApply = allowApplication &&
        post.isOpenVolunteer &&
        !post.isFull &&
        application == null &&
        !isEnrolled;
    final statusText = isEnrolled ? 'Approved' : application?.status;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.graduationCap,
                  size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(post.trainingTitle ?? 'CPD Session',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor))),
              _badge(post.isOpenVolunteer ? 'Open' : 'Assigned'),
            ],
          ),
          if ((post.trainingDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.trainingDescription!),
          ],
          const SizedBox(height: 8),
          Text(
            remaining == null
                ? 'Seats: ${post.seatsTaken} enrolled'
                : 'Remaining seats: $remaining of ${post.maxTrainees}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (statusText != null) _badge(statusText),
              const Spacer(),
              ElevatedButton(
                onPressed: canApply && !provider.isPostBusy(post.id)
                    ? () => _apply(provider, post)
                    : null,
                child: Text(allowApplication
                    ? _trainingButtonText(post, application, isEnrolled)
                    : 'View in feed'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComments(TrainingProvider provider, TrainingPost post) {
    final controller =
        _commentControllers.putIfAbsent(post.id, TextEditingController.new);

    return Column(
      children: [
        StreamBuilder<List<TrainingComment>>(
          stream: provider.commentsForPost(post.id),
          builder: (context, snapshot) {
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No comments yet.',
                        style: TextStyle(color: Colors.grey))),
              );
            }

            return Column(
              children: comments
                  .map((comment) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                            radius: 14,
                            child: Text(_initial(comment.authorName))),
                        title: Text(comment.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: AppTheme.textColor, height: 1.3),
                            children: _linkSpans(
                              comment.text,
                              const TextStyle(
                                  color: AppTheme.textColor, height: 1.3),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder()),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.send),
              onPressed: () async {
                await provider.addComment(
                  postId: post.id,
                  authorId: widget.user.id,
                  authorName: widget.user.fullName,
                  authorRole: widget.user.role,
                  text: controller.text,
                );
                controller.clear();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormattedContent(TrainingPost post) {
    final style = _contentStyle(post.fontStyle);
    final lines = post.content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: style),
                Expanded(
                    child: RichText(
                        text: TextSpan(
                            style: style,
                            children:
                                _linkSpans(trimmed.substring(2), style)))),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
              text: TextSpan(style: style, children: _linkSpans(line, style))),
        );
      }).toList(),
    );
  }

  TextStyle _contentStyle(String fontStyle) {
    switch (fontStyle) {
      case 'console_mono':
        return const TextStyle(
            fontFamily: 'monospace', color: Color(0xFF263238), height: 1.35);
      case 'book_serif':
        return const TextStyle(
            fontFamily: 'serif',
            fontSize: 16,
            color: Color(0xFF3F3428),
            height: 1.4);
      case 'playful_blue':
        return const TextStyle(
            fontSize: 16,
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
            height: 1.35);
      case 'warm_gold':
        return const TextStyle(
            fontSize: 16,
            color: Color(0xFF9A6514),
            fontWeight: FontWeight.w600,
            height: 1.35);
      default:
        return const TextStyle(color: AppTheme.textColor, height: 1.35);
    }
  }

  List<TextSpan> _linkSpans(String text, TextStyle style) {
    final regex = RegExp(r'(https?:\/\/[^\s]+)');
    final spans = <TextSpan>[];
    var index = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: style.copyWith(
            color: Colors.blue, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()..onTap = () => _showLink(url),
      ));
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return spans;
  }

  Future<void> _createSocialPost(TrainingProvider provider) async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    try {
      setState(() => _isUploadingImage = true);
      final photoUrl = _selectedImage == null
          ? ''
          : await provider.uploadImageToStorage(
              _selectedImage!, widget.user.id);

      await provider.createPost(TrainingPost(
        id: '',
        authorId: widget.user.id,
        authorName: widget.user.fullName,
        authorRole: widget.user.role,
        content: content,
        photoUrl: photoUrl,
        likes: const [],
        commentsCount: 0,
        createdAt: DateTime.now(),
        fontStyle: _fontStyle,
        isTraining: false,
        traineeIds: const [],
      ));

      _contentController.clear();
      setState(() {
        _selectedImage = null;
        _isCreatorExpanded = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _apply(TrainingProvider provider, TrainingPost post) async {
    try {
      await provider.applyForCourse(post, widget.user.id, widget.user.fullName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showFacultyProfile(
      TrainingProvider provider, String authorId) async {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<TeacherRecord?>(
        future: provider.getFacultyProfile(authorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                height: 180, child: Center(child: CircularProgressIndicator()));
          }
          final faculty = snapshot.data;
          if (faculty == null) {
            return const SizedBox(
                height: 160,
                child: Center(child: Text('Profile unavailable.')));
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StreamBuilder<List<TrainingPost>>(
                stream: provider.getPostsByAuthor(authorId),
                builder: (context, postsSnapshot) {
                  final posts = postsSnapshot.data ?? [];

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                              radius: 24,
                              child: Text(_initial(faculty.fullName))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(faculty.fullName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(faculty.role,
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _profileLine('School info',
                          _profileValueOrFallback(faculty.address)),
                      _profileLine(
                          'Ethics points', faculty.currentScore.toString()),
                      _profileLine(
                          'Emergency contact',
                          _profileValue(faculty.emergencyContactName).isEmpty
                              ? 'Not provided'
                              : '${_profileValue(faculty.emergencyContactName)} ${_profileValue(faculty.emergencyContactNumber)}'),
                      const Divider(height: 32),
                      if (postsSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (posts.isEmpty)
                        const Center(child: Text('No posts yet.'))
                      else
                        ...posts.map(
                          (post) => _buildPostCard(
                            provider,
                            post,
                            null,
                            allowApplication: false,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _profileLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.subtleGrayBoundary)),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _trainingButtonText(
      TrainingPost post, TrainingApplication? application, bool isEnrolled) {
    if (isEnrolled) return 'Enrolled';
    if (!post.isOpenVolunteer) return 'Assigned only';
    if (post.isFull) return 'Fully booked';
    if (application != null) return application.status;
    return 'Apply';
  }

  Widget _buildImagePickerRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(LucideIcons.image, size: 16),
            label: Text(_selectedImage == null ? 'Add image' : 'Change image'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedImage?.name ?? 'No image selected',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          if (_selectedImage != null)
            IconButton(
              tooltip: 'Remove image',
              icon: const Icon(LucideIcons.x),
              onPressed: () => setState(() => _selectedImage = null),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    setState(() => _selectedImage = image);
  }

  Future<void> _showLink(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  String _profileValue(Object? value) => (value ?? '').toString().trim();

  String _profileValueOrFallback(Object? value) {
    final text = _profileValue(value);
    return text.isEmpty ? 'Not provided' : text;
  }

  String _initial(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? '?' : text[0].toUpperCase();
  }
}

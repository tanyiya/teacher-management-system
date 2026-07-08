import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

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
  final List<LocalAttachment> _attachments = [];
  bool _isCreatorExpanded = false;
  bool _isUploadingImage = false;

  // ---- Shared, feed-style type scale (LinkedIn/Facebook-like, compact) ----
  static const _colorPrimaryText = Color(0xFF1A1A1A);
  static const _colorSecondaryText = Color(0xFF65676B);

  static const _authorNameStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: _colorPrimaryText,
  );
  static const _authorRoleStyle = TextStyle(
    fontSize: 11.5,
    color: _colorSecondaryText,
  );
  static const _dateStyle = TextStyle(
    fontSize: 11,
    color: _colorSecondaryText,
  );
  static const _metaCountStyle = TextStyle(
    fontSize: 12.5,
    color: _colorSecondaryText,
    fontWeight: FontWeight.w500,
  );
  static const _inputTextStyle = TextStyle(fontSize: 13.5);
  static const _hintStyle = TextStyle(fontSize: 13, color: _colorSecondaryText);

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: provider.updateSearchQuery,
                  style: _inputTextStyle,
                  decoration: InputDecoration(
                    hintText: 'Search posts, training, authors...',
                    hintStyle: _hintStyle,
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: _colorSecondaryText),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.subtleGrayBoundary)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.subtleGrayBoundary)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                      return const Center(child: Text('No posts yet.', style: _authorRoleStyle));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
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
          ),
        ),
      ),
    );
  }

  Widget _buildCreator(TrainingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.subtleGrayBoundary),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () =>
                  setState(() => _isCreatorExpanded = !_isCreatorExpanded),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 15,
                      child: Text(_initial(widget.user.fullName),
                          style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Share something...',
                          style: TextStyle(fontSize: 13, color: _colorSecondaryText))),
                  Icon(
                      _isCreatorExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.plusCircle,
                      size: 18,
                      color: AppTheme.primaryColor),
                ],
              ),
            ),
            if (_isCreatorExpanded) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 4,
                style: _inputTextStyle,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Write here...',
                    hintStyle: _hintStyle,
                    contentPadding: const EdgeInsets.all(10)),
              ),
              const SizedBox(height: 10),
              _buildAttachmentPickerRow(),
              Row(
                children: [
                  _compactIconButton(
                    tooltip: 'Bullet',
                    icon: LucideIcons.list,
                    color: _colorSecondaryText,
                    onPressed: () => _contentController.text =
                        '${_contentController.text}\n- ',
                  ),
                  _compactIconButton(
                    tooltip: 'Link',
                    icon: LucideIcons.link,
                    color: _colorSecondaryText,
                    onPressed: () => _contentController.text =
                        '${_contentController.text} https://',
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage
                        ? null
                        : () => _createSocialPost(provider),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(LucideIcons.send, size: 15),
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
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.subtleGrayBoundary)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showFacultyProfile(provider, post.authorId),
                  child: CircleAvatar(
                    radius: 17,
                    child: Text(_initial(post.authorName),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: _authorNameStyle),
                      Text(post.authorRole, style: _authorRoleStyle),
                    ],
                  ),
                ),
                Text(DateFormat('MMM dd').format(post.createdAt), style: _dateStyle),
              ],
            ),
            const SizedBox(height: 10),
            if (post.isTraining)
              _buildTrainingPanel(
                provider,
                post,
                application,
                allowApplication: allowApplication,
              ),
            _buildFormattedContent(post),
            if (post.photoUrl.isNotEmpty || post.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildAttachmentsGrid(post),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.subtleGrayBoundary),
            const SizedBox(height: 4),
            Row(
              children: [
                _compactIconButton(
                  icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: isLiked ? AppTheme.primaryColor : _colorSecondaryText,
                  onPressed: () => provider.toggleLike(post, widget.user.id),
                ),
                Text('${post.likes.length}', style: _metaCountStyle),
                const SizedBox(width: 14),
                _compactIconButton(
                  icon: LucideIcons.messageSquare,
                  color: _colorSecondaryText,
                  onPressed: () => setState(() {
                    commentsExpanded
                        ? _expandedComments.remove(post.id)
                        : _expandedComments.add(post.id);
                  }),
                ),
                Text('${post.commentsCount}', style: _metaCountStyle),
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
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.graduationCap,
                  size: 17, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(post.trainingTitle ?? 'CPD Session',
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor))),
              _badge(post.isOpenVolunteer ? 'Open' : 'Assigned'),
            ],
          ),
          if ((post.trainingDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(post.trainingDescription!,
                style: const TextStyle(fontSize: 13, height: 1.35, color: _colorPrimaryText)),
          ],
          const SizedBox(height: 6),
          Text(
            remaining == null
                ? 'Seats: ${post.seatsTaken} enrolled'
                : 'Remaining seats: $remaining of ${post.maxTrainees}',
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: _colorSecondaryText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (statusText != null) _badge(statusText),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No comments yet.', style: _authorRoleStyle)),
              );
            }

            return Column(
              children: comments
                  .map((comment) => ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                            radius: 12,
                            child: Text(_initial(comment.authorName),
                                style: const TextStyle(fontSize: 11))),
                        title: Text(comment.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                        subtitle: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: _colorPrimaryText, height: 1.3),
                            children: _linkSpans(
                              context,
                              comment.text,
                              const TextStyle(
                                  fontSize: 13, color: _colorPrimaryText, height: 1.3),
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
                style: _inputTextStyle,
                decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: _hintStyle,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder()),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 6),
            _compactIconButton(
              icon: LucideIcons.send,
              color: AppTheme.primaryColor,
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
                                _linkSpans(context, trimmed.substring(2), style)))),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
              text: TextSpan(style: style, children: _linkSpans(context, line, style))),
        );
      }).toList(),
    );
  }

  TextStyle _contentStyle(String fontStyle) {
    switch (fontStyle) {
      case 'console_mono':
        return const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFF263238),
            height: 1.35);
      case 'book_serif':
        return const TextStyle(
            fontFamily: 'serif',
            fontSize: 13.5,
            color: Color(0xFF3F3428),
            height: 1.4);
      case 'playful_blue':
        return const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
            height: 1.35);
      case 'warm_gold':
        return const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF9A6514),
            fontWeight: FontWeight.w600,
            height: 1.35);
      default:
        return const TextStyle(fontSize: 13.5, color: _colorPrimaryText, height: 1.4);
    }
  }

  List<TextSpan> _linkSpans(BuildContext context, String text, TextStyle style) {
    final regex = RegExp(r'((?:https?:\/\/)?(?:www\.)?[^\s]+\.[^\s]{2,})');
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
        recognizer: TapGestureRecognizer()
          ..onTap = () => context.read<TrainingProvider>().openUrl(url),
      ));
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return spans;
  }

  Future<void> _createSocialPost(TrainingProvider provider) async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _attachments.isEmpty) return;

    try {
      setState(() => _isUploadingImage = true);
      
      final uploadedAttachments = await Future.wait<Map<String, String>>(
        _attachments.map((attachment) async {
          final url = await provider.uploadFileToStorage(
            File(attachment.path), 
            widget.user.id
          );
          return <String, String>{
            'url': url,
            'name': attachment.name,
            'type': attachment.isImage ? 'image' : 'file',
          };
        })
      );

      await provider.createPost(TrainingPost(
        id: '',
        authorId: widget.user.id,
        authorName: widget.user.fullName,
        authorRole: widget.user.role,
        content: content,
        photoUrl: '', // Using attachments array instead
        attachments: uploadedAttachments,
        likes: const [],
        commentsCount: 0,
        createdAt: DateTime.now(),
        fontStyle: 'sans',
        isTraining: false,
        traineeIds: const [],
      ));

      _contentController.clear();
      setState(() {
        _attachments.clear();
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
                child: Center(child: Text('Profile unavailable.', style: _authorRoleStyle)));
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
                              radius: 22,
                              child: Text(_initial(faculty.fullName),
                                  style: const TextStyle(fontSize: 16))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(faculty.fullName,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700)),
                                Text(faculty.role, style: _authorRoleStyle),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _profileLine('School info',
                          _profileValueOrFallback(faculty.address)),
                      _profileLine(
                          'Ethics points', faculty.currentScore.toString()),
                      _profileLine(
                          'Emergency contact',
                          _profileValue(faculty.emergencyContactName).isEmpty
                              ? 'Not provided'
                              : '${_profileValue(faculty.emergencyContactName)} ${_profileValue(faculty.emergencyContactNumber)}'),
                      Divider(height: 28, color: AppTheme.subtleGrayBoundary),
                      if (postsSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (posts.isEmpty)
                        const Center(child: Text('No posts yet.', style: _authorRoleStyle))
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label, style: _authorRoleStyle)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, color: _colorPrimaryText))),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.subtleGrayBoundary)),
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildAttachmentPickerRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final attachment = entry.value;
                return Chip(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  avatar: Icon(
                    attachment.isImage ? LucideIcons.image : LucideIcons.fileText,
                    size: 16,
                  ),
                  onDeleted: () => setState(() => _attachments.removeAt(index)),
                );
              }).toList(),
            ),
          ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickImages,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                textStyle: const TextStyle(fontSize: 12.5),
                side: BorderSide(color: AppTheme.subtleGrayBoundary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.image, size: 15),
              label: const Text('Add images'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                textStyle: const TextStyle(fontSize: 12.5),
                side: BorderSide(color: AppTheme.subtleGrayBoundary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.file, size: 15),
              label: const Text('Add files'),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          _attachments.add(LocalAttachment(path: img.path, name: img.name, isImage: true));
        }
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (var file in result.files) {
          if (file.path != null) {
            _attachments.add(LocalAttachment(
              path: file.path!,
              name: file.name,
              isImage: file.extension?.toLowerCase() == 'jpg' || 
                       file.extension?.toLowerCase() == 'png' || 
                       file.extension?.toLowerCase() == 'jpeg',
            ));
          }
        }
      });
    }
  }

  Widget _buildAttachmentsGrid(TrainingPost post) {
    final List<Map<String, String>> items = [];
    if (post.photoUrl.isNotEmpty) {
      items.add({'url': post.photoUrl, 'name': 'Image', 'type': 'image'});
    }
    items.addAll(post.attachments);

    if (items.isEmpty) return const SizedBox.shrink();

    if (items.length == 1) {
      return _buildAttachmentItem(items.first, items);
    }

    if (items.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildAttachmentItem(items[0], items, height: 200)),
          const SizedBox(width: 4),
          Expanded(child: _buildAttachmentItem(items[1], items, height: 200)),
        ],
      );
    }

    if (items.length == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _buildAttachmentItem(items[0], items, height: 300)),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildAttachmentItem(items[1], items, height: 148),
                const SizedBox(height: 4),
                _buildAttachmentItem(items[2], items, height: 148),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildAttachmentItem(items[0], items, height: 150)),
            const SizedBox(width: 4),
            Expanded(child: _buildAttachmentItem(items[1], items, height: 150)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _buildAttachmentItem(items[2], items, height: 150)),
            const SizedBox(width: 4),
            Expanded(
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  _buildAttachmentItem(items[3], items, height: 150),
                  if (items.length > 4)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+${items.length - 4}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentItem(Map<String, String> item, List<Map<String, String>> allItems, {double? height}) {
    final isImage = item['type'] == 'image';
    return GestureDetector(
      onTap: () {
        if (isImage) {
          final images = allItems.where((i) => i['type'] == 'image').map((i) => i['url']!).toList();
          final index = images.indexOf(item['url']!);
          _showImageLightbox(images, index == -1 ? 0 : index);
        } else {
          context.read<TrainingProvider>().openUrl(item['url']!);
        }
      },
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: isImage
            ? Image.network(
                item['url']!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.fileText, size: 40, color: Colors.blueGrey),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      item['name'] ?? 'Document',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showImageLightbox(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Image.network(imageUrls[index], fit: BoxFit.contain),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: color,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      onPressed: onPressed,
    );
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
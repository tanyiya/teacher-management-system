import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';

import '../../../app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../modules/teachers/models/teacher.dart';
import '../../../modules/teachers/services/teacher_service.dart';
import '../models/training.dart';
import '../providers/training_provider.dart';

class AdminTrainingScreen extends StatefulWidget {
  final TeacherRecord user;
  const AdminTrainingScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminTrainingScreen> createState() => AdminTrainingScreenState();
}

class AdminTrainingScreenState extends State<AdminTrainingScreen> {
  final TeacherService _teacherService = TeacherService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxSeatsController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _expandedComments = {};
  final List<String> _selectedTraineeIds = [];
  final ScrollController _scrollController = ScrollController();
  final List<LocalAttachment> _attachments = [];
  bool _isUploadingImage = false;
  bool _isCpd = false;
  String _enrollmentMode = 'open_volunteer';

  // How many feed posts are currently visible. Starts at 2 so the
  // Pending Applications / Training Assignments sections below stay
  // reachable without endless scrolling through the feed first.
  int _feedVisibleCount = 2;
  static const int _feedPageSize = 10;

  /// Public so a parent shell (e.g. one holding a header with a
  /// notification bell / logout button) can call this via a
  /// GlobalKey<AdminTrainingScreenState> when the empty header area is
  /// tapped, to bring this screen back to the top.
  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  // ---- Shared, feed-style type scale (LinkedIn/Facebook-like, compact) ----
  static const _colorPrimaryText = Color(0xFF1A1A1A);
  static const _colorSecondaryText = Color(0xFF65676B);

  static const _panelTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: _colorPrimaryText,
    letterSpacing: -0.1,
  );
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
  static const _bodyTextStyle = TextStyle(
    fontSize: 13.5,
    height: 1.4,
    color: _colorPrimaryText,
  );
  static const _metaCountStyle = TextStyle(
    fontSize: 12.5,
    color: _colorSecondaryText,
    fontWeight: FontWeight.w500,
  );
  static const _inputTextStyle = TextStyle(fontSize: 13.5);
  static const _labelStyle = TextStyle(fontSize: 12.5, color: _colorSecondaryText);
  static const _hintStyle = TextStyle(fontSize: 13, color: _colorSecondaryText);

  @override
  void dispose() {
    _searchController.dispose();
    _contentController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _maxSeatsController.dispose();
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              _buildSearchBar(provider),
              const SizedBox(height: 12),
              _buildCreatePanel(provider),
              const SizedBox(height: 12),
              _buildFeedPanel(provider),
              const SizedBox(height: 12),
              _buildApplicationsPanel(provider),
              const SizedBox(height: 12),
              _buildAssignmentPanel(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(TrainingProvider provider) {
    return TextField(
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
    );
  }

  Widget _buildCreatePanel(TrainingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Post / CPD Session', style: _panelTitleStyle),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 3,
            style: _inputTextStyle,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Content...',
              hintStyle: _hintStyle,
              contentPadding: const EdgeInsets.all(10),
            ),
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
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                    value: _isCpd,
                    onChanged: (value) =>
                        setState(() => _isCpd = value ?? false)),
              ),
              const Expanded(
                child: Text('Training/CPD Session',
                    style: TextStyle(fontSize: 13, color: _colorPrimaryText)),
              ),
            ],
          ),
          if (_isCpd) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              style: _inputTextStyle,
              decoration: const InputDecoration(
                  labelText: 'Course Title',
                  labelStyle: _labelStyle,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              style: _inputTextStyle,
              decoration: const InputDecoration(
                  labelText: 'Training Description',
                  labelStyle: _labelStyle,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                TextField(
                  controller: _maxSeatsController,
                  keyboardType: TextInputType.number,
                  style: _inputTextStyle,
                  decoration: const InputDecoration(
                      labelText: 'Max Seats',
                      labelStyle: _labelStyle,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(_enrollmentMode),
                  initialValue: _enrollmentMode,
                  style: _inputTextStyle.copyWith(color: _colorPrimaryText),
                  items: const [
                    DropdownMenuItem(
                        value: 'open_volunteer',
                        child: Text('Open for Volunteers')),
                    DropdownMenuItem(
                        value: 'assigned', child: Text('Assign Trainees')),
                  ],
                  onChanged: (value) => setState(
                      () => _enrollmentMode = value ?? 'open_volunteer'),
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ],
            ),
            if (_enrollmentMode == 'assigned') ...[
              const SizedBox(height: 10),
              _buildTeacherChips(),
            ],
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isUploadingImage ? null : () => _createPost(provider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.send, size: 15),
              label: Text(_isUploadingImage ? 'Uploading...' : 'Post'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherChips(
      {String? postId, List<String> assignedIds = const []}) {
    return StreamBuilder<List<TeacherRecord>>(
      stream: _teacherService.getTeachers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final teachers = snapshot.data!
            .where((teacher) => teacher.role != 'principal')
            .toList();
        if (teachers.isEmpty) {
          return const Text('No teachers available.', style: _authorRoleStyle);
        }

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: teachers.map((teacher) {
            final selected = postId == null
                ? _selectedTraineeIds.contains(teacher.id)
                : assignedIds.contains(teacher.id);
            return FilterChip(
              visualDensity: VisualDensity.compact,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              label: Text(teacher.fullName, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: postId == null
                  ? (value) => setState(() {
                        value
                            ? _selectedTraineeIds.add(teacher.id)
                            : _selectedTraineeIds.remove(teacher.id);
                      })
                  : selected
                      ? null
                      : (_) => context
                          .read<TrainingProvider>()
                          .assignTraineeToTraining(
                              postId: postId, teacherId: teacher.id),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFeedPanel(TrainingProvider provider) {
    final posts = provider.teacherPosts();
    final visiblePosts = posts.take(_feedVisibleCount).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Training Feed', style: _panelTitleStyle),
          const SizedBox(height: 10),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (posts.isEmpty)
            const Text('No posts found.', style: _authorRoleStyle)
          else ...[
            ...visiblePosts.map((post) => _buildPostCard(provider, post)),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => _handleSeeMoreFeed(posts.length),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('See more'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleSeeMoreFeed(int totalPosts) {
    if (_feedVisibleCount >= totalPosts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more feed to show.')),
      );
      return;
    }
    setState(() {
      final next = _feedVisibleCount + _feedPageSize;
      _feedVisibleCount = next > totalPosts ? totalPosts : next;
    });
  }

  Widget _buildPostCard(TrainingProvider provider, TrainingPost post) {
    final isLiked = post.likes.contains(widget.user.id);
    final commentsExpanded = _expandedComments.contains(post.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.subtleGrayBoundary),
          borderRadius: BorderRadius.circular(10)),
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
          if (post.isTraining) ...[
            const SizedBox(height: 10),
            _buildTrainingSummary(post),
          ],
          const SizedBox(height: 10),
          _buildFormattedContent(post),
          if (post.photoUrl.isNotEmpty || post.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildAttachmentsGrid(post),
          ],
          Divider(height: 20, color: AppTheme.subtleGrayBoundary),
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
    );
  }

  Widget _buildTrainingSummary(TrainingPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.trainingTitle ?? 'CPD Session',
              style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700)),
          if ((post.trainingDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(post.trainingDescription!, style: _bodyTextStyle),
          ],
          const SizedBox(height: 6),
          Text(
            post.remainingSeats == null
                ? '${post.seatsTaken} enrolled'
                : '${post.remainingSeats} of ${post.maxTrainees} seats left',
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: _colorSecondaryText),
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
                        subtitle: _buildLinkedText(context, comment.text),
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

  Widget _buildApplicationsPanel(TrainingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Applications', style: _panelTitleStyle),
          const SizedBox(height: 10),
          StreamBuilder<List<TrainingApplication>>(
            stream: provider.pendingApplications,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final applications = snapshot.data ?? [];
              if (applications.isEmpty) {
                return const Text('No pending applications.', style: _authorRoleStyle);
              }

              final grouped = <String, List<TrainingApplication>>{};
              for (final application in applications) {
                grouped
                    .putIfAbsent(application.postId, () => [])
                    .add(application);
              }

              return Column(
                children: grouped.entries.map((entry) {
                  final title = entry.value.first.trainingTitle;
                  TrainingPost? post;
                  for (final item in provider.posts) {
                    if (item.id == entry.key) {
                      post = item;
                      break;
                    }
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.subtleGrayBoundary),
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(title,
                                    style: const TextStyle(
                                        fontSize: 13.5, fontWeight: FontWeight.w700))),
                            if (post != null)
                              Text('${post.remainingSeats ?? 'Open'} seats left',
                                  style: _authorRoleStyle),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...entry.value.map((application) => ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              title: Text(application.teacherName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  DateFormat('MMM dd, yyyy').format(application.createdAt),
                                  style: _dateStyle),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  _compactIconButton(
                                    tooltip: 'Approve',
                                    icon: LucideIcons.check,
                                    color: Colors.green.shade700,
                                    onPressed: () => _approve(provider, application),
                                  ),
                                  _compactIconButton(
                                    tooltip: 'Reject',
                                    icon: LucideIcons.x,
                                    color: Colors.red.shade600,
                                    onPressed: () => _reject(provider, application.id),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentPanel(TrainingProvider provider) {
    final posts = provider.adminTrainingPosts();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Training Assignments', style: _panelTitleStyle),
          const SizedBox(height: 10),
          if (posts.isEmpty)
            const Text('No training posts yet.', style: _authorRoleStyle)
          else
            ...posts.map((post) => Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    title: Text(post.trainingTitle ?? 'CPD Session',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        post.isOpenVolunteer ? 'Open for Volunteers' : 'Assigned',
                        style: _authorRoleStyle),
                    trailing: Text(
                        post.remainingSeats == null
                            ? '${post.seatsTaken} enrolled'
                            : '${post.remainingSeats} left',
                        style: _metaCountStyle),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTeacherChips(
                              postId: post.id, assignedIds: post.traineeIds),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Future<void> _createPost(TrainingProvider provider) async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _attachments.isEmpty) return;
    final maxSeats = int.tryParse(_maxSeatsController.text.trim());

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

      final trainingTitle = _titleController.text.trim();
      final trainingDescription = _descriptionController.text.trim();
      final assignedTraineeIds = List<String>.from(_selectedTraineeIds);
      final enrollmentMode = _enrollmentMode;
      final isTraining = _isCpd;

      final postId = await provider.createPost(TrainingPost(
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
        isTraining: isTraining,
        trainingTitle: isTraining ? trainingTitle : null,
        trainingDescription: isTraining ? trainingDescription : null,
        maxTrainees: isTraining ? maxSeats : null,
        type: isTraining ? enrollmentMode : null,
        enrollmentMode: isTraining ? enrollmentMode : 'open_volunteer',
        traineeIds: isTraining && enrollmentMode == 'assigned'
            ? assignedTraineeIds
            : const [],
      ));

      if (isTraining) {
        final notif = NotificationService();
        final title = 'New Training: ${trainingTitle.isNotEmpty ? trainingTitle : 'Untitled'}';
        final message = trainingDescription.isNotEmpty
            ? trainingDescription
            : 'A new training session has been posted.';
        if (enrollmentMode == 'assigned') {
          for (final teacherId in assignedTraineeIds) {
            await notif.send(
              userId: teacherId,
              title: title,
              message: message,
              type: 'training',
              relatedId: postId,
            );
          }
        } else {
          await notif.sendToAllTeachers(
            title: title,
            message: message,
            type: 'training',
            relatedId: postId,
          );
        }
      }

      _contentController.clear();
      _titleController.clear();
      _descriptionController.clear();
      _maxSeatsController.clear();
      setState(() {
        _selectedTraineeIds.clear();
        _attachments.clear();
        _isCpd = true;
        _enrollmentMode = 'open_volunteer';
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _approve(
      TrainingProvider provider, TrainingApplication application) async {
    try {
      await provider.approveApplication(application);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _reject(TrainingProvider provider, String applicationId) async {
    await provider.rejectApplication(applicationId);
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

  Widget _buildFormattedContent(TrainingPost post) {
    final style = _bodyTextStyle;
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
                                _linkSpans(context, trimmed.substring(2))))),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
              text: TextSpan(style: style, children: _linkSpans(context, line))),
        );
      }).toList(),
    );
  }

  Widget _buildLinkedText(BuildContext context, String text) {
    return RichText(
      text: TextSpan(
        style: _bodyTextStyle,
        children: _linkSpans(context, text),
      ),
    );
  }

  List<TextSpan> _linkSpans(BuildContext context, String text) {
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
        style: const TextStyle(
            color: Colors.blue, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()
          ..onTap = () => context.read<TrainingProvider>().openUrl(url),
      ));
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return spans;
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
                      Divider(height: 28, color: AppTheme.subtleGrayBoundary),
                      if (postsSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (posts.isEmpty)
                        const Center(child: Text('No posts yet.', style: _authorRoleStyle))
                      else
                        ...posts.map((post) => _buildPostCard(provider, post)),
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

  String _initial(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? '?' : text[0].toUpperCase();
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.subtleGrayBoundary),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
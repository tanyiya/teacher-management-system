import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_theme.dart';
import '../../../modules/teachers/models/teacher.dart';
import '../../../modules/teachers/services/teacher_service.dart';
import '../models/training.dart';
import '../providers/training_provider.dart';

class AdminTrainingScreen extends StatefulWidget {
  final TeacherRecord user;
  const AdminTrainingScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminTrainingScreen> createState() => _AdminTrainingScreenState();
}

class _AdminTrainingScreenState extends State<AdminTrainingScreen> {
  final TeacherService _teacherService = TeacherService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxSeatsController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};
  final Set<String> _expandedComments = {};
  final List<String> _selectedTraineeIds = [];
  XFile? _selectedImage;
  bool _isUploadingImage = false;
  bool _isCpd = true;
  String _enrollmentMode = 'open_volunteer';
  String _fontStyle = 'sans';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainingProvider>();

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchBar(provider),
            const SizedBox(height: 16),
            _buildCreatePanel(provider),
            const SizedBox(height: 16),
            _buildFeedPanel(provider),
            const SizedBox(height: 16),
            _buildApplicationsPanel(provider),
            const SizedBox(height: 16),
            _buildAssignmentPanel(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(TrainingProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search posts, training, authors...',
        prefixIcon: const Icon(LucideIcons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildCreatePanel(TrainingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Post / CPD Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), hintText: 'Content...'),
          ),
          const SizedBox(height: 12),
          _buildImagePickerRow(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                      value: _isCpd,
                      onChanged: (value) =>
                          setState(() => _isCpd = value ?? false)),
                  const Expanded(child: Text('Training/CPD Session')),
                ],
              ),
              DropdownButtonFormField<String>(
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
                      border: OutlineInputBorder(), isDense: true)),
            ],
          ),
          if (_isCpd) ...[
            const SizedBox(height: 12),
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Course Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Training Description',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Column(
              children: [
                TextField(
                  controller: _maxSeatsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Max Seats', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_enrollmentMode),
                  initialValue: _enrollmentMode,
                  items: const [
                    DropdownMenuItem(
                        value: 'open_volunteer',
                        child: Text('Open for Volunteers')),
                    DropdownMenuItem(
                        value: 'assigned', child: Text('Assign Trainees')),
                  ],
                  onChanged: (value) => setState(
                      () => _enrollmentMode = value ?? 'open_volunteer'),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
            ),
            if (_enrollmentMode == 'assigned') ...[
              const SizedBox(height: 12),
              _buildTeacherChips(),
            ],
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isUploadingImage ? null : () => _createPost(provider),
              icon: const Icon(LucideIcons.send, size: 16),
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
        if (teachers.isEmpty) return const Text('No teachers available.');

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: teachers.map((teacher) {
            final selected = postId == null
                ? _selectedTraineeIds.contains(teacher.id)
                : assignedIds.contains(teacher.id);
            return FilterChip(
              label: Text(teacher.fullName),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Training Feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (posts.isEmpty)
            const Text('No posts found.')
          else
            ...posts.map((post) => _buildPostCard(provider, post)),
        ],
      ),
    );
  }

  Widget _buildPostCard(TrainingProvider provider, TrainingPost post) {
    final isLiked = post.likes.contains(widget.user.id);
    final commentsExpanded = _expandedComments.contains(post.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.subtleGrayBoundary),
          borderRadius: BorderRadius.circular(8)),
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
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(DateFormat('MMM dd').format(post.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          if (post.isTraining) ...[
            const SizedBox(height: 12),
            _buildTrainingSummary(post),
          ],
          const SizedBox(height: 12),
          _buildLinkedText(post.content),
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
          const Divider(height: 24),
          Row(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
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
    );
  }

  Widget _buildTrainingSummary(TrainingPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.trainingTitle ?? 'CPD Session',
              style: const TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          if ((post.trainingDescription ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(post.trainingDescription!),
          ],
          const SizedBox(height: 6),
          Text(
            post.remainingSeats == null
                ? '${post.seatsTaken} enrolled'
                : '${post.remainingSeats} of ${post.maxTrainees} seats left',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                        subtitle: _buildLinkedText(comment.text),
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

  Widget _buildApplicationsPanel(TrainingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Applications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<TrainingApplication>>(
            stream: provider.pendingApplications,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final applications = snapshot.data ?? [];
              if (applications.isEmpty) {
                return const Text('No pending applications.');
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
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.subtleGrayBoundary),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            if (post != null)
                              Text(
                                  '${post.remainingSeats ?? 'Open'} seats left',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map((application) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(application.teacherName),
                              subtitle: Text(DateFormat('MMM dd, yyyy')
                                  .format(application.createdAt)),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    tooltip: 'Approve',
                                    icon: const Icon(LucideIcons.check),
                                    onPressed: () =>
                                        _approve(provider, application),
                                  ),
                                  IconButton(
                                    tooltip: 'Reject',
                                    icon: const Icon(LucideIcons.x),
                                    onPressed: () =>
                                        _reject(provider, application.id),
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
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Training Assignments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (posts.isEmpty)
            const Text('No training posts yet.')
          else
            ...posts.map((post) => ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(post.trainingTitle ?? 'CPD Session'),
                  subtitle: Text(post.isOpenVolunteer
                      ? 'Open for Volunteers'
                      : 'Assigned'),
                  trailing: Text(post.remainingSeats == null
                      ? '${post.seatsTaken} enrolled'
                      : '${post.remainingSeats} left'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTeacherChips(
                            postId: post.id, assignedIds: post.traineeIds),
                      ),
                    ),
                  ],
                )),
        ],
      ),
    );
  }

  Future<void> _createPost(TrainingProvider provider) async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;
    final maxSeats = int.tryParse(_maxSeatsController.text.trim());

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
        isTraining: _isCpd,
        trainingTitle: _isCpd ? _titleController.text.trim() : null,
        trainingDescription: _isCpd ? _descriptionController.text.trim() : null,
        maxTrainees: _isCpd ? maxSeats : null,
        type: _isCpd ? _enrollmentMode : null,
        enrollmentMode: _isCpd ? _enrollmentMode : 'open_volunteer',
        traineeIds: _isCpd && _enrollmentMode == 'assigned'
            ? List<String>.from(_selectedTraineeIds)
            : const [],
      ));

      _contentController.clear();
      _titleController.clear();
      _descriptionController.clear();
      _maxSeatsController.clear();
      setState(() {
        _selectedTraineeIds.clear();
        _selectedImage = null;
        _isCpd = true;
        _enrollmentMode = 'open_volunteer';
        _fontStyle = 'sans';
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

  Widget _buildLinkedText(String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppTheme.textColor, height: 1.35),
        children: _linkSpans(text),
      ),
    );
  }

  List<TextSpan> _linkSpans(String text) {
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
        style: const TextStyle(
            color: Colors.blue, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()..onTap = () => _openLink(url),
      ));
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return spans;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open $url')));
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
                      const Divider(height: 32),
                      if (postsSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (posts.isEmpty)
                        const Center(child: Text('No posts yet.'))
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

  String _initial(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? '?' : text[0].toUpperCase();
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.subtleGrayBoundary),
      boxShadow: AppTheme.iosBoxShadow,
    );
  }
}

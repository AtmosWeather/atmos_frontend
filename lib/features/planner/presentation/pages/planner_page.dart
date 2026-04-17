import 'package:flutter/material.dart';
import 'package:atmos_frontend/core/auth/auth_state.dart';
import 'package:atmos_frontend/features/planner/domain/planner_models.dart';
import 'package:atmos_frontend/features/planner/data/planner_repository.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final PlannerRepository _repository = PlannerRepository();

  // Board list state
  List<PlannerBoard> _boards = [];
  bool _loadingBoards = true;

  // Per-board pending task counts (non-done)
  Map<String, int> _pendingCountMap = {};

  // Board detail state
  PlannerBoard? _selectedBoard;
  List<PlannerTask> _tasks = [];
  bool _loadingTasks = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBoards();
  }

  String get _userId => AuthState().userEmail ?? 'guest';

  // ════════════════════════════════════════════
  // BOARD operations
  // ════════════════════════════════════════════

  Future<void> _fetchBoards() async {
    setState(() { _loadingBoards = true; _error = null; });
    try {
      final boards = await _repository.getBoards(_userId);
      if (mounted) setState(() { _boards = boards; _loadingBoards = false; });
      _fetchPendingCounts();
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load plans.'; _loadingBoards = false; });
    }
  }

  Future<void> _fetchPendingCounts() async {
    try {
      final allTasks = await _repository.getTasks(_userId);
      final Map<String, int> counts = {};
      for (final task in allTasks) {
        if (task.status != 'done' && task.boardId != null) {
          counts[task.boardId!] = (counts[task.boardId!] ?? 0) + 1;
        }
      }
      if (mounted) setState(() => _pendingCountMap = counts);
    } catch (_) {
      // silent fail
    }
  }

  void _showCreateBoardDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create New Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Plan Name',
                  hintText: 'e.g. For Monday, Weekend Trip',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _loadingBoards = true);
              try {
                final board = await _repository.createBoard(
                  nameCtrl.text.trim(), descCtrl.text.trim(), _userId,
                );
                if (mounted) setState(() { _boards.insert(0, board); _loadingBoards = false; });
              } catch (_) {
                if (mounted) { setState(() => _loadingBoards = false); _snack('Failed to create plan'); }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29B6F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBoard(PlannerBoard board) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Plan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Are you sure you want to delete "${board.name}" and all its tasks? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _boards.removeWhere((b) => b.id == board.id));
              try {
                await _repository.deleteBoard(board.id, _userId);
              } catch (_) {
                if (mounted) { _fetchBoards(); _snack('Failed to delete plan'); }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openBoard(PlannerBoard board) {
    setState(() {
      _selectedBoard = board;
      _loadingTasks = true;
    });
    _fetchTasks();
  }

  void _goBackToBoards() {
    setState(() {
      _selectedBoard = null;
      _tasks = [];
    });
    _fetchBoards(); // refresh task counts
  }

  // ════════════════════════════════════════════
  // TASK operations
  // ════════════════════════════════════════════

  Future<void> _fetchTasks() async {
    if (_selectedBoard == null) return;
    setState(() { _loadingTasks = true; _error = null; });
    try {
      final tasks = await _repository.getTasks(_userId, boardId: _selectedBoard!.id);
      if (mounted) setState(() { _tasks = tasks; _loadingTasks = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load tasks.'; _loadingTasks = false; });
    }
  }

  Future<void> _changeStatus(PlannerTask task, String newStatus) async {
    if (task.status == newStatus) return;
    setState(() {
      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i != -1) _tasks[i] = task.copyWith(status: newStatus);
    });
    try {
      await _repository.updateTask(task.copyWith(status: newStatus), _userId);
      _fetchPendingCounts();
    } catch (_) {
      if (mounted) { _fetchTasks(); _snack('Failed to update status'); }
    }
  }

  void _confirmDeleteTask(PlannerTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text('Are you sure you want to delete "${task.title}"? This action cannot be undone.',
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTask(task.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteTask(String taskId) async {
    setState(() => _tasks.removeWhere((t) => t.id == taskId));
    try {
      await _repository.deleteTask(taskId, _userId);
    } catch (_) {
      if (mounted) { _fetchTasks(); _snack('Failed to delete task'); }
    }
  }

  void _showTaskFormDialog(PlannerTask? existingTask) {
    final isEdit = existingTask != null;
    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    final descCtrl = TextEditingController(text: existingTask?.description ?? '');
    String condition = existingTask?.weatherConditionTarget ?? 'Any';
    DateTime? dueDate;
    if (existingTask?.dueDate != null) {
      try { dueDate = DateTime.parse(existingTask!.dueDate!); } catch (_) {}
    }
    final conditions = ['Clear', 'Clouds', 'Rain', 'Snow', 'Thunderstorm', 'Any'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Edit Task' : 'Add New Task', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: 'Task Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Weather Condition:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: conditions.contains(condition) ? condition : 'Any',
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                  items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) { if (val != null) setDialogState(() => condition = val); },
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Due Date (Optional):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => dueDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF29B6F6)),
                            const SizedBox(width: 8),
                            Text(
                              dueDate != null ? '${_monthName(dueDate!.month)} ${dueDate!.day}, ${dueDate!.year}' : 'No due date',
                              style: TextStyle(fontSize: 14, color: dueDate != null ? Colors.black87 : Colors.grey),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    if (dueDate != null)
                      IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.grey), onPressed: () => setDialogState(() => dueDate = null)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);

                final dueDateStr = dueDate?.toIso8601String().split('T').first;
                final weatherTarget = condition == 'Any' ? null : condition;

                if (isEdit) {
                  final updated = existingTask.copyWith(
                    title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                    weatherConditionTarget: weatherTarget, dueDate: dueDateStr, clearDueDate: dueDate == null,
                  );
                  setState(() { final i = _tasks.indexWhere((t) => t.id == updated.id); if (i != -1) _tasks[i] = updated; });
                  try { await _repository.updateTask(updated, _userId); } catch (_) { if (mounted) { _fetchTasks(); _snack('Failed to update'); } }
                } else {
                  final newTask = PlannerTask(
                    id: '', title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                    status: 'todo', weatherConditionTarget: weatherTarget, dueDate: dueDateStr,
                    boardId: _selectedBoard!.id,
                  );
                  setState(() => _loadingTasks = true);
                  try {
                    final created = await _repository.createTask(newTask, _userId);
                    if (mounted) setState(() { _tasks.insert(0, created); _loadingTasks = false; });
                  } catch (_) { if (mounted) { setState(() => _loadingTasks = false); _snack('Failed to create task'); } }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(isEdit ? 'Save' : 'Add Task', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  IconData _weatherIcon(String? c) {
    if (c == null) return Icons.wb_cloudy_outlined;
    switch (c.toLowerCase()) {
      case 'thunderstorm': return Icons.thunderstorm;
      case 'rain': return Icons.water_drop;
      case 'snow': return Icons.ac_unit;
      case 'clear': return Icons.wb_sunny;
      case 'clouds': return Icons.cloud;
      default: return Icons.wb_cloudy;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'todo': return const Color(0xFF1E88E5);
      case 'in_progress': return const Color(0xFFFB8C00);
      case 'done': return const Color(0xFF43A047);
      default: return Colors.grey;
    }
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDetail = _selectedBoard != null;
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, _) {
        final isDark = AuthState().theme == 'Dark Mode';
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white70 : Colors.black87, size: 20),
              onPressed: isDetail ? _goBackToBoards : () => Navigator.pop(context),
            ),
            title: Text(
              isDetail ? _selectedBoard!.name : 'Atmos Planner',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
          body: isDetail ? _buildBoardDetail(isDark) : _buildBoardList(isDark),
          floatingActionButton: FloatingActionButton(
            onPressed: isDetail ? () => _showTaskFormDialog(null) : _showCreateBoardDialog,
            backgroundColor: const Color(0xFF29B6F6),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════
  // BOARD LIST VIEW (first view)
  // ════════════════════════════════════════════

  Widget _buildBoardList(bool isDark) {
    if (_loadingBoards) return const Center(child: CircularProgressIndicator(color: Color(0xFF29B6F6)));
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: Colors.red)),
        TextButton(onPressed: _fetchBoards, child: const Text('Retry')),
      ]));
    }

    if (_boards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No plans yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            Text('Tap + to create your first plan', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _boards.length,
      itemBuilder: (context, index) {
        final board = _boards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _openBoard(board),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2744) : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_outlined, color: Color(0xFF1E88E5), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(board.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                        if (board.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(board.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 4),
                        Text('${board.taskCount} task${board.taskCount == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  if ((_pendingCountMap[board.id] ?? 0) > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                      child: Text('${_pendingCountMap[board.id]}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: isDark ? Colors.white54 : Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) { if (val == 'delete') _confirmDeleteBoard(board); },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'delete', child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red.shade400)),
                      ])),
                    ],
                  ),
                  Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════
  // BOARD DETAIL VIEW (tasks inside a plan)
  // ════════════════════════════════════════════

  Widget _buildBoardDetail(bool isDark) {
    if (_loadingTasks) return const Center(child: CircularProgressIndicator(color: Color(0xFF29B6F6)));
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: Colors.red)),
        TextButton(onPressed: _fetchTasks, child: const Text('Retry')),
      ]));
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No tasks yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            Text('Tap + to add your first task', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('To Do', 'todo', isDark ? const Color(0xFF1A2744) : const Color(0xFFE3F2FD), const Color(0xFF1E88E5), isDark),
          const SizedBox(height: 20),
          _buildSection('In Progress', 'in_progress', isDark ? const Color(0xFF2A1A00) : const Color(0xFFFFF3E0), const Color(0xFFFB8C00), isDark),
          const SizedBox(height: 20),
          _buildSection('Done', 'done', isDark ? const Color(0xFF0A2010) : const Color(0xFFE8F5E9), const Color(0xFF43A047), isDark),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String status, Color bgColor, Color accentColor, bool isDark) {
    final sectionTasks = _tasks.where((t) => t.status == status).toList();

    return DragTarget<PlannerTask>(
      onAcceptWithDetails: (details) => _changeStatus(details.data, status),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isHovering ? bgColor.withValues(alpha: 0.6) : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F2F5)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isHovering ? accentColor.withValues(alpha: 0.5) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200), width: isHovering ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(children: [
                  Container(width: 4, height: 20, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('${sectionTasks.length}', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor, fontSize: 13)),
                  ),
                ]),
              ),
              // Cards
              if (sectionTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(isHovering ? 'Drop here' : 'No tasks', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
                )
              else
                ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12), itemCount: sectionTasks.length,
                  itemBuilder: (context, index) {
                    final task = sectionTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LongPressDraggable<PlannerTask>(
                        data: task,
                        feedback: Material(color: Colors.transparent, child: SizedBox(
                          width: MediaQuery.of(context).size.width - 64,
                          child: Opacity(opacity: 0.85, child: _buildTaskCard(task, isDark)),
                        )),
                        childWhenDragging: Opacity(opacity: 0.25, child: _buildTaskCard(task, isDark)),
                        child: _buildTaskCard(task, isDark),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(PlannerTask task, bool isDark) {
    final isOverdue = task.isOverdue;
    return GestureDetector(
      onTap: () => _showTaskFormDialog(task),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isOverdue ? Border.all(color: Colors.red.shade200, width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title + menu
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 4, right: 10), width: 8, height: 8,
                decoration: BoxDecoration(color: _statusColor(task.status), shape: BoxShape.circle)),
              Expanded(child: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
                decoration: task.status == 'done' ? TextDecoration.lineThrough : null))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'delete') _confirmDeleteTask(task);
                  else if (v == 'edit') _showTaskFormDialog(task);
                  else _changeStatus(task, v);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Colors.black54), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuDivider(),
                  if (task.status != 'todo') const PopupMenuItem(value: 'todo', child: Row(children: [Icon(Icons.radio_button_unchecked, size: 18, color: Color(0xFF1E88E5)), SizedBox(width: 8), Text('Move to To Do')])),
                  if (task.status != 'in_progress') const PopupMenuItem(value: 'in_progress', child: Row(children: [Icon(Icons.timelapse, size: 18, color: Color(0xFFFB8C00)), SizedBox(width: 8), Text('Move to In Progress')])),
                  if (task.status != 'done') const PopupMenuItem(value: 'done', child: Row(children: [Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF43A047)), SizedBox(width: 8), Text('Move to Done')])),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), const SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red.shade400))])),
                ],
              ),
            ]),
            if (task.description.isNotEmpty) ...[const SizedBox(height: 8), Text(task.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis)],
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (task.weatherConditionTarget != null)
                _chip(icon: _weatherIcon(task.weatherConditionTarget), label: task.weatherConditionTarget!, color: const Color(0xFF29B6F6)),
              if (task.dueDateFormatted != null)
                _chip(icon: Icons.event, label: task.dueDateFormatted!, color: isOverdue ? Colors.red : Colors.grey.shade600),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

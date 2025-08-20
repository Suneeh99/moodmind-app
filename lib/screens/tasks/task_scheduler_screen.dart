import 'package:flutter/material.dart';
import 'package:moodmind_new/services/notification_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:moodmind_new/models/task_model.dart';
import 'package:moodmind_new/services/task_service.dart';
import 'package:moodmind_new/services/alarm_service.dart';
import 'package:moodmind_new/widgets/add_task_dialog.dart';
import 'package:moodmind_new/widgets/task_card.dart';
import 'package:moodmind_new/widgets/task_verification_dialog.dart';
import 'package:moodmind_new/utils/app_theme.dart';

class TaskSchedulerScreen extends StatefulWidget {
  const TaskSchedulerScreen({Key? key}) : super(key: key);

  @override
  State<TaskSchedulerScreen> createState() => _TaskSchedulerScreenState();
}

class _TaskSchedulerScreenState extends State<TaskSchedulerScreen>
    with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final AlarmService _alarmService = AlarmService();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupAlarmListener();
  }

  void _setupAlarmListener() {
    _alarmService.alarmStream.listen((task) {
      _showVerificationDialog(task);
    });
  }

  void _showVerificationDialog(Task task) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaskVerificationDialog(
        task: task,
        onVerificationComplete: (verified, points) {
          // Handle verification completion
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verified 
                  ? 'Task verified! +$points MM points' 
                  : 'Verification failed. Try again.'),
              backgroundColor: verified ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Task Scheduler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => Navigator.pushNamed(context, '/points'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            color: Colors.white,
            child: TableCalendar<Task>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getTasksForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red),
                holidayTextStyle: TextStyle(color: Colors.red),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDate = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDate = focusedDay;
              },
            ),
          ),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTasks(),
                _buildPendingTasks(),
                _buildCompletedTasks(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Task> _getTasksForDay(DateTime day) {
    // This would be implemented to return tasks for the specific day
    return [];
  }

  Widget _buildTodayTasks() {
    return StreamBuilder<List<Task>>(
      stream: _taskService.getTasksForDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No tasks for this day');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final task = snapshot.data![index];
            return TaskCard(
              task: task,
              onTap: () => _handleTaskTap(task),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingTasks() {
    return StreamBuilder<List<Task>>(
      stream: _taskService.getTasksByStatus(TaskStatus.pending),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No pending tasks');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final task = snapshot.data![index];
            return TaskCard(
              task: task,
              onTap: () => _handleTaskTap(task),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedTasks() {
    return StreamBuilder<List<Task>>(
      stream: _taskService.getTasksByStatus(TaskStatus.completed),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No completed tasks');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final task = snapshot.data![index];
            return TaskCard(
              task: task,
              onTap: () => _handleTaskTap(task),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTaskTap(Task task) {
    if (task.requiresVerification && !task.isCompleted) {
      _showVerificationDialog(task);
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        selectedDate: _selectedDate,
        onTaskAdded: (task) async {
          await _taskService.addTask(task);
          await NotificationService().scheduleTaskNotification(task);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

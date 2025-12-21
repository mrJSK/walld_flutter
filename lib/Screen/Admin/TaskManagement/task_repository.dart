import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

class TaskRepository {
  final FirebaseFirestore _db;

  TaskRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<TaskMeta>> loadAllTasks(String tenantId) async {
    final snap = await _db
        .collection('tenants/$tenantId/tasks')
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();

    return snap.docs.map((d) => TaskMeta.fromMap(d.id, d.data())).toList();
  }

  Future<List<TaskMeta>> loadTasksByStatus(String tenantId, String status) async {
    final snap = await _db
        .collection('tenants/$tenantId/tasks')
        .where('status', isEqualTo: status)
        .orderBy('updatedAt', descending: true)
        .get();

    return snap.docs.map((d) => TaskMeta.fromMap(d.id, d.data())).toList();
  }

  Future<void> updateTaskStatus(String tenantId, String taskId, String newStatus) async {
    await _db.collection('tenants/$tenantId/tasks').doc(taskId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String tenantId, String taskId) async {
    await _db.collection('tenants/$tenantId/tasks').doc(taskId).delete();
  }
}

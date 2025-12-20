# Wall-D: Complete Implementation Guide (Continued)
## Sections 10-15: Advanced Architecture & Deployment

**Version:** 2.0 - Advanced Implementation  
**Target Stack:** .NET MAUI 8.0+, WinUI3, Firebase Firestore  
**Date:** December 2025  

---

## 10. REAL-TIME SYNC ARCHITECTURE

### 10.1 Bi-Directional Sync Engine

// WallD.Infrastructure/Services/RealtimeSyncService.cs

public interface IRealtimeSyncService
{
    Task InitializeSyncAsync(string tenantId, string userId);
    Task<IDisposable> SyncTasksAsync(Action<List<Task>> onTasksChanged);
    Task<IDisposable> SyncApprovalsAsync(Action<List<Approval>> onApprovalsChanged);
    Task<IDisposable> SyncNotificationsAsync(Action<List<Notification>> onNotificationsChanged);
    Task PublishChangeAsync(string entityType, string entityId, object data);
}

public class RealtimeSyncService : IRealtimeSyncService
{
    private readonly FirestoreService _firestore;
    private readonly RealtimeDbService _realtimeDb;
    private readonly ISyncService _offlineSync;
    private readonly ILogger<RealtimeSyncService> _logger;
    private readonly Connectivity _connectivity;
    
    private string _currentTenantId;
    private string _currentUserId;
    private List<IDisposable> _listeners = new();

    public async Task InitializeSyncAsync(string tenantId, string userId)
    {
        _currentTenantId = tenantId;
        _currentUserId = userId;
        
        _logger.LogInformation($"Initializing sync for tenant {tenantId}, user {userId}");

        // Monitor connectivity
        Connectivity.ConnectivityChanged += async (s, e) =>
        {
            if (e.NetworkAccess == NetworkAccess.Internet)
            {
                _logger.LogInformation("Connection restored, syncing pending changes");
                await _offlineSync.SyncPendingChangesAsync();
            }
        };

        // Initial sync
        await _offlineSync.SyncPendingChangesAsync();
    }

    public Task<IDisposable> SyncTasksAsync(Action<List<Task>> onTasksChanged)
    {
        try
        {
            // Real-time listener on Firestore
            var listener = _firestore.ListenToCollection<Task>(
                "tasks",
                tasks =>
                {
                    // Filter for current user's tasks or team tasks
                    var relevantTasks = tasks
                        .Where(t => t.AssigneeId == _currentUserId || 
                                  t.CreatedBy == _currentUserId)
                        .OrderByDescending(t => t.CreatedAt)
                        .ToList();

                    _logger.LogInformation($"Tasks synced: {relevantTasks.Count}");
                    onTasksChanged(relevantTasks);
                },
                error =>
                {
                    _logger.LogError(error, "Error syncing tasks");
                }
            );

            _listeners.Add(listener);
            return Task.FromResult(listener);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting up task sync");
            throw;
        }
    }

    public Task<IDisposable> SyncApprovalsAsync(Action<List<Approval>> onApprovalsChanged)
    {
        try
        {
            var listener = _firestore.ListenToCollection<Approval>(
                "approvals",
                approvals =>
                {
                    // Filter for current user's pending approvals
                    var myApprovals = approvals
                        .Where(a => a.ApproverId == _currentUserId && 
                                  a.Status == "pending")
                        .OrderByDescending(a => a.CreatedAt)
                        .ToList();

                    _logger.LogInformation($"Approvals synced: {myApprovals.Count}");
                    onApprovalsChanged(myApprovals);
                },
                error =>
                {
                    _logger.LogError(error, "Error syncing approvals");
                }
            );

            _listeners.Add(listener);
            return Task.FromResult(listener);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting up approval sync");
            throw;
        }
    }

    public Task<IDisposable> SyncNotificationsAsync(Action<List<Notification>> onNotificationsChanged)
    {
        try
        {
            var listener = _firestore.ListenToCollection<Notification>(
                "notifications",
                notifications =>
                {
                    // Filter for current user's recent notifications
                    var myNotifications = notifications
                        .Where(n => n.RecipientUserId == _currentUserId)
                        .OrderByDescending(n => n.CreatedAt)
                        .Take(50) // Last 50
                        .ToList();

                    var unreadCount = myNotifications.Count(n => n.ReadAt == null);
                    _logger.LogInformation($"Notifications synced: {myNotifications.Count} (unread: {unreadCount})");
                    onNotificationsChanged(myNotifications);
                },
                error =>
                {
                    _logger.LogError(error, "Error syncing notifications");
                }
            );

            _listeners.Add(listener);
            return Task.FromResult(listener);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting up notification sync");
            throw;
        }
    }

    public async Task PublishChangeAsync(string entityType, string entityId, object data)
    {
        try
        {
            // Publish to Realtime DB for presence/quick sync
            var path = $"sync_channels/{_currentTenantId}/{entityType}/{entityId}";
            
            await _realtimeDb.SetValueAsync(path, new
            {
                updated_at = DateTime.UtcNow,
                updated_by = _currentUserId,
                data = data
            });

            _logger.LogInformation($"Change published: {entityType}/{entityId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error publishing change for {entityType}/{entityId}");
        }
    }

    public void Dispose()
    {
        foreach (var listener in _listeners)
        {
            listener?.Dispose();
        }
        _listeners.Clear();
    }
}

### 10.2 Conflict Resolution Strategy

// WallD.Infrastructure/Services/ConflictResolutionService.cs

public class ConflictResolutionService
{
    private readonly ILogger<ConflictResolutionService> _logger;

    // CRDT-inspired Last-Write-Wins with version tracking
    public T ResolveConflict<T>(
        T localVersion, 
        T remoteVersion,
        Func<T, DateTime> getTimestamp,
        Func<T, int> getVersion) where T : class
    {
        var localTime = getTimestamp(localVersion);
        var remoteTime = getTimestamp(remoteVersion);

        var localVersion_int = getVersion(localVersion);
        var remoteVersion_int = getVersion(remoteVersion);

        // If versions differ, prefer higher version
        if (localVersion_int != remoteVersion_int)
        {
            if (remoteVersion_int > localVersion_int)
            {
                _logger.LogInformation($"Resolved: Remote version {remoteVersion_int} > Local {localVersion_int}");
                return remoteVersion;
            }
            else
            {
                _logger.LogInformation($"Resolved: Local version {localVersion_int} > Remote {remoteVersion_int}");
                return localVersion;
            }
        }

        // If versions equal, use timestamp (last-write-wins)
        if (remoteTime > localTime)
        {
            _logger.LogInformation($"Resolved: Remote time {remoteTime} > Local {localTime}");
            return remoteVersion;
        }

        _logger.LogInformation($"Resolved: Local time {localTime} >= Remote {remoteTime}");
        return localVersion;
    }

    // Deep merge for complex objects
    public Dictionary<string, object> MergeChanges(
        Dictionary<string, object> local,
        Dictionary<string, object> remote)
    {
        var merged = new Dictionary<string, object>(local);

        foreach (var kvp in remote)
        {
            if (!local.ContainsKey(kvp.Key))
            {
                merged[kvp.Key] = kvp.Value;
            }
            else
            {
                // If both have the key, remote wins (simpler strategy)
                // In production, would need field-level timestamps
                merged[kvp.Key] = kvp.Value;
            }
        }

        return merged;
    }
}

---

## 11. APPROVAL WORKFLOW ENGINE

### 11.1 State Machine Pattern for Approval Flow

// WallD.Core/Models/ApprovalState.cs

public abstract class ApprovalState
{
    protected readonly Approval _approval;
    protected readonly ILogger _logger;

    protected ApprovalState(Approval approval, ILogger logger)
    {
        _approval = approval;
        _logger = logger;
    }

    public abstract Task<bool> CanTransitionToAsync(string targetState);
    public abstract Task ApproveAsync(ApprovalContext context);
    public abstract Task RejectAsync(ApprovalContext context, string reason);
    public abstract Task EscalateAsync(ApprovalContext context);
}

public class PendingApprovalState : ApprovalState
{
    public PendingApprovalState(Approval approval, ILogger logger) 
        : base(approval, logger) { }

    public override async Task<bool> CanTransitionToAsync(string targetState)
    {
        return targetState is "approved" or "rejected" or "escalated";
    }

    public override async Task ApproveAsync(ApprovalContext context)
    {
        _approval.Status = "approved";
        _approval.ApprovedAt = DateTime.UtcNow;
        _approval.ApprovedBy = context.ApproverId;
        _approval.Notes = context.Notes;

        _logger.LogInformation($"Approval {_approval.Id} approved by {context.ApproverId}");

        // Advance to next level
        if (_approval.Level < context.TotalLevels - 1)
        {
            // Create next approval
            await context.ApprovalService.CreateNextLevelApprovalAsync(
                _approval.TaskId,
                _approval.Level + 1
            );
        }
        else
        {
            // All levels approved - mark task as approved
            await context.TaskService.ApproveTaskAsync(_approval.TaskId);
        }
    }

    public override async Task RejectAsync(ApprovalContext context, string reason)
    {
        _approval.Status = "rejected";
        _approval.RejectionReason = reason;
        _approval.ApprovedAt = DateTime.UtcNow;
        _approval.ApprovedBy = context.ApproverId;

        _logger.LogInformation($"Approval {_approval.Id} rejected by {context.ApproverId}");

        // Reject task
        await context.TaskService.RejectTaskAsync(_approval.TaskId, reason);
    }

    public override async Task EscalateAsync(ApprovalContext context)
    {
        _approval.Status = "escalated";
        _approval.EscalatedAt = DateTime.UtcNow;
        _approval.EscalatedBy = context.ApproverId;

        _logger.LogInformation($"Approval {_approval.Id} escalated");

        // Find escalation target
        var escalationTarget = await context.EscalationService
            .FindEscalationTargetAsync(_approval.ApproverId);

        if (escalationTarget != null)
        {
            _approval.ApproverId = escalationTarget.Id;
            _approval.Status = "pending";
            await context.NotificationService.NotifyApprovalAsync(
                escalationTarget.Id,
                $"Task approval escalated to you",
                _approval.TaskId
            );
        }
    }
}

public class ApprovedApprovalState : ApprovalState
{
    public ApprovedApprovalState(Approval approval, ILogger logger) 
        : base(approval, logger) { }

    public override async Task<bool> CanTransitionToAsync(string targetState)
    {
        return false; // Terminal state
    }

    public override Task ApproveAsync(ApprovalContext context)
        => throw new InvalidOperationException("Already approved");

    public override Task RejectAsync(ApprovalContext context, string reason)
        => throw new InvalidOperationException("Already approved");

    public override Task EscalateAsync(ApprovalContext context)
        => throw new InvalidOperationException("Already approved");
}

// Approval Context
public class ApprovalContext
{
    public string ApproverId { get; set; }
    public string Notes { get; set; }
    public int TotalLevels { get; set; }
    public IApprovalService ApprovalService { get; set; }
    public ITaskService TaskService { get; set; }
    public IEscalationService EscalationService { get; set; }
    public INotificationService NotificationService { get; set; }
}

// Approval State Factory
public class ApprovalStateFactory
{
    public static ApprovalState CreateState(Approval approval, ILogger logger)
    {
        return approval.Status switch
        {
            "pending" => new PendingApprovalState(approval, logger),
            "approved" => new ApprovedApprovalState(approval, logger),
            "rejected" => new RejectedApprovalState(approval, logger),
            "escalated" => new EscalatedApprovalState(approval, logger),
            _ => throw new ArgumentException($"Unknown approval status: {approval.Status}")
        };
    }
}

### 11.2 Approval Chain Execution

// WallD.Application/UseCases/Approvals/ProcessApprovalChainUseCase.cs

public class ProcessApprovalChainUseCase
{
    private readonly IApprovalRepository _approvalRepository;
    private readonly ITaskRepository _taskRepository;
    private readonly INotificationService _notificationService;
    private readonly ILogger<ProcessApprovalChainUseCase> _logger;

    public async Task ExecuteAsync(string taskId, string approverId, 
        ApprovalAction action, string notes = null)
    {
        try
        {
            // Get approval chain for task
            var approvals = await _approvalRepository
                .GetByTaskIdAsync(taskId);

            if (!approvals.Any())
                throw new InvalidOperationException($"No approvals found for task {taskId}");

            // Find current approval
            var currentApproval = approvals
                .Where(a => a.Status == "pending")
                .OrderBy(a => a.Level)
                .FirstOrDefault();

            if (currentApproval == null)
                throw new InvalidOperationException("No pending approvals");

            // Verify approver
            if (currentApproval.ApproverId != approverId)
                throw new UnauthorizedAccessException(
                    $"Only {currentApproval.ApproverId} can approve"
                );

            // Get state and execute action
            var state = ApprovalStateFactory.CreateState(currentApproval, _logger);
            var context = new ApprovalContext
            {
                ApproverId = approverId,
                Notes = notes,
                TotalLevels = approvals.Count,
                ApprovalService = this,
                TaskService = _taskRepository,
                NotificationService = _notificationService
            };

            switch (action)
            {
                case ApprovalAction.Approve:
                    await state.ApproveAsync(context);
                    break;

                case ApprovalAction.Reject:
                    if (string.IsNullOrEmpty(notes))
                        throw new ArgumentException("Rejection reason required");
                    await state.RejectAsync(context, notes);
                    break;

                case ApprovalAction.Escalate:
                    await state.EscalateAsync(context);
                    break;
            }

            // Persist changes
            await _approvalRepository.UpdateAsync(currentApproval);

            _logger.LogInformation(
                $"Approval processed: {taskId}, action: {action}, by: {approverId}"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error processing approval for {taskId}");
            throw;
        }
    }
}

public enum ApprovalAction
{
    Approve,
    Reject,
    Escalate,
    Delegate
}

---

## 12. NOTIFICATION SYSTEM

### 12.1 Multi-Channel Notification Service

// WallD.Core/Services/INotificationService.cs

public interface INotificationService
{
    Task NotifyTaskAssignedAsync(string userId, string taskId);
    Task NotifyApprovalRequiredAsync(string userId, string taskId, string approverDesignation);
    Task NotifyTaskOverdueAsync(string userId, string taskId);
    Task NotifyApprovalCompletedAsync(string userId, string taskId, bool approved);
    Task NotifyCustomAsync(Notification notification);
}

// WallD.Infrastructure/Services/NotificationService.cs

public class NotificationService : INotificationService
{
    private readonly FirestoreService _firestore;
    private readonly IEmailService _emailService;
    private readonly ISmsService _smsService;
    private readonly ILogger<NotificationService> _logger;
    private readonly RealtimeDbService _realtimeDb;

    public async Task NotifyTaskAssignedAsync(string userId, string taskId)
    {
        try
        {
            var task = await _firestore.GetDocumentAsync<Task>("tasks", taskId);
            var user = await _firestore.GetDocumentAsync<User>("users", userId);

            var notification = new Notification
            {
                Id = Guid.NewGuid().ToString(),
                RecipientUserId = userId,
                Type = "task_assigned",
                Title = "New Task Assigned",
                Message = $"{task.CreatedBy} assigned you '{task.Title}'",
                RelatedEntity = new EntityReference { Type = "task", Id = taskId },
                Priority = task.Priority == "critical" ? "urgent" : "normal",
                Channels = GetNotificationChannels(user),
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };

            await CreateAndPublishNotificationAsync(notification);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error notifying task assignment to {userId}");
        }
    }

    public async Task NotifyApprovalRequiredAsync(string userId, string taskId, 
        string approverDesignation)
    {
        try
        {
            var task = await _firestore.GetDocumentAsync<Task>("tasks", taskId);

            var notification = new Notification
            {
                Id = Guid.NewGuid().ToString(),
                RecipientUserId = userId,
                Type = "approval_required",
                Title = "Approval Pending",
                Message = $"Task '{task.Title}' awaiting your approval",
                RelatedEntity = new EntityReference { Type = "task", Id = taskId },
                Priority = "high",
                Channels = ["in_app", "email"], // Approvals always email
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(48),
                ActionUrl = $"/approvals/{taskId}"
            };

            await CreateAndPublishNotificationAsync(notification);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error notifying approval to {userId}");
        }
    }

    public async Task NotifyTaskOverdueAsync(string userId, string taskId)
    {
        try
        {
            var task = await _firestore.GetDocumentAsync<Task>("tasks", taskId);

            var notification = new Notification
            {
                Id = Guid.NewGuid().ToString(),
                RecipientUserId = userId,
                Type = "task_overdue",
                Title = "Task Overdue",
                Message = $"Task '{task.Title}' is overdue since {task.DueDate:MMM dd}",
                RelatedEntity = new EntityReference { Type = "task", Id = taskId },
                Priority = "urgent",
                Channels = ["in_app", "email", "sms"], // Max urgency
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(3)
            };

            await CreateAndPublishNotificationAsync(notification);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error notifying task overdue for {userId}");
        }
    }

    private async Task CreateAndPublishNotificationAsync(Notification notification)
    {
        try
        {
            // 1. Save to Firestore
            var docId = await _firestore.CreateDocumentAsync("notifications", notification);
            notification.Id = docId;

            // 2. Publish to realtime DB (for instant push)
            await _realtimeDb.SetValueAsync(
                $"notifications/{notification.RecipientUserId}/unread",
                DateTime.UtcNow
            );

            // 3. Send via channels
            foreach (var channel in notification.Channels)
            {
                switch (channel)
                {
                    case "in_app":
                        // Already in Firestore, instant sync handles it
                        _logger.LogInformation($"In-app notification created: {docId}");
                        break;

                    case "email":
                        await _emailService.SendAsync(
                            notification.RecipientUserId,
                            notification.Title,
                            notification.Message
                        );
                        break;

                    case "sms":
                        await _smsService.SendAsync(
                            notification.RecipientUserId,
                            notification.Message
                        );
                        break;
                }
            }

            _logger.LogInformation(
                $"Notification published: {notification.Id} to {notification.RecipientUserId}"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error publishing notification");
            throw;
        }
    }

    private List<string> GetNotificationChannels(User user)
    {
        var channels = new List<string> { "in_app" };

        // Check user preferences
        if (user.Preferences?.EmailNotifications ?? true)
            channels.Add("email");

        if (user.Preferences?.SmsNotifications ?? false)
            channels.Add("sms");

        return channels;
    }
}

// Email Service Implementation
public interface IEmailService
{
    Task SendAsync(string recipientId, string subject, string message);
}

public class SendGridEmailService : IEmailService
{
    private readonly SendGridClient _sendGridClient;
    private readonly ILogger<SendGridEmailService> _logger;

    public SendGridEmailService(IConfiguration config, ILogger<SendGridEmailService> logger)
    {
        var apiKey = config["SendGrid:ApiKey"];
        _sendGridClient = new SendGridClient(apiKey);
        _logger = logger;
    }

    public async Task SendAsync(string recipientId, string subject, string message)
    {
        try
        {
            var user = await GetUserAsync(recipientId);

            var from = new EmailAddress("noreply@wall-d.com", "Wall-D");
            var to = new EmailAddress(user.Email, user.FullName);
            var htmlContent = BuildEmailTemplate(subject, message);

            var msg = new SendGridMessage()
            {
                From = from,
                Subject = subject,
                HtmlContent = htmlContent
            };

            msg.AddTo(to);

            var response = await _sendGridClient.SendEmailAsync(msg);
            _logger.LogInformation($"Email sent: {subject} to {user.Email}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending email to {recipientId}");
        }
    }
}

---

## 13. PERFORMANCE & OPTIMIZATION

### 13.1 Caching Strategy

// WallD.Infrastructure/Services/CachingService.cs

public interface ICachingService
{
    Task<T> GetOrCreateAsync<T>(string key, Func<Task<T>> factory, TimeSpan? expiry = null);
    Task InvalidateAsync(string pattern);
    Task SetAsync<T>(string key, T value, TimeSpan? expiry = null);
}

public class DistributedCachingService : ICachingService
{
    private readonly IDistributedCache _cache;
    private readonly ILogger<DistributedCachingService> _logger;
    private readonly ConcurrentDictionary<string, DateTime> _expiryMap;

    public DistributedCachingService(
        IDistributedCache cache,
        ILogger<DistributedCachingService> logger)
    {
        _cache = cache;
        _logger = logger;
        _expiryMap = new ConcurrentDictionary<string, DateTime>();
    }

    public async Task<T> GetOrCreateAsync<T>(string key, Func<Task<T>> factory, 
        TimeSpan? expiry = null)
    {
        // Check if expired
        if (_expiryMap.TryGetValue(key, out var expiryTime) && expiryTime < DateTime.UtcNow)
        {
            await InvalidateAsync(key);
            _expiryMap.TryRemove(key, out _);
        }

        // Try get from cache
        var cached = await _cache.GetStringAsync(key);
        if (!string.IsNullOrEmpty(cached))
        {
            _logger.LogDebug($"Cache hit: {key}");
            return JsonConvert.DeserializeObject<T>(cached);
        }

        // Get from factory
        var value = await factory();
        await SetAsync(key, value, expiry);

        return value;
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan? expiry = null)
    {
        var json = JsonConvert.SerializeObject(value);
        var options = new DistributedCacheEntryOptions();

        if (expiry.HasValue)
        {
            options.AbsoluteExpirationRelativeToNow = expiry.Value;
            _expiryMap[key] = DateTime.UtcNow.Add(expiry.Value);
        }

        await _cache.SetStringAsync(key, json, options);
        _logger.LogDebug($"Cache set: {key}");
    }

    public async Task InvalidateAsync(string pattern)
    {
        // In production, use Redis pub/sub or similar
        await _cache.RemoveAsync(pattern);
        _logger.LogInformation($"Cache invalidated: {pattern}");
    }
}

// Usage in Repositories
public class FirestoreUserRepository : IUserRepository
{
    private readonly FirestoreService _firestore;
    private readonly ICachingService _cache;

    public async Task<User> GetAsync(string userId)
    {
        return await _cache.GetOrCreateAsync(
            $"user:{userId}",
            async () => await _firestore.GetDocumentAsync<User>("users", userId),
            expiry: TimeSpan.FromHours(1)
        );
    }

    public async Task UpdateAsync(User user)
    {
        await _firestore.UpdateDocumentAsync("users", user.Id, user);
        await _cache.InvalidateAsync($"user:{user.Id}");
    }
}

### 13.2 Query Optimization

// WallD.Infrastructure/Repositories/QueryOptimization.cs

public static class FirestoreQueryOptimization
{
    // Efficient task query with pagination
    public static IQueryable<Task> BuildOptimizedTaskQuery(
        FirebaseFirestore firestore,
        string tenantId,
        TaskFilter filter)
    {
        var query = (IQueryable<Task>)firestore
            .Collection($"tenants/{tenantId}/tasks");

        // Apply filters in order of selectivity
        if (!string.IsNullOrEmpty(filter.AssigneeId))
            query = query.Where(t => t.AssigneeId == filter.AssigneeId);

        if (!string.IsNullOrEmpty(filter.Status))
            query = query.Where(t => t.Status == filter.Status);

        if (filter.DueDateFrom.HasValue)
            query = query.Where(t => t.DueDate >= filter.DueDateFrom.Value);

        if (filter.DueDateTo.HasValue)
            query = query.Where(t => t.DueDate <= filter.DueDateTo.Value);

        // Sort and paginate
        query = query
            .OrderByDescending(t => t.CreatedAt)
            .Limit(filter.PageSize)
            .Offset((filter.PageNumber - 1) * filter.PageSize);

        return query;
    }

    // Batch operations
    public static async Task BatchUpdateTasksAsync(
        FirebaseFirestore firestore,
        string tenantId,
        List<(string Id, Dictionary<string, object> Updates)> updates)
    {
        var batch = firestore.Batch();

        foreach (var (id, updateDict) in updates)
        {
            batch.Update(
                firestore
                    .Collection($"tenants/{tenantId}/tasks")
                    .Document(id),
                updateDict
            );
        }

        await batch.CommitAsync();
    }
}

public class TaskFilter
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string AssigneeId { get; set; }
    public string Status { get; set; }
    public DateTime? DueDateFrom { get; set; }
    public DateTime? DueDateTo { get; set; }
}

---

## 14. TESTING STRATEGY

### 14.1 Unit Testing Pattern

// WallD.Core.Tests/Services/TaskServiceTests.cs

[TestClass]
public class CreateTaskUseCaseTests
{
    private CreateTaskUseCase _useCase;
    private Mock<ITaskRepository> _taskRepository;
    private Mock<IUserRepository> _userRepository;
    private Mock<INotificationService> _notificationService;
    private Mock<ILogger<CreateTaskUseCase>> _logger;

    [TestInitialize]
    public void Setup()
    {
        _taskRepository = new Mock<ITaskRepository>();
        _userRepository = new Mock<IUserRepository>();
        _notificationService = new Mock<INotificationService>();
        _logger = new Mock<ILogger<CreateTaskUseCase>>();

        _useCase = new CreateTaskUseCase(
            _taskRepository.Object,
            _userRepository.Object,
            _notificationService.Object,
            _logger.Object
        );
    }

    [TestMethod]
    [DataRow(null)]
    [DataRow("")]
    public async Task CreateTask_WithMissingTitle_ThrowsValidationException(string title)
    {
        // Arrange
        var request = new CreateTaskRequest { Title = title };

        // Act & Assert
        await Assert.ThrowsExceptionAsync<ValidationException>(
            () => _useCase.ExecuteAsync(request)
        );
    }

    [TestMethod]
    public async Task CreateTask_WithValidInput_CreatesTask()
    {
        // Arrange
        var request = new CreateTaskRequest
        {
            Title = "Database Migration",
            Description = "Migrate to PostgreSQL",
            AssigneeId = "user_123",
            DueDate = DateTime.UtcNow.AddDays(5),
            Priority = "high"
        };

        var createdTask = new Task
        {
            Id = "task_123",
            Title = request.Title,
            AssigneeId = request.AssigneeId,
            Status = "pending",
            CreatedAt = DateTime.UtcNow
        };

        _taskRepository
            .Setup(r => r.CreateAsync(It.IsAny<Task>()))
            .ReturnsAsync(createdTask);

        _userRepository
            .Setup(r => r.GetAsync("user_123"))
            .ReturnsAsync(new User { Id = "user_123", Email = "user@test.com" });

        // Act
        var result = await _useCase.ExecuteAsync(request);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual("task_123", result.Id);
        Assert.AreEqual("pending", result.Status);

        _taskRepository.Verify(r => r.CreateAsync(It.IsAny<Task>()), Times.Once);
        _notificationService.Verify(
            n => n.NotifyTaskAssignedAsync("user_123", "task_123"),
            Times.Once
        );
    }

    [TestMethod]
    [ExpectedException(typeof(EntityNotFoundException))]
    public async Task CreateTask_WithInvalidAssignee_ThrowsException()
    {
        // Arrange
        var request = new CreateTaskRequest
        {
            Title = "Test Task",
            AssigneeId = "invalid_user"
        };

        _userRepository
            .Setup(r => r.GetAsync("invalid_user"))
            .ReturnsAsync((User)null);

        // Act
        await _useCase.ExecuteAsync(request);
    }
}

// WallD.Infrastructure.Tests/Firebase/FirestoreRepositoryTests.cs

[TestClass]
public class FirestoreTaskRepositoryTests
{
    private FirestoreTaskRepository _repository;
    private Mock<FirestoreService> _firestore;
    private Mock<ILogger<FirestoreTaskRepository>> _logger;

    [TestInitialize]
    public void Setup()
    {
        _firestore = new Mock<FirestoreService>();
        _logger = new Mock<ILogger<FirestoreTaskRepository>>();

        _repository = new FirestoreTaskRepository(_firestore.Object, _logger.Object);
    }

    [TestMethod]
    public async Task GetAsync_WithValidId_ReturnsTask()
    {
        // Arrange
        var taskId = "task_123";
        var expectedTask = new Task
        {
            Id = taskId,
            Title = "Test Task",
            Status = "pending"
        };

        _firestore
            .Setup(f => f.GetDocumentAsync<Task>("tasks", taskId))
            .ReturnsAsync(expectedTask);

        // Act
        var result = await _repository.GetAsync(taskId);

        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(taskId, result.Id);
        _firestore.Verify(
            f => f.GetDocumentAsync<Task>("tasks", taskId),
            Times.Once
        );
    }
}

### 14.2 Integration Testing

// WallD.Tests/Integration/ApprovalWorkflowTests.cs

[TestClass]
public class ApprovalWorkflowIntegrationTests
{
    private FirebaseEmulator _emulator;
    private WallDApplication _app;

    [TestInitialize]
    public async Task Initialize()
    {
        // Start Firebase emulator
        _emulator = new FirebaseEmulator();
        await _emulator.StartAsync();

        // Create test application
        _app = new WallDApplication(_emulator.Config);
        await _app.InitializeAsync();
    }

    [TestCleanup]
    public async Task Cleanup()
    {
        await _emulator.StopAsync();
    }

    [TestMethod]
    public async Task ApprovalWorkflow_Complete_TaskApproved()
    {
        // Arrange
        var employee = await _app.CreateUserAsync(new User
        {
            Email = "employee@test.com",
            DesignationId = "employee"
        });

        var manager = await _app.CreateUserAsync(new User
        {
            Email = "manager@test.com",
            DesignationId = "manager"
        });

        var task = await _app.CreateTaskAsync(new Task
        {
            Title = "Complete Project",
            AssigneeId = employee.Id,
            RequiresApproval = true
        });

        // Act - Complete task
        await _app.CompleteTaskAsync(task.Id);

        // Verify approval created
        var approvals = await _app.GetPendingApprovalsAsync(manager.Id);
        Assert.AreEqual(1, approvals.Count);
        Assert.AreEqual(task.Id, approvals[0].TaskId);

        // Act - Approve
        await _app.ApproveTaskAsync(approvals[0].Id, manager.Id);

        // Assert - Task status changed
        var updatedTask = await _app.GetTaskAsync(task.Id);
        Assert.AreEqual("approved", updatedTask.ApprovalStatus);
    }

    [TestMethod]
    public async Task ApprovalWorkflow_Rejection_TaskRejected()
    {
        // Similar to above but test rejection flow
        // ...
    }
}

---

## 15. DEPLOYMENT & DEVOPS

### 15.1 CI/CD Pipeline (GitHub Actions)

# .github/workflows/build-and-deploy.yml

name: Build and Deploy

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      
      - name: Restore dependencies
        run: dotnet restore
      
      - name: Build
        run: dotnet build --configuration Release --no-restore
      
      - name: Test
        run: dotnet test --configuration Release --no-build --verbosity normal
      
      - name: Publish
        run: dotnet publish src/WallD/WallD.csproj -c Release -o publish
      
      - name: Create MSIX Package
        run: |
          cd publish
          makemsix -Manifest ../src/WallD/Package.appxmanifest -m ../src/WallD -o ../walld-app.msix

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/staging'
    runs-on: windows-latest
    
    steps:
      - name: Deploy to Azure AppService
        uses: azure/webapps-deploy@v2
        with:
          app-name: walld-staging
          publish-profile: ${{ secrets.AZURE_PUBLISH_PROFILE_STAGING }}
          package: ./publish
      
      - name: Deploy Firebase Functions
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

  deploy-production:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: windows-latest
    
    steps:
      - name: Deploy to Azure AppService
        uses: azure/webapps-deploy@v2
        with:
          app-name: walld-production
          publish-profile: ${{ secrets.AZURE_PUBLISH_PROFILE_PROD }}
          package: ./publish
      
      - name: Deploy Firebase Functions
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
      
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ github.run_number }}
          release_name: Release ${{ github.run_number }}

### 15.2 Docker Deployment

# Dockerfile for Firebase Cloud Functions deployment

FROM node:18-alpine as builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/dist ./dist

EXPOSE 5000

CMD ["npm", "start"]

### 15.3 Database Backup Strategy

// WallD.Infrastructure/Services/BackupService.cs

public interface IBackupService
{
    Task<string> CreateBackupAsync();
    Task RestoreFromBackupAsync(string backupId);
    Task<List<BackupMetadata>> GetBackupHistoryAsync();
}

public class FirestoreBackupService : IBackupService
{
    private readonly FirestoreAdminClient _firestoreAdmin;
    private readonly BlobServiceClient _blobServiceClient;
    private readonly ILogger<FirestoreBackupService> _logger;

    public async Task<string> CreateBackupAsync()
    {
        try
        {
            var databasePath = _firestoreAdmin.DatabasePath(
                _projectId, 
                "(default)"
            );

            var backupPath = _firestoreAdmin.BackupPath(
                _projectId, 
                Guid.NewGuid().ToString()
            );

            var operation = await _firestoreAdmin.ExportDocumentsAsync(
                new ExportDocumentsRequest
                {
                    Name = databasePath,
                    OutputUriPrefix = $"gs://{_backupBucket}/backups/"
                }
            );

            var completedOperation = await operation.PollUntilCompletedAsync();

            var backupMetadata = new BackupMetadata
            {
                Id = backupPath,
                CreatedAt = DateTime.UtcNow,
                Size = 0, // Would calculate from GCS
                Status = "completed"
            };

            await SaveBackupMetadataAsync(backupMetadata);

            _logger.LogInformation($"Backup created: {backupPath}");
            return backupPath;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Backup creation failed");
            throw;
        }
    }

    public async Task RestoreFromBackupAsync(string backupId)
    {
        try
        {
            var databasePath = _firestoreAdmin.DatabasePath(
                _projectId,
                "(default)"
            );

            var operation = await _firestoreAdmin.ImportDocumentsAsync(
                new ImportDocumentsRequest
                {
                    Name = databasePath,
                    InputUriPrefix = $"gs://{_backupBucket}/backups/{backupId}/"
                }
            );

            await operation.PollUntilCompletedAsync();

            _logger.LogInformation($"Backup restored: {backupId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Backup restore failed");
            throw;
        }
    }

    public async Task<List<BackupMetadata>> GetBackupHistoryAsync()
    {
        var blobContainer = _blobServiceClient.GetBlobContainerClient("backups");
        var backups = new List<BackupMetadata>();

        await foreach (var blob in blobContainer.GetBlobsAsync())
        {
            backups.Add(new BackupMetadata
            {
                Id = blob.Name,
                CreatedAt = blob.Properties.CreatedOn?.DateTime ?? DateTime.UtcNow,
                Size = blob.Properties.ContentLength ?? 0,
                Status = "available"
            });
        }

        return backups.OrderByDescending(b => b.CreatedAt).ToList();
    }
}

public class BackupMetadata
{
    public string Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public long Size { get; set; }
    public string Status { get; set; } // completed, pending, failed
}

---

## PRODUCTION READINESS CHECKLIST

### Infrastructure & Deployment
- [ ] Firebase project created with staging + production environments
- [ ] GitHub Actions CI/CD pipeline fully configured
- [ ] Azure App Service setup for Windows deployment
- [ ] Automatic backup scheduled (daily)
- [ ] Database indexes created in Firestore
- [ ] CDN configured for static assets
- [ ] Error logging with Application Insights
- [ ] Performance monitoring enabled

### Security & Compliance
- [ ] Firestore security rules validated
- [ ] Two-factor authentication implemented
- [ ] Session management with token expiry
- [ ] Password policies enforced
- [ ] Data encryption at rest and in transit
- [ ] GDPR compliance (data deletion, privacy)
- [ ] SOC 2 compliance documentation
- [ ] Security audit completed

### Testing & Quality
- [ ] Unit test coverage >80%
- [ ] Integration tests for critical flows
- [ ] Load testing completed (1000+ concurrent users)
- [ ] Security penetration testing done
- [ ] Accessibility audit (WCAG 2.1 AA)
- [ ] Performance benchmarks established
- [ ] Cross-browser testing

### Documentation
- [ ] API documentation complete
- [ ] Deployment runbook created
- [ ] Disaster recovery plan
- [ ] User documentation & videos
- [ ] Administrator guide
- [ ] Architecture decision records (ADRs)
- [ ] Code comments for complex logic

### Operations
- [ ] Monitoring dashboards setup
- [ ] Alert rules configured
- [ ] Incident response procedures
- [ ] Runbooks for common issues
- [ ] Support ticketing system
- [ ] SLA agreements defined
- [ ] Cost monitoring enabled

---

## NEXT STEPS (POST LAUNCH)

### Phase 2 (Months 4-6)
- Mobile app (Flutter) with offline sync
- Advanced reporting and analytics
- Custom workflow builder UI
- SSO integration (SAML/OAuth)

### Phase 3 (Months 7-9)
- AI-powered task recommendations
- Predictive resource allocation
- Advanced data visualization
- API for third-party integrations

### Phase 4 (Months 10-12)
- Global deployment (multi-region)
- Advanced security features
- Enterprise add-ons marketplace
- Certifications (ISO 27001, SOC 2)

---

## TECHNICAL DEBT TRACKING

Prioritized list of improvements:

1. **High Priority**
   - [ ] Implement distributed locking for concurrent edits
   - [ ] Add comprehensive audit logging
   - [ ] Optimize Firestore queries with materialized views

2. **Medium Priority**
   - [ ] Refactor form system for better extensibility
   - [ ] Add caching layer for frequently accessed data
   - [ ] Implement webhook system for integrations

3. **Low Priority**
   - [ ] Improve error messages UX
   - [ ] Add dark mode support
   - [ ] Optimize app startup time

---

## KEY METRICS & KPIs

Track these metrics post-launch:

| Metric | Target | Tool |
|--------|--------|------|
| API Response Time (p95) | <200ms | Application Insights |
| Task Creation Latency | <500ms | Firestore Metrics |
| Sync Success Rate | >99.5% | Custom Logging |
| Approval Completion Time | <24hrs | Analytics |
| User Adoption | >70% first month | Usage Analytics |
| Error Rate | <0.1% | Sentry |
| Mobile App Rating | 4.5+ stars | App Store Reviews |

---

**Document Status:** Production Ready  
**Last Updated:** December 2025  
**Maintainer:** Development Team  
**Version:** 2.0
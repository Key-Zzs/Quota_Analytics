import '../entities/notification_candidate.dart';
import '../repositories/notification_repository.dart';

class SendQuotaNotification {
  const SendQuotaNotification(this.repository);

  final NotificationRepository repository;

  Future<bool> call(NotificationCandidate candidate, {required DateTime now}) {
    return repository.send(candidate, now: now);
  }
}

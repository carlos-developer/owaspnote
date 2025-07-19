abstract class DomainEvent {
  final DateTime occurredOn;

  DomainEvent() : occurredOn = DateTime.now();
}
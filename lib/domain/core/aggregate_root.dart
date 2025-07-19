import 'entity.dart';
import 'domain_event.dart';

abstract class AggregateRoot<T> extends Entity<T> {
  final List<DomainEvent> _domainEvents = [];

  AggregateRoot(super.id);

  List<DomainEvent> get domainEvents => List.unmodifiable(_domainEvents);

  void addDomainEvent(DomainEvent event) {
    _domainEvents.add(event);
  }

  void clearDomainEvents() {
    _domainEvents.clear();
  }
}
abstract class Entity<T> {
  final T id;

  Entity(this.id);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entity<T> && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
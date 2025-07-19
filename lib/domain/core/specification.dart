abstract class Specification<T> {
  bool isSatisfiedBy(T candidate);

  Specification<T> and(Specification<T> other) {
    return AndSpecification(this, other);
  }

  Specification<T> or(Specification<T> other) {
    return OrSpecification(this, other);
  }

  Specification<T> not() {
    return NotSpecification(this);
  }
}

class AndSpecification<T> extends Specification<T> {
  final Specification<T> left;
  final Specification<T> right;

  AndSpecification(this.left, this.right);

  @override
  bool isSatisfiedBy(T candidate) {
    return left.isSatisfiedBy(candidate) && right.isSatisfiedBy(candidate);
  }
}

class OrSpecification<T> extends Specification<T> {
  final Specification<T> left;
  final Specification<T> right;

  OrSpecification(this.left, this.right);

  @override
  bool isSatisfiedBy(T candidate) {
    return left.isSatisfiedBy(candidate) || right.isSatisfiedBy(candidate);
  }
}

class NotSpecification<T> extends Specification<T> {
  final Specification<T> spec;

  NotSpecification(this.spec);

  @override
  bool isSatisfiedBy(T candidate) {
    return !spec.isSatisfiedBy(candidate);
  }
}
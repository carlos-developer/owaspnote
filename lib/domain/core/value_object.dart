abstract class ValueObject<T> {
  final T value;

  const ValueObject(this.value);

  Either<ValueFailure<T>, T> get validValue;

  bool isValid() => validValue.isRight();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValueObject<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Value($value)';
}

abstract class ValueFailure<T> {
  final T failedValue;
  final String? message;

  const ValueFailure({
    required this.failedValue,
    this.message,
  });
}

class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isRight;

  const Either.left(L left)
      : _left = left,
        _right = null,
        _isRight = false;

  const Either.right(R right)
      : _left = null,
        _right = right,
        _isRight = true;

  bool isLeft() => !_isRight;
  bool isRight() => _isRight;

  L get left {
    if (!isLeft()) {
      throw Exception('Called left on a Right');
    }
    return _left!;
  }

  R get right {
    if (!isRight()) {
      throw Exception('Called right on a Left');
    }
    return _right!;
  }

  T fold<T>(T Function(L) leftFn, T Function(R) rightFn) {
    return _isRight ? rightFn(_right as R) : leftFn(_left as L);
  }
}
sealed class ApiResult<T> {
  const ApiResult();

  factory ApiResult.success(T data) = Success<T>;
  factory ApiResult.failure(String message) = Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Failure<T>).message);
    }
  }
}

class Success<T> extends ApiResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends ApiResult<T> {
  final String message;
  const Failure(this.message);
}

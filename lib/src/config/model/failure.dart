import 'api_result.dart';

class Failure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;

  const Failure({this.message = "Something went wrong", this.statusCode});
}

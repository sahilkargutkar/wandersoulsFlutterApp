import 'package:wonder_souls/src/config/model/api_result.dart';

class Success<T> extends ApiResult<T> {
  final T data;
  final String  message; 
  const Success(this.data, {this.message="Sucess"});
}

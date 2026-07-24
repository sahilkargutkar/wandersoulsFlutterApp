import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/model/failure.dart';

abstract interface class UseCase<SucessType, Params> {
  Future<Either<Failure, SucessType>> call(Params params);
}

class NoParams {
  const NoParams();
}

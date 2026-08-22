import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:wonder_souls/src/features/trips/model/blog_model.dart';

abstract class BlogsState {}

class BlogsInitial extends BlogsState {}

class BlogsLoading extends BlogsState {}

class BlogsLoaded extends BlogsState {
  final List<BlogModel> blogs;
  BlogsLoaded(this.blogs);
}

class BlogsError extends BlogsState {
  final String message;
  BlogsError(this.message);
}

class BlogsCubit extends Cubit<BlogsState> {
  BlogsCubit() : super(BlogsInitial());

  Future<void> fetchBlogs() async {
    emit(BlogsLoading());
    try {
      final dio = Dio();
      final response = await dio.get('https://www.wandersouls.in/api/blogs');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList = response.data;
        final List<BlogModel> blogs = dataList
            .map((e) => BlogModel.fromJson(e as Map<String, dynamic>))
            .toList();
        emit(BlogsLoaded(blogs));
      } else {
        emit(BlogsError("Failed to fetch blogs: Status ${response.statusCode}"));
      }
    } catch (e) {
      emit(BlogsError("Failed to fetch blogs: ${e.toString()}"));
    }
  }
}

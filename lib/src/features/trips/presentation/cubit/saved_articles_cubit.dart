import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonder_souls/src/features/trips/model/blog_model.dart';

class SavedArticlesCubit extends Cubit<List<BlogModel>> {
  final SharedPreferences _prefs;
  static const String _savedArticlesKey = 'saved_articles_key';

  SavedArticlesCubit(this._prefs) : super([]) {
    _loadSavedArticles();
  }

  void _loadSavedArticles() {
    try {
      final savedString = _prefs.getString(_savedArticlesKey);
      if (savedString != null && savedString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(savedString);
        final List<BlogModel> articles = decodedList
            .map((item) => BlogModel.fromJson(item as Map<String, dynamic>))
            .toList();
        emit(articles);
      }
    } catch (_) {
      emit([]);
    }
  }

  bool isSaved(String articleId) {
    if (articleId.isEmpty) return false;
    return state.any((a) => a.id == articleId);
  }

  void toggleSave(BlogModel blog) {
    final currentList = List<BlogModel>.from(state);

    final isSavedIndex = currentList.indexWhere((a) {
      if (a.id.isNotEmpty && blog.id.isNotEmpty) {
        return a.id == blog.id;
      }
      return a.title == blog.title;
    });

    if (isSavedIndex >= 0) {
      currentList.removeAt(isSavedIndex);
    } else {
      currentList.add(blog);
    }

    emit(currentList);
    _saveToPrefs(currentList);
  }

  void removeArticle(String articleId) {
    final currentList = List<BlogModel>.from(state);
    currentList.removeWhere((a) => a.id == articleId);
    emit(currentList);
    _saveToPrefs(currentList);
  }

  void _saveToPrefs(List<BlogModel> articles) {
    final encodedList = articles.map((a) => a.toJson()).toList();
    _prefs.setString(_savedArticlesKey, json.encode(encodedList));
  }
}

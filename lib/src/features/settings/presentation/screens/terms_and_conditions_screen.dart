import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/failure.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  static const String routeName = "/TermsAndConditionsScreen";

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _title = "Terms & Conditions";
  String _htmlContent = "";

  @override
  void initState() {
    super.initState();
    _fetchTerms();
  }

  Future<void> _fetchTerms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = sl<ApiService>();
      final result = await apiService.get<dynamic>(
        ApiConstants.otherService,
        fromJson: (data) => data,
      );

      if (!mounted) return;

      if (result is Success<dynamic>) {
        final data = result.data;
        if (data is Map<String, dynamic>) {
          setState(() {
            _title = data["title"]?.toString() ?? "Terms & Conditions";
            _htmlContent =
                data["description_html"]?.toString() ??
                data["description"]?.toString() ??
                "";
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else if (result is Failure<dynamic>) {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          _title,
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: context.primary,
              strokeWidth: 3,
            ),
            16.h.verticalSpace,
            Text(
              "Loading Terms & Conditions...",
              style: context.text.bodyMedium?.copyWith(
                color: context.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: context.colors.error.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: context.colors.error,
                  size: 48.sp,
                ),
              ),
              16.h.verticalSpace,
              Text(
                "Unable to load Terms",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              8.h.verticalSpace,
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
              20.h.verticalSpace,
              ElevatedButton.icon(
                onPressed: _fetchTerms,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTerms,
      color: context.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Shield Banner Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.primaryTint,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: context.primary.withAlpha(30),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: context.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: context.primary,
                      size: 24.sp,
                    ),
                  ),
                  14.w.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Legal & Privacy Assurance",
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.onSurface,
                          ),
                        ),
                        4.h.verticalSpace,
                        Text(
                          "Please review our service policies and account permissions.",
                          style: context.text.bodySmall?.copyWith(
                            color: context.onSurfaceVariant,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            20.h.verticalSpace,

            // Content Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: context.mutedBackground,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: context.borderColor.withAlpha(50),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.primary,
                    ),
                  ),
                  12.h.verticalSpace,
                  const Divider(height: 1),
                  16.h.verticalSpace,
                  _buildHtmlSpans(context, _htmlContent),
                ],
              ),
            ),
            24.h.verticalSpace,

            // Official policy link footer
            Center(
              child: InkWell(
                onTap: () {
                  launchUrl(
                    Uri.parse("https://wanderingsouls.in/terms-and-conditions"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Open full web policy in browser",
                        style: context.text.bodySmall?.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      6.w.horizontalSpace,
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 14.sp,
                        color: context.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            20.h.verticalSpace,
          ],
        ),
      ),
    );
  }

  /// Parses basic HTML tags (<p>, <a>, <b>, <strong>) into clickable TextSpans
  Widget _buildHtmlSpans(BuildContext context, String html) {
    if (html.trim().isEmpty) {
      return Text(
        "No terms and conditions content available.",
        style: context.text.bodyMedium?.copyWith(
          color: context.onSurfaceVariant,
        ),
      );
    }

    // Split HTML into paragraph blocks
    final paragraphs = html
        .replaceAll('</p>', '\n\n')
        .replaceAll('<p>', '')
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: RichText(
            text: TextSpan(
              style: context.text.bodyMedium?.copyWith(
                color: context.onSurface,
                height: 1.6,
                fontSize: 13.5.sp,
              ),
              children: _parseInlineHtml(context, paragraph.trim()),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<InlineSpan> _parseInlineHtml(BuildContext context, String text) {
    final spans = <InlineSpan>[];
    final linkRegex = RegExp(r"<a\s+href=['\x22]([^'\x22]+)['\x22][^>]*>(.*?)<\/a>", caseSensitive: false);

    int lastIndex = 0;
    for (final match in linkRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final plain = text.substring(lastIndex, match.start);
        spans.add(TextSpan(text: _stripHtmlTags(plain)));
      }

      final url = match.group(1) ?? "";
      final linkText = _stripHtmlTags(match.group(2) ?? url);

      spans.add(
        TextSpan(
          text: linkText,
          style: TextStyle(
            color: context.primary,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: context.primary,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (url.isNotEmpty) {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: _stripHtmlTags(text.substring(lastIndex))));
    }

    return spans;
  }

  String _stripHtmlTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }
}

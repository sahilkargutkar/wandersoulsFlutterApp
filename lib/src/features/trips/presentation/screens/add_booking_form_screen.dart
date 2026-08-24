import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/api_services.dart';
import 'package:wonder_souls/src/config/model/success.dart';
import 'package:wonder_souls/src/config/utils/app_toast.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/accommodation_model.dart';
import 'package:wonder_souls/src/features/trips/model/trip_transport_model.dart';

class AddBookingFormScreen extends StatefulWidget {
  final String tripId;
  final String bookingType; // "accommodation" or "transport"

  const AddBookingFormScreen({
    super.key,
    required this.tripId,
    required this.bookingType,
  });

  static const String routeName = "/AddBookingFormScreen";

  @override
  State<AddBookingFormScreen> createState() => _AddBookingFormScreenState();
}

class _AddBookingFormScreenState extends State<AddBookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = sl<ApiService>();

  // General Fields
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _bookingRefController = TextEditingController();
  final _bookingUrlController = TextEditingController();

  // Accommodation Specific
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _accType = "Hotel";
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));

  // Transport Specific
  String _transportType = "Flight";
  final _providerController = TextEditingController();
  final _departureLocController = TextEditingController();
  final _arrivalLocController = TextEditingController();
  DateTime _departureTime = DateTime.now();
  DateTime _arrivalTime = DateTime.now().add(const Duration(hours: 2));

  // Attachment upload
  File? _pickedFile;
  bool _submitting = false;

  @override
  void dispose() {
    _costController.dispose();
    _notesController.dispose();
    _bookingRefController.dispose();
    _bookingUrlController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _providerController.dispose();
    _departureLocController.dispose();
    _arrivalLocController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadAttachment() async {
    if (_pickedFile == null) return null;
    final filename = _pickedFile!.path.split("/").last;
    final extension = filename.split(".").last;
    final blobPath =
        "attachments/${widget.tripId}_booking_${DateTime.now().millisecondsSinceEpoch}.$extension";

    final res = await _apiService.uploadFile(_pickedFile!.path, blobPath);
    if (res is Success<String>) {
      return blobPath;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    AppToast.success("Submitting booking details...");

    try {
      final docUrl = await _uploadAttachment();

      if (widget.bookingType == "accommodation") {
        final acc = AccommodationModel(
          tripId: widget.tripId,
          name: _nameController.text.trim(),
          type: _accType,
          bookingReference: _bookingRefController.text.trim(),
          address: _addressController.text.trim(),
          cost: double.tryParse(_costController.text.trim()) ?? 0.0,
          bookingUrl: _bookingUrlController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          confirmationDocumentUrl: docUrl,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
        );

        final res = await _apiService.post<dynamic>(
          "/Accomodation",
          data: acc.toJson(),
          fromJson: (d) => d,
        );

        if (res is Success) {
          AppToast.success("Accommodation added successfully!");
          if (mounted) context.pop();
        } else {
          AppToast.error("Failed to add accommodation");
        }
      } else {
        final transport = TripTransportModel(
          tripId: widget.tripId,
          type: _transportType,
          provider: _providerController.text.trim(),
          bookingReference: _bookingRefController.text.trim(),
          departureLocation: _departureLocController.text.trim(),
          arrivalLocation: _arrivalLocController.text.trim(),
          cost: double.tryParse(_costController.text.trim()) ?? 0.0,
          notes: _notesController.text.trim(),
          departureDatetime: _departureTime,
          arrivalDatetime: _arrivalTime,
        );

        final res = await _apiService.post<dynamic>(
          "/TripTransports",
          data: transport.toJson(),
          fromJson: (d) => d,
        );

        if (res is Success) {
          AppToast.success("Transport added successfully!");
          if (mounted) context.pop();
        } else {
          AppToast.error("Failed to add transport");
        }
      }
    } catch (e) {
      AppToast.error("An error occurred: $e");
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime initial = isStart
        ? (widget.bookingType == "accommodation" ? _checkInDate : _departureTime)
        : (widget.bookingType == "accommodation" ? _checkOutDate : _arrivalTime);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date == null) return;

    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (widget.bookingType == "accommodation") {
        if (isStart) {
          _checkInDate = selected;
          if (_checkOutDate.isBefore(_checkInDate)) {
            _checkOutDate = _checkInDate.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = selected;
        }
      } else {
        if (isStart) {
          _departureTime = selected;
          if (_arrivalTime.isBefore(_departureTime)) {
            _arrivalTime = _departureTime.add(const Duration(hours: 2));
          }
        } else {
          _arrivalTime = selected;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.bookingType == "accommodation"
        ? "Add Accommodation"
        : "Add Transport Booking";

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          title,
          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              if (widget.bookingType == "accommodation") ...[
                _buildSectionHeader("Accommodation Details"),
                12.h.verticalSpace,
                _buildTextFormField(
                  controller: _nameController,
                  labelText: "Hotel / Place Name *",
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Name is required" : null,
                ),
                12.h.verticalSpace,
                _buildDropdownField(
                  value: _accType,
                  items: ["Hotel", "Hostel", "Resort", "Airbnb", "Villa", "Camp", "Other"],
                  labelText: "Accommodation Type",
                  onChanged: (val) {
                    if (val != null) setState(() => _accType = val);
                  },
                ),
                12.h.verticalSpace,
                _buildTextFormField(controller: _addressController, labelText: "Address"),
                12.h.verticalSpace,
                _buildTextFormField(
                  controller: _phoneController,
                  labelText: "Phone Number",
                  keyboardType: TextInputType.phone,
                ),
                16.h.verticalSpace,
                _buildSectionHeader("Dates & Schedule"),
                12.h.verticalSpace,
                _buildDateTimeTile(
                  context,
                  label: "Check-In Date & Time",
                  dateTime: _checkInDate,
                  onTap: () => _selectDateTime(context, true),
                ),
                12.h.verticalSpace,
                _buildDateTimeTile(
                  context,
                  label: "Check-Out Date & Time",
                  dateTime: _checkOutDate,
                  onTap: () => _selectDateTime(context, false),
                ),
              ] else ...[
                _buildSectionHeader("Transport Details"),
                12.h.verticalSpace,
                _buildDropdownField(
                  value: _transportType,
                  items: ["Flight", "Train", "Bus", "Car Rental", "Ferry", "Other"],
                  labelText: "Transport Type",
                  onChanged: (val) {
                    if (val != null) setState(() => _transportType = val);
                  },
                ),
                12.h.verticalSpace,
                _buildTextFormField(
                  controller: _providerController,
                  labelText: "Provider / Airline Name *",
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Provider is required" : null,
                ),
                12.h.verticalSpace,
                _buildTextFormField(
                  controller: _departureLocController,
                  labelText: "Departure Station / City *",
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Departure location is required" : null,
                ),
                12.h.verticalSpace,
                _buildTextFormField(
                  controller: _arrivalLocController,
                  labelText: "Arrival Station / City *",
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? "Arrival location is required" : null,
                ),
                16.h.verticalSpace,
                _buildSectionHeader("Times & Schedule"),
                12.h.verticalSpace,
                _buildDateTimeTile(
                  context,
                  label: "Departure Date & Time",
                  dateTime: _departureTime,
                  onTap: () => _selectDateTime(context, true),
                ),
                12.h.verticalSpace,
                _buildDateTimeTile(
                  context,
                  label: "Arrival Date & Time",
                  dateTime: _arrivalTime,
                  onTap: () => _selectDateTime(context, false),
                ),
              ],
              16.h.verticalSpace,
              _buildSectionHeader("Billing & Booking"),
              12.h.verticalSpace,
              _buildTextFormField(
                controller: _costController,
                labelText: "Cost (\$)",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) return "Enter a valid cost number";
                  }
                  return null;
                },
              ),
              12.h.verticalSpace,
              _buildTextFormField(
                controller: _bookingRefController,
                labelText: "Booking Reference Number",
              ),
              12.h.verticalSpace,
              _buildTextFormField(
                controller: _bookingUrlController,
                labelText: "Booking Details URL / Link",
                keyboardType: TextInputType.url,
              ),
              12.h.verticalSpace,
              _buildTextFormField(
                controller: _notesController,
                labelText: "Additional Notes",
                maxLines: 3,
              ),
              16.h.verticalSpace,
              _buildSectionHeader("Document Attachment"),
              12.h.verticalSpace,
              _buildAttachmentPicker(context),
              28.h.verticalSpace,
              _buildSubmitButton(context),
              40.h.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: context.text.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: context.primary,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String labelText,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildDateTimeTile(
    BuildContext context, {
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor.withAlpha(50)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.bodySmall?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
                4.h.verticalSpace,
                Text(
                  "${dateTime.day}/${dateTime.month}/${dateTime.year}   ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(Icons.calendar_today, color: context.primary, size: 18.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPicker(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.mutedBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withAlpha(20)),
      ),
      child: Column(
        children: [
          if (_pickedFile != null) ...[
            Row(
              children: [
                Icon(Icons.insert_drive_file_rounded, color: context.primary, size: 24.sp),
                12.w.horizontalSpace,
                Expanded(
                  child: Text(
                    _pickedFile!.path.split("/").last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: () => setState(() => _pickedFile = null),
                ),
              ],
            ),
          ] else ...[
            Text(
              "Add ticket snapshot, voucher receipt, or confirmation PDF",
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.onSurfaceVariant,
              ),
            ),
            12.h.verticalSpace,
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary.withAlpha(15),
                foregroundColor: context.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: _pickAttachment,
              icon: Icon(Icons.add_a_photo_outlined, size: 18.sp),
              label: const Text("Select Ticket / Document"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: context.primary,
        minimumSize: Size(double.infinity, 48.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
      ),
      onPressed: _submitting ? null : _submit,
      child: _submitting
          ? SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              "Save Booking Details",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

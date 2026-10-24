import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../../domain/entities/recording/recording_detail.dart';
import '../../../../../domain/repositories/audio_repository/audio_repository.dart';

/// Uploads a finished recording to the medvoice-service `/recordings` endpoint.
/// Shared by the iOS and Android recording screens: the upload contract is the
/// same, only the on-device live-transcription engine differs.
class RecordingPresenter extends Presenter {
  final AudioRepository _audioRepository;

  Function? onUploadRecordingSuccess;
  Function? onUploadRecordingFailed;

  RecordingPresenter(this._audioRepository);

  @override
  void dispose() {}

  Future<void> executeUploadRecording(
      File file, String? patientName, String language) async {
    try {
      final RecordingDetail detail = await _audioRepository.uploadRecording(
        filePath: file.path,
        fileName: _fileNameFor(file),
        patientName:
            (patientName == null || patientName.isEmpty) ? null : patientName,
        language: language,
      );
      onUploadRecordingSuccess?.call(detail);
    } catch (e) {
      onUploadRecordingFailed?.call(e);
    }
  }

  /// Backend audio allowlist (`Config.ALLOWED_EXTENSIONS` minus video).
  static const List<String> uploadAudioExtensions = [
    'mp3', 'wav', 'aac', 'ogg', 'oga', 'm4a', 'wma', 'amr', 'awb'
  ];

  /// Opens the system file picker; null when the user cancels.
  // ponytail: picker's cache copy is left for the OS to purge.
  Future<String?> pickAudioFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: uploadAudioExtensions);
    return result?.files.single.path;
  }

  /// The recorder names files after the patient, so an unnamed recording yields
  /// a bare ".m4a". Fall back to a timestamp so the server always gets a usable
  /// filename.
  String _fileNameFor(File file) {
    final String name = file.uri.pathSegments.last;
    if (name.isEmpty || name.startsWith('.')) {
      return 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    return name;
  }
}

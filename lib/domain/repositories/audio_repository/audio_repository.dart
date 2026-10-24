import '../../entities/recording/recording_detail.dart';
import '../../entities/recording/recording_list.dart';

abstract class AudioRepository {
  Future<RecordingDetail> uploadRecording({
    required String filePath,
    required String fileName,
    String? patientName,
    String language,
  });
  Future<RecordingList> listRecordings();
  Future<RecordingDetail> getRecordingDetail(String recordingId);
  Future<void> deleteRecording(String recordingId);
}

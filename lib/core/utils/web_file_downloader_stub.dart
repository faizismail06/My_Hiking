Future<void> downloadTextFileOnWeb({
  required String fileName,
  required String content,
  String mimeType = 'text/plain',
}) async {
  throw UnsupportedError('Web downloader tidak tersedia pada platform ini.');
}

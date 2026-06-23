// ReportsExportWeb: pdf экспорт из админки полностью удалён.
// Файл оставлен только чтобы не ломать импорты, если где-то ещё осталась ссылка.

class ReportsExportWeb {
  const ReportsExportWeb();

  static Future<void> exportReportsPdf({
    required int periodDays,
    required String periodLabel,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    throw UnsupportedError('PDF экспорт из админки удалён.');
  }
}


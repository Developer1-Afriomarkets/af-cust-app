/// Abstract base class for all data repositories.
/// This enables seamless switching between dummy data and real
/// (Supabase + Medusa) data sources.
///
/// Usage:
///   - In debug/development mode, use the DummyDataRepository implementations
///   - In production mode, use the RealDataRepository implementations
///   - Toggle via AppConfig or environment variable
abstract class DataRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(dynamic id);
}

/// Mixin to identify whether a repository is serving dummy data
mixin DummyDataMarker {
  bool get isDummy => true;
}

/// Enum to control which data source the app uses
enum DataSourceMode {
  dummy,
  real,
}

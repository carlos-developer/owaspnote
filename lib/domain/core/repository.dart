abstract class Repository<T, ID> {
  Future<T?> findById(ID id);
  Future<List<T>> findAll();
  Future<void> save(T entity);
  Future<void> delete(T entity);
}
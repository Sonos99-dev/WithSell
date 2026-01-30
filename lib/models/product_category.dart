enum ProductCategory {
  all("전체"),
  noodle("국수"),
  rice("누룽지"),
  gift("선물세트"),
  etc("기타");

  final String label;
  const ProductCategory(this.label);
}
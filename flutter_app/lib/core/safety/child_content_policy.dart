/// This allowlist is shared by child-facing adapters and tests.
/// Adult notes, diagnostic claims, and employment language must never reach play routes.
const Set<String> childContentForbiddenTerms = <String>{
  'diagnosis',
  'diagnostic',
  'autism',
  'career',
  'job',
  'salary',
  'employer',
  'industry',
};

bool isSafeChildCopy(String value) {
  final lowercase = value.toLowerCase();
  return childContentForbiddenTerms.every((term) => !lowercase.contains(term));
}

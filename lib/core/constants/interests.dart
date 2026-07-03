/*
InterestCatalog — the curated first-run interest catalog. Each Interest maps a
chip label to a source query `topic`; the interests the user picks become
Subscriptions. Topics are lowercase (they become Subscription ids) and chosen to
work across the sources' search (Hacker News, dev.to, Habr, Lobsters).
*/
class Interest {
  const Interest(this.label, this.topic);

  final String label;
  final String topic;
}

class InterestGroup {
  const InterestGroup(this.title, this.interests);

  final String title;
  final List<Interest> interests;
}

class InterestCatalog {
  const InterestCatalog._();

  static const List<InterestGroup> groups = [
    InterestGroup('Development', [
      Interest('Flutter', 'flutter'),
      Interest('Backend', 'backend'),
      Interest('Frontend', 'frontend'),
      Interest('Mobile', 'mobile'),
      Interest('Web', 'web'),
      Interest('Programming', 'programming'),
    ]),
    InterestGroup('DevOps / Infra', [
      Interest('DevOps', 'devops'),
      Interest('Cloud', 'cloud'),
      Interest('Kubernetes', 'kubernetes'),
      Interest('Docker', 'docker'),
      Interest('Linux', 'linux'),
    ]),
    InterestGroup('Data & AI', [
      Interest('AI / ML', 'ai'),
      Interest('Data', 'data'),
      Interest('Databases', 'database'),
      Interest('PostgreSQL', 'postgresql'),
    ]),
    InterestGroup('Quality & Security', [
      Interest('Security', 'security'),
      Interest('Testing', 'testing'),
    ]),
    InterestGroup('IT-Business', [
      Interest('Startup', 'startup'),
      Interest('Product', 'product'),
      Interest('Career', 'career'),
      Interest('Technology', 'technology'),
    ]),
  ];
}

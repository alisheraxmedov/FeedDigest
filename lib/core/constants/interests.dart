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
    InterestGroup('Languages', [
      Interest('Python', 'python'),
      Interest('JavaScript', 'javascript'),
      Interest('TypeScript', 'typescript'),
      Interest('Rust', 'rust'),
      Interest('Go', 'go'),
      Interest('Kotlin', 'kotlin'),
      Interest('Swift', 'swift'),
      Interest('Java', 'java'),
      Interest('C++', 'cpp'),
      Interest('Dart', 'dart'),
    ]),
    InterestGroup('AI & LLMs', [
      Interest('AI / ML', 'ai'),
      Interest('Machine Learning', 'machine learning'),
      Interest('Deep Learning', 'deep learning'),
      Interest('LLMs', 'llm'),
      Interest('Generative AI', 'generative ai'),
      Interest('Claude', 'claude'),
      Interest('ChatGPT', 'chatgpt'),
      Interest('Gemini', 'gemini'),
      Interest('LangChain', 'langchain'),
      Interest('Computer Vision', 'computer vision'),
      Interest('NLP', 'nlp'),
    ]),
    InterestGroup('Web & Frontend', [
      Interest('React', 'react'),
      Interest('Vue', 'vue'),
      Interest('Angular', 'angular'),
      Interest('Next.js', 'nextjs'),
      Interest('Node.js', 'nodejs'),
      Interest('Frontend', 'frontend'),
      Interest('Web', 'web'),
    ]),
    InterestGroup('Mobile', [
      Interest('Flutter', 'flutter'),
      Interest('iOS', 'ios'),
      Interest('Android', 'android'),
      Interest('React Native', 'react native'),
      Interest('Mobile', 'mobile'),
    ]),
    InterestGroup('Backend & Data', [
      Interest('Backend', 'backend'),
      Interest('Databases', 'database'),
      Interest('PostgreSQL', 'postgresql'),
      Interest('SQL', 'sql'),
      Interest('Data', 'data'),
      Interest('Data Science', 'data science'),
    ]),
    InterestGroup('DevOps & Cloud', [
      Interest('DevOps', 'devops'),
      Interest('Cloud', 'cloud'),
      Interest('AWS', 'aws'),
      Interest('Kubernetes', 'kubernetes'),
      Interest('Docker', 'docker'),
      Interest('Linux', 'linux'),
      Interest('Terraform', 'terraform'),
      Interest('CI/CD', 'cicd'),
    ]),
    InterestGroup('Security & Web3', [
      Interest('Security', 'security'),
      Interest('Cybersecurity', 'cybersecurity'),
      Interest('Privacy', 'privacy'),
      Interest('Blockchain', 'blockchain'),
      Interest('Crypto', 'crypto'),
      Interest('Web3', 'web3'),
    ]),
    InterestGroup('Companies', [
      Interest('GitHub', 'github'),
      Interest('Google', 'google'),
      Interest('Amazon', 'amazon'),
      Interest('Microsoft', 'microsoft'),
      Interest('Apple', 'apple'),
      Interest('Meta', 'meta'),
      Interest('Nvidia', 'nvidia'),
      Interest('OpenAI', 'openai'),
    ]),
    InterestGroup('Business & Career', [
      Interest('Startup', 'startup'),
      Interest('Product', 'product'),
      Interest('Programming', 'programming'),
      Interest('Technology', 'technology'),
      Interest('Open Source', 'open source'),
      Interest('Testing', 'testing'),
      Interest('Career', 'career'),
    ]),
  ];
}

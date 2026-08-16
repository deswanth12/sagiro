class FamilyQuestions {
  static String answer(String question) {
    final q = question.toLowerCase();
    if (q.contains('saved') || q.contains('most')) {
      return 'Dad saved the most toward shared goals this month (₹2,00,000 contributed).';
    }
    if (q.contains('afford') || q.contains('vacation')) {
      return 'Yes! The family has saved 72% (₹1,08,000) of the vacation budget.';
    }
    return 'The family spent 14% less on groceries compared to last month.';
  }
}

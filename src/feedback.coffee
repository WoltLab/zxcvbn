scoring = require('./scoring')

default_phrases =
  suggestions:
    use_words_avoid_common_phrases: 'Use a few words, avoid common phrases'
    no_need_for_symbols_digits_uppercase: 'No need for symbols, digits, or uppercase letters'

    add_word_uncommon_better: 'Add another word or two. Uncommon words are better.'

    use_longer_keyboard_pattern: 'Use a longer keyboard pattern with more turns'

    avoid_repeat: 'Avoid repeated words and characters'

    avoid_sequence: 'Avoid sequences'

    avoid_recent_year: 'Avoid recent years'
    avoid_associated_year: 'Avoid years that are associated with you'

    avoid_date: 'Avoid dates and years that are associated with you'

    start_upper: "Capitalization doesn't help very much"
    all_upper: 'All-uppercase is almost as easy to guess as all-lowercase'

    reversed: "Reversed words aren't much harder to guess"

    l33t: "Predictable substitutions like '@' instead of 'a' don't help very much"

  warnings:
    straight_row: 'Straight rows of keys are easy to guess'
    short_keyboard_pattern: 'Short keyboard patterns are easy to guess'

    repeat_single_char: 'Repeats like "aaa" are easy to guess'
    repeat: 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"'

    sequence: 'Sequences like abc or 6543 are easy to guess'

    recent_year: 'Recent years are easy to guess'

    date: 'Dates are often easy to guess'

    top_10: 'This is a top-10 common password'
    top_100: 'This is a top-100 common password'
    common: 'This is a very common password'
    common_alike: 'This is similar to a commonly used password'
    sole_word: 'A word by itself is easy to guess'
    sole_name: 'Names and surnames by themselves are easy to guess'
    name: 'Common names and surnames are easy to guess'


class Feedback
  constructor: (phrases = {}) ->
    @phrases = {}
    for source in [default_phrases, phrases]
      for key, value of source
        @phrases[key] = {
          (@phrases[key] or {})...
          value...
        }
  
    @default_feedback =
      warning: ''
      suggestions: [
        @phrases.suggestions.use_words_avoid_common_phrases
        @phrases.suggestions.no_need_for_symbols_digits_uppercase
      ]

  from_result: (result) ->
    @get_feedback result.score, result.sequence

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = @phrases.suggestions.add_word_uncommon_better
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          @phrases.warnings.straight_row
        else
          @phrases.warnings.short_keyboard_pattern
        warning: warning
        suggestions: [
          @phrases.suggestions.use_longer_keyboard_pattern
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          @phrases.warnings.repeat_single_char
        else
          @phrases.warnings.repeat
        warning: warning
        suggestions: [
          @phrases.suggestions.avoid_repeat
        ]

      when 'sequence'
        warning: @phrases.warnings.sequence
        suggestions: [
          @phrases.suggestions.avoid_sequence
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: @phrases.warnings.recent_year
          suggestions: [
            @phrases.suggestions.avoid_recent_year
            @phrases.suggestions.avoid_associated_year
          ]

      when 'date'
        warning: @phrases.warnings.date
        suggestions: [
          @phrases.suggestions.avoid_date
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          @phrases.warnings.top_10
        else if match.rank <= 100
          @phrases.warnings.top_100
        else
          @phrases.warnings.common
      else if match.guesses_log10 <= 4
        @phrases.warnings.common_alike
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        @phrases.warnings.sole_word
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        @phrases.warnings.sole_name
      else
        @phrases.warnings.name
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push @phrases.suggestions.start_upper
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push @phrases.suggestions.all_upper

    if match.reversed and match.token.length >= 4
      suggestions.push @phrases.suggestions.reversed
    if match.l33t
      suggestions.push @phrases.suggestions.l33t

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = Feedback

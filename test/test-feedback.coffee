test = require 'tape'
zxcvbn = require '../src/main'
Feedback = require '../src/feedback'

test 'no warning for no password', (t) ->
  feedbacker = new Feedback
  t.equal feedbacker.get_feedback(0, []).warning, ''
  t.end()

test 'basic localization test', (t) ->
  feedbacker = new Feedback
    warnings:
      date: 'date'
    suggestions:
      avoid_date: 'avoid_date'

  feedback = feedbacker.from_result(zxcvbn('20000101'))

  t.equal feedback.warning, 'date'
  t.ok feedback.suggestions.includes 'avoid_date'
  t.end()

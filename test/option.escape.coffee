
parse = require '../lib'

describe 'Option `escape`', ->

  describe 'normalisation, coercion & validation', ->
  
    it 'default', ->
      parse().options.escape.should.eql Buffer.from('"')[0]
      parse(escape: undefined).options.escape.should.eql Buffer.from('"')[0]
      parse(escape: true).options.escape.should.eql Buffer.from('"')[0]
  
    it 'custom', ->
      parse(escape: '\\').options.escape.should.eql Buffer.from('\\')[0]
      parse(escape: Buffer.from('\\')).options.escape.should.eql Buffer.from('\\')[0]
  
    it 'disabled', ->
      (parse(escape: null).options.escape is null).should.be.true()
      (parse(escape: false).options.escape is null).should.be.true()
  
    it 'invalid', ->
      (->
        parse escape: 1
      ).should.throw 'Invalid Option: escape must be a buffer, a string or a boolean, got 1'
      (->
        parse escape: 'abc'
      ).should.throw 'Invalid Option Length: escape must be one character, got 3'
  
  describe 'disabled', ->

    it 'when null', (next) ->
      parse '''
      a"b
      '1"2'
      ''', escape: null, quote: '\'', (err, data) ->
        return next err if err
        data.should.eql [
          [ 'a"b' ],[ '1"2' ]
        ]
        next()
      
  describe 'same as quote', ->

    it 'is same as quote', (next) ->
      parse '''
      aa,"b1""b2","c""d""e"
      "f""g",h,"i1""i2"
      ''', escape: '"', (err, data) ->
        return next err if err
        data.should.eql [
          [ 'aa','b1"b2','c"d"e' ]
          [ 'f"g','h','i1"i2' ]
        ]
        next()

  describe 'different than quote', ->

    it 'apply to quote char', (next) ->
      parse '''
      aa,"b1\\"b2","c\\"d\\"e"
      "f\\"g",h,"i1\\"i2"
      ''', escape: '\\', (err, data) ->
        return next err if err
        data.should.eql [
          [ 'aa','b1"b2','c"d"e' ]
          [ 'f"g','h','i1"i2' ]
        ]
        next()

    it 'apply to escape char', (next) ->
      parse '''
      aa,"b1\\\\b2","c\\\\d\\\\e"
      "f\\\\g",h,"i1\\\\i2"
      ''', escape: '\\', (err, data) ->
        return next err if err
        data.should.eql [
          [ 'aa','b1\\b2','c\\d\\e' ]
          [ 'f\\g','h','i1\\i2' ]
        ]
        next()

    it 'does not apply outside quoted field', (next) ->
      parse '''
      aa,b1\\\\b2,c\\\\d\\\\e
      f\\\\g,h,i1\\\\i2
      ''', escape: '\\', (err, data) ->
        return next err if err
        data.should.eql [
          [ 'aa','b1\\\\b2','c\\\\d\\\\e' ]
          [ 'f\\\\g','h','i1\\\\i2' ]
        ]
        next()

    it 'does not apply to delimiter', (next) ->
      parse '''
      aa\\,bb
      ''', escape: '\\', (err, data) ->
        return next err if err
        data.should.eql [
          [ 'aa\\','bb' ]
        ]
        next()

    it 'handle non continuous chunks', (next) ->
      data = []
      parser = parse escape: '\\'
      parser.on 'readable', ->
        while d = parser.read()
          data.push d
      parser.on 'end', ->
        data.should.eql [
          [ 'abc " def' ]
        ]
        next()
      parser.write chr for chr in '''
        "abc \\" def"
        '''
      parser.end()

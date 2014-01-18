'use strict'

error = (message)->
  console.error message

class WebSpider
  constructur:
    @
  run: (config)->
    @urls = config.urls
    error "urls required" unless @urls?
    @tags = config.tags
    error "tags required" unless @tags?

    phantom = require 'phantom'
    sqlite3 = require('sqlite3').verbose()
    @db = new sqlite3.Database config.database
    self = @
    phantom.create '', (ph)->
      self.ph = ph
      self.capturePageRecursive ->
        setTimeout ->
          self.db.close()
          self.ph.exit()
        , 1000

  capturePageRecursive: (callback)->
    # 終了条件
    if @urls.length is 0 then return callback()
    self = @
    url = @urls.shift()
    @ph.createPage (page)->
      self.page = page
      options =
        width: 1366
        height: 768
      page.set 'viewportSize', options, ->
        page.open url, (status)->
          console.log '['+status+']'+url
          if status is 'success'
            # ページ内でjsを実行している場合があるので、2秒待ってから処理を開始する
            setTimeout ->
              self.parsePage url, callback
            ,2000
          else
            # ページが開けなかったら次のURLの処理へ
            @capturePageRecursive callback

  parsePage: (url, callback)->
    self = @
    jqueryPath = 'http://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js'
    @page.includeJs jqueryPath, ->
      self.page.evaluate (_tags)->
        do ->
          data = {}
          for tag in _tags
            data[tag] = []
            $(tag).each (i, node)->
              $node = $(node)
              data[tag].push {
                tagName: node.tagName
                width: $node.width()
                height: $node.height()
                top: $node.offset().top
                left: $node.offset().left
              }
          return data
      ,(result)->
        self.save(result)
        self.page.close()
        self.capturePageRecursive callback
      , self.tags

  save: (result)->
    self = @
    for tag in @tags
      @db.serialize ->
        self.db.run 'CREATE TABLE IF NOT EXISTS ' + tag + ' (width INTEGER, height INTEGER, top INTEGER, left INTEGER)'
        self.db.serialize ->
          stmt = self.db.prepare 'INSERT INTO ' + tag + ' VALUES (?, ?, ?, ?)'
          for data in result[tag]
            stmt.run data.width, data.height, data.top, data.left
          stmt.finalize()

module.exports = new WebSpider()

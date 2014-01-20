'use strict'

error = (message)->
  console.error message
  process.exit()

# 配列のシャッフルアルゴリズム
# 参考 http://la.ma.la/blog/diary_200608300350.htm
shuffle = (array)->
  i = array.length
  while i
    j = Math.floor(Math.random()*i);
    tmp = array[--i]
    array[i] = array[j]
    array[j] = tmp
  return array

run = (config, classA, classB)->
  error 'classA is must a single tag' if classA.length > 1
  sqlite3 = require('sqlite3').verbose()
  db = new sqlite3.Database config.database
  tags = classA.concat classB
  data = {}
  for tag in tags
    data[tag] = []
    getDataFromTable db, tag, data
  db.close ->
    crossValidation data, classA, classB

###
  @args [Object, String, Object]
    dbオブジェクト, データを取得するテーブル名, データを保存するオブジェクト
###
getDataFromTable = (db, tag, data)->
  db.serialize ->
    db.each 'SELECT * FROM '+tag, (err, row)->
      error 'DB error.' if err
      data[tag].push row

###
  @args [Object, Array, Array]
    DBから読み込んだデータの集合, クラスAのHTMLタグ, クラスBのHTMLタグ
###
crossValidation = (data, classA, classB)->
  # 各クラスのデータ数が均等になるように調整
  numOfDataPerClass = fixNumOfData data, classA, classB

  # 交差検定用のデータを作成
  dataA = shuffle(data[classA[0]]).slice 0, numOfDataPerClass
  dataB = []
  for tag in classB
    tmp = shuffle data[tag]
    dataB = dataB.concat tmp.slice(0, numOfDataPerClass/classB.length)
  dataB = shuffle dataB

  # 交差検定開始
  # kの値
  # 参考 http://d.hatena.ne.jp/hoxo_m/20110618/p1
  preK = (1 + Math.log(numOfDataPerClass*2)/Math.log(2)) * 4

  # kの値を調整
  k = numOfDataPerClass
  for i in [1..preK]
    k = i if numOfDataPerClass % i is 0

  # k個のサブセットを作成
  subsets = []
  do ->
  numOfDataPerSubset = numOfDataPerClass/k
  for i in [0..k-1]
    subsets[i] = {
      dataA: dataA.slice i*numOfDataPerSubset, (i+1)*numOfDataPerSubset
      dataB: dataB.slice i*numOfDataPerSubset, (i+1)*numOfDataPerSubset
    }

  # サブセット分テストする
  hit = 0
  for i in [0..k-1]
    console.log "Calculating(#{i}/#{k})..."
    # テスト用データ作成
    subset = subsets[i]
    testData = []
    testLabels = []
    for data in subset.dataA
      testData.push [data.width, data.height, data.top, data.left]
      testLabels.push 1
    for data in subset.dataB
      testData.push [data.width, data.height, data.top, data.left]
      testLabels.push -1

    # 学習用データ作成
    trainingData = []
    trainingLabels = []
    for j in [0..k-1]
      continue if i is j
      for data in subsets[j].dataA
        trainingData.push [data.width, data.height, data.top, data.left]
        trainingLabels.push 1
      for data in subsets[j].dataB
        trainingData.push [data.width, data.height, data.top, data.left]
        trainingLabels.push -1

    # 学習
    svmjs = require 'svm'
    svm = new svmjs.SVM()
    svm.train trainingData, trainingLabels
    result = svm.predict testData
    for j in [0..result.length-1]
      hit += 1 if result[j] is testLabels[j]

  # 結果表示
  console.log 'done'
  console.log hit/(numOfDataPerClass*2)

###
 @return Integer 学習に用いるデータ数（各クラス）
###
fixNumOfData = (data, classA, classB)->
  # classA = 分類するタグの要素数を取得
  numOfDataA = data[classA[0]].length
  min = numOfDataA
  for tag in classB
    min = data[tag].length if min > data[tag].length

  # レコード数の最小がclassAだった場合
  if min is numOfDataA
    rest = min % classB.length
    n = min - rest
  else
    if min * classB.length <= numOfDataA
      n = min * classB.length
    else
      # classAが最小値だった時と同じ処理
      min = numOfDataA
      rest = min % classB.length
      n = min - rest
  return n

module.exports = {
  run: run
}

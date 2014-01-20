so2pro
---

# What's so2pro?
卒プロの提出用コード。masterブランチは最終発表までに更新する可能性あり。

提出時に切ったブランチ → [submitted_20140120](https://github.com/saxsir/so2pro/tree/submitted_20140120)

# Usage
- Clone this repository.
- At first, get experiment data.(Just once)
- Run cross validation script.
- You can see accuracy of classifier that we made.

```
$ git clone git://github.com/saxsir/so2pro.git
$ cd so2pro
$ ./bin/web-spider.coffee examples/sample.json
$ ./bin/cross-validation.coffee examples/sample.json 'h1' 'span,p'
Calculating(0/2)...
Calculating(1/2)...
done
0.5
```
You can also edit sample config file. Add urls and try to see change of value.

# Requirement
- PhantomJS
- Node.js
- Sqlite3


# LICENSE
MIT
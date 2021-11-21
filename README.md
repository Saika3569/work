# 作業

## 內容
寫一個script,可以在672往大鵬新城方向的公車,到達博仁醫院前3~5站時發出通知(語言/通知方法不限) 
## 實作
- 使用語言: Ruby
- 使用的 API: [公共運輸整合資訊流通服務平臺](https://ptx.transportdata.tw/PTX/)
- 通知套件: [terminal-notifier](https://github.com/julienXX/terminal-notifier/tree/master/Ruby)

步驟：
1. 672 往大鵬新城方向的公車，為反向 Direction = 1 
2. 博仁醫院前3~5站為 三民健康路口(西松高中)，健康新城，長壽公園站
3. 上述三站代表 StopSequence 為 2 ~ 4
4. 符合結果就發出通知

## 使用步驟
1. 申請 [公共運輸整合資訊流通服務平臺](https://ptx.transportdata.tw/PTX/) 的 API ID 與 API KEY
2. 終端機輸入 cp key.rb.sample key.rb
3. key.rb 填上 API 的 ID 與 KEY
3. 執行 api.rb


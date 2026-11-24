# Backlog: carat/domain/message_history.rb

### the levels INFO, WARNING, and ERROR stay on MessageHistory, which at carat/domain/message_history.rb:10 (sprint-32 sweep quality, note 5)
- Location: carat/domain/message_history.rb:10
- Why: the levels INFO, WARNING, and ERROR stay on MessageHistory, which no longer keeps a level since #332, and Notices, FloatPainter (float_painter.rb:237), and JsonRpcLanguageGateway (json_rpc_language_gateway.rb:1207) name them there
- Fix: move the three constants to Notices, which stores levels, and update the callers
- Category: quality

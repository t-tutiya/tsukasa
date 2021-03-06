#! ruby -E utf-8

###############################################################################
#TSUKASA for DXRuby ver2.2(2017/2/14)
#メッセージ指向ゲーム記述言語「司エンジン（Tsukasa Engine）」 for DXRuby
#
#Copyright (c) <2013-2017> <tsukasa TSUCHIYA>
#
#This software is provided 'as-is', without any express or implied
#warranty. In no event will the authors be held liable for any damages
#arising from the use of this software.
#
#Permission is granted to anyone to use this software for any purpose,
#including commercial applications, and to alter it and redistribute it
#freely, subject to the following restrictions:
#
#   1. The origin of this software must not be misrepresented; you must not
#   claim that you wrote the original software. If you use this software
#   in a product, an acknowledgment in the product documentation would be
#   appreciated but is not required.
#
#   2. Altered source versions must be plainly marked as such, and must not be
#   misrepresented as being the original software.
#
#   3. This notice may not be removed or altered from any source
#   distribution.
#
#[The zlib/libpng License http://opensource.org/licenses/Zlib]
###############################################################################

# Usage:
# gem install parslet するか、
# bundler で Gemfile に gem 'parslet' を書いて
# bundle install して bundle exec で利用してください
require 'parslet'

class TKSParser < Parslet::Parser

  attr_accessor :script_prefix
  attr_accessor :comment_prefix
  attr_accessor :inline_command_open
  attr_accessor :inline_command_close
#  attr_reader :indent_mode
  attr_reader :indent_width

  def initialize(
#    indent_mode: :spaces, #インデントモード
    indent_width: 2, #インデントの空白文字数単位
    script_prefix: "@", #スクリプト行接頭字
    comment_prefix: ["//"], #コメント行接頭字
    inline_command_open: "[", #インラインコマンドプレフィクス
    inline_command_close: "]" #インラインコマンドポストフィクス
  )
    super()
#    @indent_mode = indent_mode
    @indent_width = indent_width
    @script_prefix = script_prefix
    @comment_prefix = comment_prefix
    @inline_command_open = inline_command_open
    @inline_command_close = inline_command_close
  end

  rule(:space)  { match('\s').repeat(1) }
  rule(:space?) { space.maybe }

  rule(:integer) { match('[0-9]').repeat(1).as(:int) }

  #既読ラベル
  rule(:label){
    str("*") >>
    space? >>
    label_node >>
    str(" ").repeat(0) >> newline
  }

  rule(:label_node){
    match('[a-zA-Z0-9_]').repeat(1).as(:chapter) >> space? >> match('[0-9]').repeat(1).as(:id) |
    match('[a-zA-Z0-9_]').repeat(1).as(:chapter)
  }

  #インデント
  rule(:indent) { 
#    str(indent_char) 
    #タブor指定文字数の半角空白をインデントと定義する
    str("\t") | 
    str(" " * @indent_width)
  }

  rule(:eof) { any.absent? }

  #改行
  rule(:newline) { 
    str("\n") 
  }

  #コマンドブロック
  rule(:command) {
    ( str(script_prefix) | indent) >> #スクリプト行接頭字orインデント
    (newline.absent? >> any).repeat(0).as(:command_line) >>
    (newline | eof)#改行
  }

  #textコマンドブロック
  rule(:printable) {
      #１個以上のインラインコマンドor文字列集合
      ( inline_data | 
        inline_command | 
        text ).repeat(1).as(:text_line) >> 
      (newline | eof)#改行
  }

  #文字列
  #インラインコマンド接頭字or改行までの１文字以上
  rule(:text) {
    (
      str(inline_command_open).absent? >> newline.absent? >> any
    ).repeat(1).as(:text_node) 
  }

  #インラインコマンド
  rule(:inline_command) {
    #インラインコマンド接頭字
    str(inline_command_open) >> 
    #コマンド文字列
    ( 
      #先頭`=`不可
      str('=').absent? >>
      #任意のエスケープシーケンス文字（ex. "\["）
      str('\\') >> any | 
      #配列
      array |
      #インラインコマンド接尾字以外の任意一文字
      str(inline_command_close).absent? >> any
      
    ).repeat.as(:inline_command_node) >> 
    #インラインコマンド接尾字
    str(inline_command_close) 
  }

  #インラインデータ
  rule(:inline_data) {
    #インラインコマンド接頭字
    str('[') >> str('=') >> 
    #コマンド文字列
    ( 
      #任意のエスケープシーケンス文字（ex. "\["）
      str('\\') >> any | 
      #配列
      array |
      #インラインコマンド接尾字以外の任意一文字
      str(inline_command_close).absent? >> any
      
    ).repeat.as(:inline_data_node) >> 
    #インラインコマンド接尾字
    str(inline_command_close) 
  }

  #配列表記
  rule(:array) {
    str('[') >> (array | (str(']').absent? >> any)).repeat >> str(']') 
  }

  #コメント
  rule(:comment) {
    #コメント行の第１候補をピックする
    first = _comment(comment_prefix.first)

    #comment_prefixの二つ目の要素から最後の要素までを巡回する
    #（初期値は"//"のみなので実行されない）
    comment_prefix[1..-1].inject(first) {|prev, str|
      #次点候補が該当するならそちらを採用とする
      prev | _comment(str)
    }
  }

  def _comment(comment_str)
    str(comment_str) >> #コメントプレフィクス
    match[' \t'].repeat >> #空白もしくはタブの繰り返し
    match['^\n'].repeat >> #改行までの０文字以上の文字列
    newline.as(:comment_line) #改行
  end

  #空行ブロック（テキストウィンドウの改ページの明示）
  rule(:blankline) { 
    #改行
    match['$\n'].as(:flush)
  }

  rule(:node) { 
    ( comment | 
      command | 
      printable) 
  }

  rule(:document) { 
    ( blankline | 
      label | 
      node).repeat.as(:output)
  }

  root(:document)

  class Replacer < Parslet::Transform

    #シナリオラベル
    rule(
      :chapter => simple(:chapter), :id => simple(:id)
    ) { 
      "end;" + 
      "_LABEL_ chapter: :#{chapter}, id: #{id} do;"
    }

    #シナリオラベル（id無し）
    rule(
      :chapter => simple(:chapter)
    ) { 
      "end;" + 
      "_LABEL_ chapter: :#{chapter} do;"
    }

    #コメント行→無視
    rule(
      :comment_line => simple(:target)
    ) {  }

    #コマンド行→そのまま返す
    rule(
      :command_line => simple(:target)
    ) {
      target.to_s + "\n"
    }

    #コマンド行→そのまま返す
    rule(
      :command_line => sequence(:target)
    ) {
      target.join
    }

    #テキストノード→textコマンド
    rule(
      :text_node => simple(:target)
    ) {
      text = "#{target}".gsub(/"/, '\"')
  "_GET_ :_DEFAULT_TEXT_PAGE_ do |_DEFAULT_TEXT_PAGE_:|;"+
  "  _SEND_ _DEFAULT_TEXT_PAGE_ do;" + 
      %Q'_TEXT_ "#{text}"' +
  "  end;" + 
  "end;" 
    }

    #インラインコマンド→そのまま返す
    rule(
      :inline_command_node => simple(:target)
    ) { 
      target.to_s + ";"
    }

    #インラインデータ→textコマンド
    rule(
      :inline_data_node => simple(:target)
    ) {
  "_GET_ :_DEFAULT_TEXT_PAGE_ do |_DEFAULT_TEXT_PAGE_:|;"+
  "  _SEND_ _DEFAULT_TEXT_PAGE_ do;" + 
       "_TEXT_ " + target.to_s +
  "  end;" + 
  "end;" 
    }

    #text行→末端に改行コード追加
    rule(
      :text_line => sequence(:target)
    ) { 
      target.join + 
  "_GET_ :_DEFAULT_TEXT_PAGE_ do |_DEFAULT_TEXT_PAGE_:|;"+
  "  _SEND_ _DEFAULT_TEXT_PAGE_ do;" + 
  "    _LINE_FEED_;" + 
  "  end;" + 
  "end\n" 
    }

    rule(
      :output => sequence(:target)
    ) { 
      "_LABEL_ chapter: :_TKS_ do;" + 
      target.join + ";" +
      "end;"
    }

    #空行ブロック→キー入力待ちコマンド追加
    rule(
      :flush => simple(:target)
    ) { 
  "_GET_ :_DEFAULT_TEXT_PAGE_ do |_DEFAULT_TEXT_PAGE_:|;"+
  "  _SEND_ _DEFAULT_TEXT_PAGE_ do;" + 
  "    _FLUSH_;" + 
  "  end;" + 
  "end\n" 
    }
  end
end


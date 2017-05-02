#! ruby -E utf-8
# coding: utf-8

#$VERBOSE = true

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

require_relative './Clickable.rb'

module Tsukasa

class Window < Layout
  #マウスカーソルがウィンドウの外に出たかを判定するため、Clickableをmix-inする
  include Clickable

  attr_accessor :auto_close #「閉じる」ボタンが押下された際に自動的に終了する
  attr_accessor :inactive_pause #非アクティブ時に更新処理を停止するかどうか

  #ウィンドウ座標上のマウスＸ座標
  attr_reader :mouse_x
  def mouse_x=(arg)
    @_INPUT_API_.set_mouse_pos(arg, @_INPUT_API_.mouse_y)
    @mouse_x = arg
  end

  #ウィンドウ座標上のマウスＸ座標前フレームからの増分
  attr_accessor :mouse_offset_x

  #ウィンドウ座標上のマウスＹ座標
  attr_reader :mouse_y
  def mouse_y=(arg)
    @_INPUT_API_.set_mouse_pos(@_INPUT_API_.mouse_x, arg)
    @mouse_y = arg
  end

  #ウィンドウ座標上のマウスＸ座標前フレームからの増分
  attr_accessor :mouse_offset_y

  def mouse_wheel_pos()
    @_INPUT_API_.mouse_wheel_pos
  end
  def mouse_wheel_pos=(arg)
    @_INPUT_API_.mouse_wheel_pos = arg
  end

  #マウスカーソル可視フラグ
  def mouse_enable()
    @mouse_enable
  end
  def mouse_enable=(arg)
    @mouse_enable = arg
    @_INPUT_API_.mouse_enable = @mouse_enable
  end

  #フルスクリーン状態の取得／設定
  def full_screen()
    @_WINDOW_API_.full_screen?
  end
  def full_screen=(arg)
    @_WINDOW_API_.full_screen = arg
  end

  #フルスクリーン時に使用可能な解像度
  #[[width, height, refreshrate], ...]
  def screen_modes()
    @_WINDOW_API_.get_screen_modes
  end

  #タイトルバーに表示する文字列
  def caption()
    @_WINDOW_API_.caption
  end
  def caption=(arg)
    @_WINDOW_API_.caption = arg
  end

  #フレーム更新時のリセット背景色
  def bgcolor()
    @_WINDOW_API_.bgcolor
  end
  def bgcolor=(arg)
    @_WINDOW_API_.bgcolor = arg
  end

  #タイトルバーに表示するアイコン
  def icon_path()
    @icon_path
  end
  def icon_path=(arg)
    @icon_path = arg
    @_WINDOW_API_.load_icon(arg)
  end

  #マウスカーソルの形状
  def cursor_type()
    @cursor_type
  end
  def cursor_type=(arg)
    @cursor_type = arg
    @_INPUT_API_.set_cursor(arg) 
  end

  def initialize(system = [nil, nil, nil],
                 _INPUT_API_: DXRuby::Input, 
                 _WINDOW_API_: DXRuby::Window, 
                 shape: [0,0],
                 **options, 
                 &block)
    #ベースオブジェクト
    @_INPUT_API_ = _INPUT_API_
    @_WINDOW_API_ = _WINDOW_API_

    #アプリ終了フラグ
    @close = false
    #「閉じる」ボタンが押下された場合自動終了する
    @auto_close = options[:auto_close] || true
    #非アクティブ時に更新処理を行うかどうか
    @inactive_pause = true

    @mouse_x = 0
    @mouse_y = 0

    #マウスカーソル可視フラグ
    self.mouse_enable = options[:mouse_enable] || true
    #タイトルバーに表示するアイコン
    self.caption = options[:caption] || "Tsukasa Engine powered by DXRuby"
    #フレーム更新時のリセット背景色
    self.bgcolor = options[:bgcolor] || [0,0,0]
    #タイトルバーに表示するアイコン
    @icon_path = nil
    if options[:icon_path]
      self.icon_path = options[:icon_path]
    end
    #マウスカーソルの形状
    self.cursor_type = options[:cursor_type] || IDC_ARROW
    super
  end

  def update(absolute_x, absolute_y)
    #「閉じる」ボタンが押下された
    if @_INPUT_API_.requested_close? and @auto_close
      set_exit()
    end

    #マウスのオフセット増分と座標を保存
    @mouse_offset_x = @_INPUT_API_.mouse_x - @mouse_x
    @mouse_x = @_INPUT_API_.mouse_x

    @mouse_offset_y = @_INPUT_API_.mouse_y - @mouse_y
    @mouse_y = @_INPUT_API_.mouse_y

    #windowがアクティブで無ければ子コントロールを動作せずに終了
    return  unless @_WINDOW_API_.active? and @inactive_pause

    super

    #カーソルが画面外に出た時／戻った時にカーソル可視状態を復帰する
    #※ウィンドウ枠に出た時に標準カーソルを表示させるために必要
    if @on_inner_control
      @_INPUT_API_.mouse_enable = false unless @mouse_enable
    else
      @_INPUT_API_.mouse_enable = true unless @mouse_enable
    end
  end

  #ウィンドウの閉じるボタンが押されたかどうかの判定
  def _CHECK_REQUESTED_CLOSE_(**)
    #「閉じる」ボタンが押下された
    if @_INPUT_API_.requested_close?
      unshift_command_block()
    end
  end

  def _RESIZE_(width:, height:)
    @_WINDOW_API_.resize(width, height)
    self.shape = [ 0, 0, width, height]
  end
end

end

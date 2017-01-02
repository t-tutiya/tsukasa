#! ruby -E utf-8
# coding: utf-8

#$VERBOSE = true

###############################################################################
#TSUKASA for DXRuby ver2.1(2016/12/23)
#メッセージ指向ゲーム記述言語「司エンジン（Tsukasa Engine）」 for DXRuby
#
#Copyright (c) <2013-2016> <tsukasa TSUCHIYA>
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

require_relative './ClickableLayout.rb'

module Tsukasa

class Window < ClickableLayout
  attr_accessor :auto_close #「閉じる」ボタンが押下された際に自動的に終了する

  #ウィンドウ座標上のマウスＸ座標
  def mouse_x()
    return DXRuby::Input.mouse_x
  end
  def mouse_x=(arg)
    DXRuby::Input.set_mouse_pos(arg, DXRuby::Input.mouse_y)
  end

  #ウィンドウ座標上のマウスＹ座標
  def mouse_y()
    return DXRuby::Input.mouse_y
  end
  def mouse_y=(arg)
    DXRuby::Input.set_mouse_pos(DXRuby::Input.mouse_x, arg)
  end

  def mouse_wheel_pos()
    DXRuby::Input.mouse_wheel_pos
  end
  def mouse_wheel_pos=(arg)
    DXRuby::Input.mouse_wheel_pos = arg
  end

  #マウスカーソル可視フラグ
  def mouse_enable()
    @mouse_enable
  end
  def mouse_enable=(arg)
    @mouse_enable = arg
    DXRuby::Input.mouse_enable = @mouse_enable
  end

  #フルスクリーン状態の取得／設定
  def full_screen()
    DXRuby::Window.full_screen
  end
  def full_screen=(arg)
    DXRuby::Window.full_screen = arg
  end

  #フルスクリーン時に使用可能な解像度
  #[[width, height, refreshrate], ...]
  def screen_modes()
    DXRuby::Window.get_screen_modes
  end

  #タイトルバーに表示する文字列
  def caption()
    DXRuby::Window.caption
  end
  def caption=(arg)
    DXRuby::Window.caption = arg
  end

  #フレーム更新時のリセット背景色
  def bgcolor()
    DXRuby::Window.bgcolor
  end
  def bgcolor=(arg)
    DXRuby::Window.bgcolor = arg
  end

  #タイトルバーに表示するアイコン
  def icon_path=(arg)
    @icon_path
  end
  def icon_path=(arg)
    @icon_path = arg
    DXRuby::Window.load_icon(arg)
  end

  #マウスカーソルの形状
  def cursor_type()
    @cursor_type
  end
  def cursor_type=(arg)
    @cursor_type = arg
    DXRuby::Input.set_cursor(arg) 
  end

  def initialize( options = {}, 
                  yield_stack = nil, 
                  root_control = nil, 
                  parent_control = nil)
    #アプリ終了フラグ
    @close = false
    #「閉じる」ボタンが押下された場合自動終了する
    @auto_close = options[:auto_close] || true

    #マウスカーソル可視フラグ
    self.mouse_enable = options[:mouse_enable] || true
    #タイトルバーに表示するアイコン
    self.caption = options[:caption] || "Tsukasa Engine powered by DXRuby"
    #フレーム更新時のリセット背景色
    self.bgcolor = options[:bgcolor] || [0,0,0]
    #タイトルバーに表示するアイコン
    if options[:icon_path]
      self.icon_path = options[:icon_path]
    end
    #マウスカーソルの形状
    self.cursor_type = options[:cursor_type] || IDC_ARROW
    super
  end

  def update(mouse_pos_x, mouse_pos_y, index)
    #「閉じる」ボタンが押下された
    if DXRuby::Input.requested_close? and @auto_close
      @root_control.exit = true
    end

    super

    #カーソルが画面外に出た時／戻った時にカーソル可視状態を復帰する
    #※ウィンドウ枠に出た時に標準カーソルを表示させるために必要
    if @on_inner_control
      DXRuby::Input.mouse_enable = false unless @mouse_enable
    else
      DXRuby::Input.mouse_enable = true unless @mouse_enable
    end
  end

  #ウィンドウの閉じるボタンが押されたかどうかの判定
  def _CHECK_REQUESTED_CLOSE_(yield_stack, options = nil, &block)
    #「閉じる」ボタンが押下された
    if DXRuby::Input.requested_close?
      shift_command_block(nil, yield_stack, &block)
    end
  end

  def _RESIZE_(yield_stack, width:, height:)
    DXRuby::Window.resize(width, height)
    super
  end
end

end

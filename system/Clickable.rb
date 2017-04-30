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

require_relative './Layoutable.rb'

module Tsukasa

module Clickable
  include Layoutable

  #コリジョンの配列指定
  #[x, y]                    1ピクセルの点
  #[x, y, r]                 中心(x, y)から半径rのサイズの円
  #[x1, y1, x2, y2]          左上(x1, y1)と右下(x2, y2)を結ぶ矩形
  #[x1, y1, x2, y2, x3, y3]  (x1, y1)～(x2, y2)～(x3, y3)を結ぶ三角形
  attr_reader :shape
  def shape=(arg)
    @shape = arg
    @collision_sprite.collision = @shape
  end

  attr_reader  :cursor_x
  attr_reader  :cursor_y
  attr_accessor  :colorkey_id
  attr_accessor  :colorkey_border

  def check_imple(condition, value)
    case condition
    when :collision
      Array(value).any? do |key|
        case key
        when :cursor_on
          @on_inner_control
        when :cursor_off
          !(@on_inner_control)
        #カーソルが指定範囲に侵入した場合
        when :cursor_over
          @on_mouse_over
        #カーソルが指定範囲の外に移動した場合
        when :cursor_out
          @on_mouse_out
        #マウスボタンが押下された場合
        when :key_push
          @on_key_push
        #マウスボタンが継続押下されている合
        when :key_down
          @on_key_down
        #マウスボタンが範囲外で押下された場合
        when :key_down_out
          @on_key_down_out
        #マウスボタン押下が解除された場合
        when :key_up
          @on_key_up
        #マウスボタン押下が範囲外で解除された場合
        when :key_up_out
          @on_key_up_out
        #マウス右ボタンが押下された場合
        when :right_key_push
          @on_right_key_push
        #マウス右ボタンが継続押下されている場合
        when :right_key_down
          @on_right_key_down
        #マウスボタンが範囲外で押下された場合
        when :right_key_down_out
          @on_right_key_down_out
        #マウスボタン押下が解除された場合
        when :right_key_up
          @on_right_key_up
        #マウスボタン押下が範囲外で解除された場合
        when :right_key_up_out
          @on_right_key_up_out
        else
          false
        end
      end 
    else
      super
    end
  end

  def initialize( system, 
                  _INPUT_API_: DXRuby::Input,
                  _SPRITE_API_: DXRuby::Sprite,
                  **options, 
                  &block)
    #ベースクラス
    @_INPUT_API_ = _INPUT_API_
    #カラーキー
    @colorkey_id = options[:colorkey_id]
    #カラーキーボーダー
    @colorkey_border = options[:colorkey_border] || 255

    #コリジョン形状の指定
    @shape = options[:shape] || [0,0]

    #コントロールSprite初期化
    @collision_sprite = _SPRITE_API_.new
    @collision_sprite.collision = @shape

    #コリジョン図形の位置を補正
    @collision_sprite.x = 0
    @collision_sprite.y = 0

    #カーソルSprite初期化
    @mouse_sprite = _SPRITE_API_.new
    @mouse_sprite.collision = [0, 0]

    #カーソル座標がコントロール内にある
    @cursor_in  = false

    #コントロールに対するカーソルの相対座標
    @cursor_x = @cursor_y = 0
    super
  end

  #描画
  def update(mouse_pos_x, mouse_pos_y)
    @on_inner_control = false
    @on_mouse_over  = false
    @on_mouse_out   = false

    @on_key_push    = false
    @on_key_down    = false
    @on_key_down_out= false
    @on_key_up      = false
    @on_key_up_out  = false

    @on_right_key_push    = false
    @on_right_key_down    = false
    @on_right_key_down_out= false
    @on_right_key_up      = false
    @on_right_key_up_out  = false

    #カーソル座標を保存する
    @cursor_x = @mouse_sprite.x = mouse_pos_x - @x
    @cursor_y = @mouse_sprite.y = mouse_pos_y - @y

    #マウスカーソル座標との衝突判定
    if not (@mouse_sprite === @collision_sprite)
      #マウスカーソルがコリジョン範囲内に無い
      @on_inner_control = false
    elsif @colorkey_id and (
      child_control(@colorkey_id).entity[
        mouse_pos_x - @x, mouse_pos_y - @y][0] <= @colorkey_border)
      #マウスカーソルがコリジョン範囲内にあるがカラーキーボーダー内に無い
      @on_inner_control = false
    else
      #マウスカーソルがコリジョン範囲内にある
      @on_inner_control = true
    end

    if @on_inner_control
      #前フレームでカーソル座標がコントロール外だった場合
      unless @cursor_in
        #イベント発生
        @on_mouse_over = true 
        #フラグを立てる
        @cursor_in = true
      end

      #キー継続押下チェック
      @on_key_down = @_INPUT_API_.mouse_down?( M_LBUTTON )
      #キー押下チェック
      @on_key_push = @_INPUT_API_.mouse_push?( M_LBUTTON )
      #キー解除チェック
      @on_key_up = @_INPUT_API_.mouse_release?( M_LBUTTON )
      #キー継続押下チェック
      @on_right_key_down = @_INPUT_API_.mouse_down?( M_RBUTTON )
      #右キー押下チェック
      @on_right_key_push = @_INPUT_API_.mouse_push?( M_RBUTTON )
      #右キー解除チェック
      @on_right_key_up = @_INPUT_API_.mouse_release?( M_RBUTTON )
    else
      #前フレームでカーソル座標がコントロール内だった場合
      if @cursor_in
        #イベント発生
        @on_mouse_out = true 
        #フラグを下ろす
        @cursor_in = false
      end

      #キー押下チェック
      @on_key_down_out = @_INPUT_API_.mouse_down?( M_LBUTTON )
      #キー解除チェック
      @on_key_up_out = @_INPUT_API_.mouse_release?( M_LBUTTON )
      #右キー押下チェック
      @on_right_key_down_out = @_INPUT_API_.mouse_down?( M_RBUTTON )
      #右キー解除チェック
      @on_right_key_up_out = @_INPUT_API_.mouse_release?( M_RBUTTON )
    end

    return super
  end

end

end
#! ruby -E utf-8

require 'dxruby'

###############################################################################
#TSUKASA for DXRuby  α１
#汎用ゲームエンジン「司（TSUKASA）」 for DXRuby
#
#Copyright (c) <2013-2015> <tsukasa TSUCHIYA>
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

#クリックイベントが発生するコントロールの基底クラス
module Clickable

  attr_accessor  :collision_shape
  attr_accessor  :colorkey_border

  def collision_x=(args)
    @collision_sprite.x = args
  end

  def collision_y=(args)
    @collision_sprite.y = args
  end

  def colorkey=(arg)
    @colorkey = find_control(arg)[0]
  end

  def initialize(options, inner_options, root_control)
    super
    
    @collision_shape = options[:collision_shape]
    
    self.colorkey = options[:colorkey] if options[:colorkey]

    @collision_sprite = Sprite.new
    if @collision_shape
      @collision_sprite.collision = @collision_shape
    else
      @collision_sprite.collision = [0, 0, @width-1, @height-1]
    end

    self.collision_x = options[:collision_x] || 0
    self.collision_y = options[:collision_y] || 0

    @mouse_sprite = Sprite.new
    @mouse_sprite.collision = [0, 0]

    @over = false
    @out = true

    @old_cursol_x = @old_cursol_y = nil
  end

  def update()
    @on_mouse_over  = false
    @on_mouse_out   = false

    @on_key_down    = false
    @on_key_down_out= false
    @on_key_up      = false
    @on_key_up_out  = false

    @on_right_key_down    = false
    @on_right_key_down_out= false
    @on_right_key_up      = false
    @on_right_key_up_out  = false

    #マウスカーソル座標を取得
    @mouse_sprite.x = @cursol_x = Input.mouse_pos_x
    @mouse_sprite.y = @cursol_y = Input.mouse_pos_y

    #前フレームと座標が異なる場合on_mouse_moveイベントを実行する
    @on_mouse_move = (@old_cursol_x != @cursol_x)or(@old_cursol_y != @cursol_y)

    #カーソル座標を保存する
    @old_cursol_x = @cursol_x
    @old_cursol_y = @cursol_y

    #マウスカーソルがコリジョン範囲内に無い
    if not (@mouse_sprite === @collision_sprite)
      inner_control = false
    #マウスカーソルがコリジョン範囲内にあるがカラーキーボーダー内に無い
    elsif @colorkey and (@colorkey.entity[@cursol_x - @x, @cursol_y - @y][0] < @colorkey.border)
      inner_control = false
    #マウスカーソルがコリジョン範囲内にある
    else
      inner_control = true
    end

    if inner_control
      #イベント起動済みフラグクリア
      @out = false

      #イベント起動前であれば起動し、クリアフラグを立てる
      @on_mouse_over = true unless @over
      @over = true

      #キー押下チェック
      if Input.mouse_push?( M_LBUTTON )
        @on_key_down = true
      end

      #キー解除チェック
      if Input.mouse_release?( M_LBUTTON )
        @on_key_up = true
      end

      #右キー押下チェック
      if Input.mouse_push?( M_RBUTTON )
        @on_right_key_down = true
      end

      #右キー解除チェック
      if Input.mouse_release?( M_RBUTTON )
        @on_right_key_up = true
      end

    else
      #イベント起動済みフラグクリア
      @over = false

      #イベント起動前であれば起動し、クリアフラグを立てる
      @on_mouse_out = true unless @out
      @out = true

      #キー押下チェック
      if Input.mouse_push?( M_LBUTTON )
        @on_key_down_out = true
      end

      #キー解除チェック
      if Input.mouse_release?( M_LBUTTON )
        @on_key_up_out = true
      end

      #右キー押下チェック
      if Input.mouse_push?( M_RBUTTON )
        @on_right_key_down_out = true
      end

      #右キー解除チェック
      if Input.mouse_release?( M_RBUTTON )
        @on_right_key_up_out = true
      end
    end

    super
  end

  def command_on_mouse_move(options, inner_options)
    #前フレと比較してカーソルが移動した場合
    if @on_mouse_move
      eval_block( {:_X_ => @cursol_x, :_Y_ => @cursol_y}, 
                  inner_options[:block_stack], 
                  &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_mouse_move, options, inner_options)
  end

  def command_on_mouse_over(options, inner_options)
    #カーソルが指定範囲に侵入した場合
    if @on_mouse_over
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_mouse_over, options, inner_options)
  end
  
  def command_on_mouse_out(options, inner_options)
    #カーソルが指定範囲の外に移動した場合
    if @on_mouse_out
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_mouse_out, options, inner_options)
  end

  def command_on_key_down(options, inner_options)
    #マウスボタンが押下された場合
    if @on_key_down
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_key_down, options, inner_options)
  end

  def command_on_key_down_out(options, inner_options)
    #マウスボタンが範囲外で押下された場合
    if @on_key_down_out
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_key_down_out, options, inner_options)
  end

  def command_on_key_up(options, inner_options)
    #マウスボタン押下が解除された場合
    if @on_key_up
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_key_up, options, inner_options)
  end

  def command_on_key_up_out(options, inner_options)
    #マウスボタン押下が範囲外で解除された場合
    if @on_key_up_out
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_key_up_out, options, inner_options)
  end

  def command_on_right_key_down(options, inner_options)
    #マウスボタンが押下された場合
    if @on_right_key_down
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_right_key_down, options, inner_options)
  end

  def command_on_right_key_down_out(options, inner_options)
    #マウスボタンが範囲外で押下された場合
    if @on_right_key_down_out
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_right_key_down_out, options, inner_options)
  end

  def command_on_right_key_up(options, inner_options)
    #マウスボタン押下が解除された場合
    if @on_right_key_up
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_right_key_up, options, inner_options)
  end

  def command_on_right_key_up_out(options, inner_options)
    #マウスボタン押下が範囲外で解除された場合
    if @on_key_right_up_out
      eval_block(options, inner_options[:block_stack], &inner_options[:block])
    end
    #イベントコマンドはコマンドリストに残り続ける
    push_command_to_next_frame(:on_right_key_up_out, options, inner_options)
  end
end

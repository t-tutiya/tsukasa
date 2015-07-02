#! ruby -E utf-8

require 'dxruby'
require_relative './module_movable.rb'
require_relative './module_drawable.rb'
require_relative './control_container.rb'

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

#ＳＥコントロール
class SEControl  < Control

  def initialize(options, system_options)
    super

    #イメージの読み込み
    @control = Sound.new(options[:file_path])
    #ループの設定（true=ループする）
    @control.loop_count = options[:loop] ? -1 : 0
  end

  def render(offset_x, offset_y, target)
    return offset_x, offset_y
  end

  #ＳＥの再生
  def command_se_play(options, target)
    @control.play
    return :continue #フレーム続行
  end

  #ＳＥの停止
  def command_se_stop(options, target)
    @control.stop
    return :continue #フレーム続行
  end

  def visible
    false
  end

end

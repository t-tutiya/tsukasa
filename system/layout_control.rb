#! ruby -E utf-8

require 'dxruby'

###############################################################################
#TSUKASA for DXRuby ver1.0(2015/12/24)
#メッセージ指向ゲーム記述言語「司エンジン（Tsukasa Engine）」 for DXRuby
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

class LayoutControl < Control
  include Layoutable
  include Clickable

  #描画
  def render(offset_x, offset_y, target, 
                                            width , 
                                            height , 
                                            mouse_pos_x,
                                            mouse_pos_y )
    #下揃えを考慮
    if @align_y == :bottom 
      offset_y += height - @height
    end

    return super( offset_x + @x + @offset_x,
                  offset_y + @y + @offset_y, 
                  target, 
                  width , 
                  height , 
                  mouse_pos_x,
                  mouse_pos_y )
  end

  def serialize(control_name = :LayoutControl, **options)
    return super(control_name, options)
  end

end

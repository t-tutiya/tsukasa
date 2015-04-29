#! ruby -E utf-8

###############################################################################
#TSUKASA for DXRuby α１
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

create :ImageControl ,
       file_path: "./sozai/bg_sample.png", x_po: 0, y_pos: 0, 
       id: :BG do
  move offset_x: 300,offset_y: 0, frame: 60, offset: true
  transition_fade frame: 200,
                  count: 0,
                  start: 0,
                  last: 255
  check_key_push
  wait_command :move_line
  move offset_x: -300, offset_y: 0, frame: 60, offset: true
end


#ボタンコントロール
create :ButtonControl, 
        :x_pos => 0, 
        :y_pos => 0, 
        :id=>:button1 do
  create :ImageControl, 
         :file_path=>"./sozai/button_normal.png", 
         :id=>:normal
  create :ImageControl, 
        :file_path=>"./sozai/button_over.png", 
        :id=>:over,
        :visible => false
  create :ImageControl, 
        :file_path=>"./sozai/button_key_down.png", 
        :id=>:key_down,
        :visible => false
  create :ImageControl, 
        :file_path=>"./sozai/button_key_up.png", 
        :id=>:key_up,
        :visible => false
  create :ImageControl, 
        :file_path=>"./sozai/button_out.png", 
        :id=>:out,
        :visible => false

  event :key_up do
    EVAL "pp 'pre_wait'"
    flag :key=>3, :data=>2
    flag :key=>4, :data=>true
  end
  normal
end

WHILE "true", target_control: :button1 do
  move_line x: 300, y: 0,   count:0, frame: 60, start_x: 0,   start_y: 0
  wait_command :move_line
  move_line x: 300, y: 300, count:0, frame: 60, start_x: 300, start_y: 0
  wait_command :move_line
  move_line x: 0,   y: 300, count:0, frame: 60, start_x: 300, start_y: 300
  wait_command :move_line
  move_line x: 0,   y: 0,   count:0, frame: 60, start_x: 0,   start_y: 300
  wait_command :move_line
end

wait_flag "3"

dispose :button1

pause

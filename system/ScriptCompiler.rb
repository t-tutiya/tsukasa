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

module Tsukasa

class ScriptCompiler

  def initialize()
    @command_list = []
  end

  def eval_commands(script, fname = "(eval)", yield_stack)
    @yield_stack = yield_stack
    @command_list.clear

    eval(script, nil, fname)

    return @command_list
  end

  def eval_block(block, yield_stack, options)
    raise unless block

    @yield_stack = yield_stack
    @command_list.clear

    self.instance_exec(options, &block)

    return @command_list
  end

  def method_missing(command_name, argument = nil, **options, &block)
    if command_name == :_END_FRAME_
      warn "warning: _END_FRAME_コマンドは非推奨です。_HALT_コマンドを使ってください"
      command_name = :_HALT_
    end

    #第１引数が設定されているならオプションに追加する
    unless nil == argument
      options[:_ARGUMENT_] = argument
    end

    #コマンド配列を登録する
    @command_list.push([command_name, 
                        options, 
                        block, 
                        @yield_stack.dup])
  end
end

end
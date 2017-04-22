#! ruby -E utf-8

require 'pstore'
require "tmpdir"

#キーコード定数／パッド定数／マウスボタン定数
require_relative './Constant.rb'
#例外（TskasaError）
require_relative './Exception.rb'
#スクリプトコンパイラ
require_relative './ScriptCompiler.rb'

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

class Control #公開インターフェイス
  #スクリプトパーサー
  @@script_compiler = ScriptCompiler.new
  @@script_parser = {}

  #プロセスのカレントディレクトリを保存する
  @@system_path = File.expand_path('../../', __FILE__)

  attr_accessor :id
  attr_accessor :child_update  #子コントロールの更新可否
  attr_reader  :function_list #ユーザー定義関数

  attr_reader :exit #終了

  #system = [root_control, parent_control, yield_stack]
  def initialize(system = [nil, nil, nil], options = {}, &block)
    #rootコントロールの保存
    @root_control = system[0] || self
    #親コントロールの保存
    @parent_control = system[1]
    #_YIELD_用ブロックのスタックリスト
    @temporary_yield_stack = Array(system[2])

    #子コントロールの更新実行可能フラグ
    @child_update = true
    #ユーザ定義コマンド格納ハッシュ
    @function_list = {} 
    #コントロールのID(省略時は自身のクラス名とする)
    @id = options[:id] || self.class.name.to_sym
    #コマンドリスト
    @command_list = [] 
    #コントロールリスト
    @control_list = [] 
    #削除フラグ
    @delete_flag = false 
    #終了フラグ
    @exit = false

    #ブロックが付与されているなら読み込んで登録する
    @temporary_command_block = block
    if @temporary_command_block
      unshift_command_block(options)
    end
  end

  #コマンドをスタックの先頭に挿入する
  def unshift_command(command, 
                      command_block = @temporary_command_block,
                      yield_stack = @temporary_yield_stack,
                      **options, 
                      &block)
    @command_list.unshift([ command, 
                            options,
                            command_block ? command_block : block, 
                            yield_stack ])
  end

  #コマンドをスタックの末端に挿入する
  def push_command( command, 
                    command_block = @temporary_command_block,
                    yield_stack = @temporary_yield_stack,
                    **options, 
                    &block)
    @command_list.push([command, 
                        options,
                        command_block ? command_block : block, 
                        yield_stack])
  end

  #コマンド配列をスタックの先頭に挿入する
  def unshift_command_array(command_array)
    @command_list = command_array + @command_list
  end

  #コマンド配列をスタックの末尾に挿入する
  def push_command_array(command_array)
    @command_list += command_array
  end

  #ブロックをパースしてコマンド配列化し、コマンドリストの先頭に挿入する
  def unshift_command_block(command_block = @temporary_command_block,
                            yield_stack = @temporary_yield_stack,
                            **options)
    @command_list = 
      @@script_compiler.eval_block(command_block, yield_stack, options) + 
      @command_list
  end

  #ブロックをパースしてコマンド配列化し、コマンドリストの末尾に挿入する
  def push_command_block( command_block = @temporary_command_block,
                          yield_stack = @temporary_yield_stack,
                          **options)
    @command_list += 
      @@script_compiler.eval_block(command_block, yield_stack, options)
  end
end

class Control
  def update(mouse_pos_x, mouse_pos_y)
    #コマンドリストが空になるまで走査し、コマンドを実行する
    until @command_list.empty?
      #コマンドリストの先頭要素を取得
      command_name, 
      options, 
      @temporary_command_block, 
      @temporary_yield_stack = @command_list.shift
      #今フレーム処理終了判定
      break if command_name == :_HALT_
      #コマンドを実行する
      exec_command(command_name, options)
    end

    #子コントロールを更新しない場合は処理を終了
    return unless @child_update

    #下位コントロール巡回
    @control_list.delete_if do |child_control|
      #下位コントロールを自ターゲットに直接描画
      child_control.update(mouse_pos_x, mouse_pos_y)
      #コントロールの削除チェック
      child_control.delete?
    end
  end

  #描画
  def render(offset_x, offset_y, target)
    #下位コントロール巡回
    @control_list.each do |child_control|
      #下位コントロールを自ターゲットに直接描画
      child_control.render(offset_x, offset_y, target)
    end
  end
end

class Control
  def child_control(id)
    #idがnilであれば自身を返す
    return self unless id
    #整数であれば子要素の添え字と見なす
    return @control_list[id] if id.instance_of?(Fixnum)
    #_ROOT_：ルートコントロール
    return @root_control if id == :_ROOT_
    #_PARENT_：親コントロール
    return @parent_control if id == :_PARENT_
    #直下の子コントロールを探査して返す。存在しなければnil
    return @control_list.find {|control| control.id == id }
  end

  def find_control(control_path)
    control = self
    Array(control_path).each do |control_id|
      control = control.child_control(control_id)
      break unless control
    end

    #候補が見つからなかった場合
    unless control
      warn "コントロール\"#{control_path}\"は存在しません"
    end
    
    return control
  end

  #コントロールを削除して良いかどうか
  def delete?
    return @delete_flag
  end

  #リソースを解放する
  def dispose
    @delete_flag = true
    @control_list.each do |child_control|
      child_control.dispose
    end
    @control_list.clear
    @command_list.clear
  end

  def serialize()
    options = {}

    #自コントロールのプロパティを取得
    methods.each do |method|
      method = method.to_s
      if method[-1] == "=" and not(["===", "==", "!="].index(method))
        options[method.chop!.to_sym] = send(method)
      end
    end

    #自身を再構築する_SET_コマンドを生成
    command_list = [[:_SET_, options]]

    #子コントロールのシリアライズコマンドを取得
    @control_list.each do |control|
      command_list.push([:_CREATE_, {_ARGUMENT_: control.class.name}])
      command_list.push([:_SERIALIZE_, {_ARGUMENT_: control.serialize(), 
                                        control: -1}])
    end

    return command_list
  end

  #終了フラグを立てる
  def set_exit()
    @exit = true
    #親コントロールに伝搬する
    unless self == @root_control
      @parent_control.set_exit()
    end
  end
end

class Control #判定系

  def check_imple(condition, value)
    case condition
    #指定されたデータと値がイコールの場合
    when :equal
      value.any?{|key, val| send(key) == val}
    #指定されたデータと値がイコールでない場合
    when :not_equal
      value.any?{|key, val| send(key) != val}
    #指定されたデータと値が未満の場合
    when :under
      value.any?{|key, val| send(key) < val}
    #指定されたデータと値がより大きい場合
    when :over
      value.any?{|key, val| send(key) > val}
    else
      false
    end
  end
end

class Control #内部メソッド

  #############################################################################
  #非公開インターフェイス
  #############################################################################

  private

  def command_block?()
    @temporary_command_block
  end

  #コマンドの実行
  def exec_command(command_name, options)
    #コマンドがメソッドとして存在する場合
    if self.respond_to?(command_name, true)
      #コマンドを実行する
      send(command_name, options)
      return
    end

    #関数名に対応する関数ブロックを取得する
    function_block =  @function_list[command_name] || 
                      @root_control.function_list[command_name]

    #ユーザー定義コマンドが存在しない場合、例外送出する
    unless function_block
      raise(Tsukasa::TsukasaError, "コマンド[#{command_name}]は#{self.class.name}コントロール [#{@id}]に登録されていません")
    end

    #終端コマンドを挿入
    unshift_command(:_END_FUNCTION_)

    #スタックプッシュ
    @temporary_yield_stack.push(@temporary_command_block)
    @temporary_command_block = function_block

    #functionを実行時評価しコマンド列を生成する。
    unshift_command_block(options)
  end
end

class Control #コントロールの生成／破棄
  #コントロールをリストに登録する
  def _CREATE_(_ARGUMENT_:, **options)
    #コントロールを生成して子要素として登録する
    @control_list.push(
      #名前空間Tsukasa内のクラスを生成する
      Tsukasa.const_get(_ARGUMENT_).new([ @root_control, 
                                          self,
                                          @temporary_yield_stack], 
                                        options, 
                                        &@temporary_command_block)
    )
  #NoMethodError(NameErrorの派生クラス)をすくい取る
  rescue NoMethodError => e
    raise e
  rescue NameError => e
    puts "エラー：コントロール[#{_ARGUMENT_}]の生成に失敗しました。コントロールクラスが定義されていないか、生成するクラス名が間違っています"
    raise e
  end

  #コントロールを削除する
  def _DELETE_(_ARGUMENT_: nil)
    #コントロールを検索する
    control = find_control(_ARGUMENT_)

    #削除フラグを立てる
    control.dispose() if control
  end

  #ユーザー定義コマンドを定義する
  def _DEFINE_(_ARGUMENT_:)
    @function_list[_ARGUMENT_] = @temporary_command_block
  end

  #プロパティを動的に追加する
  def _DEFINE_PROPERTY_(options)
    #ハッシュを巡回
    options.each do |key, value|
      #インスタンス変数を動的に生成し、値を設定する
      instance_variable_set('@' + key.to_s, value)
      
      #ゲッターメソッドを動的に生成する
      singleton_class.send( :define_method, 
                            key,
                            lambda{ 
                              instance_variable_get('@' + key.to_s) 
                            })
      
      #セッターメソッドを動的に生成する
      singleton_class.send( :define_method, 
                            key.to_s + '=', 
                            lambda{ |set_value| 
                              instance_variable_set('@' + key.to_s, set_value) 
                            })
    end
  end

  #ユーザー定義コマンドの別名を作る
  def _ALIAS_(new_name:, original_name:)
    @function_list[new_name] = @function_list[original_name]
  end

  #関数ブロックを実行する
  def _YIELD_(**options)
    @temporary_command_block = @temporary_yield_stack.pop
    raise unless @temporary_command_block

    unshift_command_block(options)
  end
end

class Control #セッター／ゲッター
  #コントロールのプロパティを更新する
  def _SET_(_ARGUMENT_: nil, **options)
    #オプション全探査
    options.each do |key, val|
      begin
        #コントロールプロパティに値を代入
        find_control(_ARGUMENT_).send(key.to_s + "=", val)
      rescue
        warn  "クラス[#{self.class}]：プロパティ[" + "#{key}]は存在しません"
      end
    end
  end

  #指定したコントロール(orデータストア)のプロパティを取得する
  def _GET_(_ARGUMENT_:, control: nil)
    result = {}

    #オプション全探査
    Array(_ARGUMENT_).each do |property|
      property = Array(property)
      #取得先コントロールパスが指定されていなければcontrolに準じる
      property[1] = control unless property[1]
      #格納名が指定されていなければpropetyに準じる
      property[2] = property[0] unless property[2]
      begin
        #コントロールプロパティから値を取得する
        result[property[2]] = find_control(property[1]).send(property[0])
      rescue
        warn  "クラス[#{find_control(property[1]).class}]：プロパティ[" + "#{property[0]}]は存在しません"
      end
    end

    #ブロックを実行する
    unshift_command_block(result)
  end
end

class Control #制御構文
  #条件判定
  def _CHECK_(_ARGUMENT_: nil, **options)
    #対象のコントロールがチェック条件を満たす場合
    if options.any?{|condition, value| 
        find_control(_ARGUMENT_).check_imple(condition, value)
       }
      #ブロックを実行する
      unshift_command_block()
    end
  end

  def _CHECK_BLOCK_(**)
    #yield呼び出し可能なブロックがあるかを判定する
    unless @temporary_yield_stack[-1] == nil
      #条件が成立したらブロックを実行する
      unshift_command_block()
    end
  end

  #繰り返し
  def _LOOP_(_ARGUMENT_: nil) 
    if _ARGUMENT_
      _ARGUMENT_ = Array(_ARGUMENT_)
      
      #現在の経過カウントを初期化
      _ARGUMENT_[1] ||= 0
      #カウントが終了しているならループを終了する
      return if _ARGUMENT_[0] == _ARGUMENT_[1]
      #カウントアップ
      _ARGUMENT_[1] += 1

      args = {end: _ARGUMENT_[0], now: _ARGUMENT_[1]}
    else
      args = {}
    end

    #リストの先端に自分自身を追加する
    unshift_command(:_LOOP_, {_ARGUMENT_: _ARGUMENT_})
    #現在のループ終端を挿入
    unshift_command(:_END_LOOP_)
    #ブロックを実行時評価しコマンド列を生成する。
    unshift_command_block(args)
  end

  def _NEXT_(**)
    #_END_LOOP_タグが見つかるまで@command_listからコマンドを取り除く
    #_END_LOOP_タグが見つからない場合は@command_listを空にする
    until @command_list.empty? do
      break if @command_list.shift[0] == :_END_LOOP_ 
    end
  end

  def _BREAK_(**)
    #_END_LOOP_タグが見つかるまで@command_listからコマンドを取り除く
    #_END_LOOP_タグが見つからない場合は@command_listを空にする
    until @command_list.empty? do
      if @command_list.shift[0] == :_END_LOOP_ 
        #再スタックされている_LOOP_ブロックを削除する
        @command_list.shift 
        break 
      end
    end
  end

  def _RETURN_(**)
    #_END_FUNCTION_タグが見つかるまで@command_listからコマンドを取り除く
    #_END_FUNCTION_タグが見つからない場合は@command_listを空にする
    until @command_list.empty? do
      break if @command_list.shift[0] == :_END_FUNCTION_ 
    end

    #ブロックが付与されているならそれを実行する
    if command_block?
      unshift_command_block()
    end
  end
end

class Control #スクリプト制御
  #カスタムパーサーの登録
  def _SCRIPT_PARSER_(path:, ext_name:, parser:)
    require_relative path
    @@script_parser[ext_name] = [
      Module.const_get(parser).new,
      Module.const_get(parser)::Replacer.new]
  end

  #子コントロールを検索してコマンドブロックを送信する
  def _SEND_(_ARGUMENT_: nil, interrupt: nil, **options)
    #コントロールを検索する
    control = find_control(_ARGUMENT_)
    return unless control

    #インタラプト指定されている
    if interrupt
      #子コントロールのコマンドリスト先頭に挿入
      control.unshift_command_block(@temporary_command_block, 
                                    @temporary_yield_stack, 
                                    options)
    else
      #子コントロールのコマンドリスト末端に挿入
      control.push_command_block( @temporary_command_block, 
                                  @temporary_yield_stack, 
                                  options)
    end
  end

  #直下の子コントロール全てにコマンドを送信する
  def _SEND_ALL_(_ARGUMENT_: nil, **options)
    #子コントロール全てを探査対象とする
    @control_list.each do |control|
      next if _ARGUMENT_ and (control.id != _ARGUMENT_)
      control.unshift_command(:_SEND_, 
                              @temporary_command_block,
                              @temporary_yield_stack, 
                              options)
    end
  end

  #スクリプトファイルを挿入する
  def _INCLUDE_(_ARGUMENT_:, path: nil, parser: nil, force: false, **)
    #プロセスのカレントディレクトリを強制的に更新する
    #TODO：Window.open_filenameが使用された場合の対策だが、他に方法はないか？
    FileUtils.chdir(@@system_path)
    #ファイルのフルパスを取得
    path = File.expand_path(_ARGUMENT_)
    #拡張子取得
    ext_name = File.extname(path)
    #rbファイルでなければparserのクラス名を初期化する。
    unless ext_name == ".rb"
      ext_name.slice!(0)
      parser = ext_name.to_sym
    end

    begin
      #スクリプトをパースする
      _PARSE_(_ARGUMENT_: File.read(path, encoding: "UTF-8"), 
              path: path, 
              parser: parser)
    rescue Errno::ENOENT
      raise(Tsukasa::TsukasaLoadError.new(path))
    end
  end

  #スクリプトをパースする
  def _PARSE_(_ARGUMENT_:, path: nil, parser: nil, **)
    path = "(parse)" unless path

    #パーサーが指定されている場合
    if parser
      #文字列を取得して変換をかける
      _ARGUMENT_ = @@script_parser[parser][1].apply(
                      @@script_parser[parser][0].parse(_ARGUMENT_)
                    )
    end

    #司スクリプトを評価してコマンド配列を取得し、コマンドリストの先頭に追加する
    @command_list = @@script_compiler.eval_commands(
                      _ARGUMENT_,
                      path,
                      @temporary_yield_stack) + 
                    @command_list
  end

  #アプリを終了する
  def _EXIT_(**)
    set_exit()
  end

  #文字列を評価する（デバッグ用）
  def _EVAL_(_ARGUMENT_:)
    eval(_ARGUMENT_)
  end

  #文字列をコマンドラインに出力する（デバッグ用）
  def _PUTS_(_ARGUMENT_: nil, **options)
    if _ARGUMENT_
      puts '"' + _ARGUMENT_.to_s + '"'
    else
      puts options.to_s
    end
  end
end

class Control #シリアライズ
  def _SERIALIZE_(_ARGUMENT_: nil, control: nil)
    #第一引数が設定されている
    if _ARGUMENT_
      #配列を指定したコントロールのコマンドリストの先頭に挿入する
      child_control(control).unshift_command_array(_ARGUMENT_)
    else
      #指定したコントロールのコマンドリストを配列化し、ブロックに渡す
      unshift_command_block({command_list: find_control(control).serialize()})
    end
  end
end

class Control #内部コマンド
  #ファンクションの終点を示す
  def _END_LOOP_(**)
  end

  #ファンクションの終点を示す
  def _END_FUNCTION_(**)
  end
  
  #フレームの終了を示す（ダミーコマンド。これ自体は実行されない）
  def _HALT_(**)
    raise
  end
end

class Control #プロパティのパラメータ遷移

  #_MOVE_ [フレーム数, 
  #          {
  #            easing: イージング種類,
  #            lerp: 補間種類,
  #            control: コントールへの相対パス,
  #          }, 
  #         現在フレーム数
  #       ], 
  #       プロパティ名： [補間パラメータ], プロパティ名２...
  def _MOVE_(_ARGUMENT_:, **options)
    #第１引数をarray化
    _ARGUMENT_ = Array(_ARGUMENT_)
    #第１引数の第２要素が設定されていなければハッシュを初期化
    hash = _ARGUMENT_[1] || {}
    #現在フレーム数初期化
    _ARGUMENT_[2] ||= 0

    #カウントが終了しているならループを終了する
    return if _ARGUMENT_[0] == _ARGUMENT_[2]
    #カウントアップ
    _ARGUMENT_[2] += 1

    #経過量（0.0～1.0）を決定する
    step = EasingProcHash[hash[:easing] || :liner].call(
              _ARGUMENT_[2].fdiv(_ARGUMENT_[0])
            )

    #プロパティ走査
    options.each do |key, value|
      #値を更新する
      find_control(hash[:control]).send(key.to_s + "=", 
        #線形補完実行
        LerpProcHash[hash[:lerp] || :liner].call(value, step)
      )
    end

    #第１引数をオプションに復帰
    options[:_ARGUMENT_] = _ARGUMENT_

    #リストの先端に自分自身を追加する
    unshift_command(:_MOVE_, options)
    #現在のループ終端を挿入
    unshift_command(:_END_LOOP_)
    #フレーム終了疑似コマンドをスタックする
    unshift_command(:_HALT_)

    if command_block?
      #ブロックが付与されているならそれを実行する
      unshift_command_block(options)
    end
  end

  LerpProcHash = {
    #線形補間
    :liner => ->(value,step){
      return value[0] * (1.0 - step) + value[1] * step
    },
    #２次ベジェ補間
    :quadratic_bezier => ->(value, step){
      one_minus_step = 1.0 - step
      return   one_minus_step ** 2      *      value[0] + 
               one_minus_step *    step *      value[1] * 2 +
                                   step ** 2 * value[2] 
    },
    #３次ベジェ補間
    :cubic_bezier => ->(value, step){
      one_minus_step = 1.0 - step
      return one_minus_step ** 3             * value[0] +
             one_minus_step ** 2 * step      * value[1] * 3 +
             one_minus_step *      step ** 2 * value[2] * 3 +
                                   step ** 3 * value[3]
    },
    #Ｂスプライン補間
    #これらの実装については以下のサイトを参考にさせて頂きました。感謝します。
    # http://www1.u-netsurf.ne.jp/~future/HTML/bspline.html
    :b_spline => ->(value, step){
      step = (value.size - 1) * step
      result = 0.0

      #全ての座標を巡回し、それぞれの座標についてstep量に応じた重み付けを行い、その総和を現countでの座標とする
      value.size.times do |index|
        t = (step - index).abs
        # -1.0 < t < 1.0
        if t < 1.0 
          coefficent = (3.0 * t ** 3 - 6.0 * t ** 2 + 4.0) / 6.0
        # -2.0 < t <= -1.0 or 1.0 <= t < 2.0
        elsif t < 2.0 
          coefficent = -(t - 2.0) ** 3 / 6.0
        # t <= -2.0 or 2.0 <= t
        else 
          coefficent =  0.0
        end
        result += value[index] * coefficent
      end
      
      return result
    }
  }


  # jQuery + jQueryEasingPluginより32種類の内蔵イージング関数。それぞれの動きはサンプルを実行して確認のこと。
  EasingProcHash = {
    :liner => ->x{x},
    :in_quad => ->x{x**2},
    :in_cubic => ->x{x**3},
    :in_quart => ->x{x**4},
    :in_quint => ->x{x**5},
    :in_expo => ->x{x == 0 ? 0 : 2 ** (10 * (x - 1))},
    :in_sine => ->x{-Math.cos(x * Math::PI / 2) + 1},
    :in_circ => ->x{x == 0 ? 0 : -(Math.sqrt(1 - (x * x)) - 1)},
    :in_back => ->x{x == 0 ? 0 : x == 1 ? 1 : (s = 1.70158; x * x * ((s + 1) * x - s))},
    :in_bounce => ->x{1-EasingProcHash[:out_bounce][1-x]},
    :in_elastic => ->x{1-EasingProcHash[:out_elastic][1-x]},
    :out_quad => ->x{1-EasingProcHash[:in_quad][1-x]},
    :out_cubic => ->x{1-EasingProcHash[:in_cubic][1-x]},
    :out_quart => ->x{1-EasingProcHash[:in_quart][1-x]},
    :out_quint => ->x{1-EasingProcHash[:in_quint][1-x]},
    :out_expo => ->x{1-EasingProcHash[:in_expo][1-x]},
    :out_sine => ->x{1-EasingProcHash[:in_sine][1-x]},
    :out_circ => ->x{1-EasingProcHash[:in_circ][1-x]},
    :out_back => ->x{1-EasingProcHash[:in_back][1-x]},
    :out_bounce => ->x{
      case x
      when 0, 1
        x
      else
        if x < (1 / 2.75)
          7.5625 * x * x
        elsif x < (2 / 2.75)
          x -= 1.5 / 2.75
          7.5625 * x * x + 0.75
        elsif x < 2.5 / 2.75
          x -= 2.25 / 2.75
          7.5625 * x * x + 0.9375
        else
          x -= 2.625 / 2.75
          7.5625 * x * x + 0.984375
        end
      end
    },
    :out_elastic => ->x{
      case x
      when 0, 1
        x
      else
        (2 ** (-10 * x)) * Math.sin((x / 0.15 - 0.5) * Math::PI) + 1
      end
    },
    :swing => ->x{0.5 - Math.cos( x * Math::PI ) / 2},
    :inout_quad => ->x{
      if x < 0.5
        x *= 2
        0.5 * x * x
      else
        x = (x * 2) - 1
        -0.5 * (x * (x - 2) - 1)
      end
    },
    :inout_cubic => ->x{
      if x < 0.5
        x *= 2
        0.5 * x * x * x
      else
        x = (x * 2) - 2
        0.5 * (x * x * x + 2)
      end
    },
    :inout_quart => ->x{
      if x < 0.5
        x *= 2
        0.5 * x * x * x * x
      else
        x = (x * 2) - 2
        -0.5 * (x * x * x * x - 2)
      end
    },
    :inout_quint => ->x{
      if x < 0.5
        x *= 2
        0.5 * x * x * x * x * x
      else
        x = (x * 2) - 2
        0.5 * (x * x * x * x * x + 2)
      end
    },
    :inout_sine => ->x{
      -0.5 * (Math.cos(Math::PI * x) - 1);
    },
    :inout_expo => ->x{
      case x
      when 0, 1
        x
      else
        if x < 0.5
          x *= 2
          0.5 * (2 ** (10 * (x - 1)))
        else
          x = x * 2 - 1
          0.5 * (-2 ** (-10 * x) + 2)
        end
      end
    },
    :inout_circ => ->x{
    if x < 0.5
      x *= 2
      -0.5 * (Math.sqrt(1 - x * x) - 1);
    else
      x = x * 2 - 2
      0.5 * (Math.sqrt(1 - x * x) + 1);
    end
    },
    :inout_back => ->x{
      case x
      when 0, 1
        x
      else
        if x < 0.5
          EasingProcHash[:in_back][x*2] * 0.5
        else
          EasingProcHash[:out_back][x*2-1] * 0.5 + 0.5
        end
      end
    },
    :inout_bounce => ->x{
      case x
      when 0, 1
        x
      else
        if x < 0.5
          EasingProcHash[:in_bounce][x*2] * 0.5
        else
          EasingProcHash[:out_bounce][x*2-1] * 0.5 + 0.5
        end
      end
    },
    :inout_elastic => ->x{
      case x
      when 0, 1
        x
      else
        if x < 0.5
          EasingProcHash[:in_elastic][x*2] * 0.5
        else
          EasingProcHash[:out_elastic][x*2-1] * 0.5 + 0.5
        end
      end
    },
  }

  #スプライン補間
  #これらの実装については以下のサイトを参考にさせて頂きました。感謝します。
  # http://www1.u-netsurf.ne.jp/~future/HTML/bspline.html
  def _PATH_(_ARGUMENT_:, **options)
    _ARGUMENT_ = Array(_ARGUMENT_)
    #移動アルゴリズムの指定（初期値Ｂスプライン）
    _ARGUMENT_[1] ||= :spline
    #現在の経過カウントを初期化
    _ARGUMENT_[2] ||= 0
    #カウントが終了しているならループを終了する
    return if _ARGUMENT_[0] == _ARGUMENT_[2]
    #カウントアップ
    _ARGUMENT_[2] += 1

    options.each do |key, value|
      #Ｂスプライン補間時に始点終点を通らない
      step =(value.size - 1).fdiv(_ARGUMENT_[0]) * (_ARGUMENT_[2])

      result = 0.0

      #全ての座標を巡回し、それぞれの座標についてstep量に応じた重み付けを行い、その総和を現countでの座標とする
      value.size.times do |index|
        case _ARGUMENT_[1]
        when :spline
          coefficent = b_spline_coefficent(step - index)
        when :line
          coefficent = line_coefficent(step - index)
        else
          raise
        end

        result += value[index] * coefficent
      end

      #移動先座標の決定
      send(key.to_s + "=", result.round)
    end

    options[:_ARGUMENT_] = _ARGUMENT_

    #リストの先端に自分自身を追加する
    unshift_command(:_PATH_, options)
    #現在のループ終端を挿入
    unshift_command(:_END_LOOP_)
    #フレーム終了疑似コマンドをスタックする
    unshift_command(:_HALT_)

    if command_block?
      #ブロックが付与されているならそれを実行する
      unshift_command_block(options)
    end
  end

  #３次Ｂスプライン重み付け関数
  def b_spline_coefficent(t)
    t = t.abs

    # -1.0 < t < 1.0
    if t < 1.0 
      return (3.0 * t ** 3 - 6.0 * t ** 2 + 4.0) / 6.0

    # -2.0 < t <= -1.0 or 1.0 <= t < 2.0
    elsif t < 2.0 
      return  -(t - 2.0) ** 3 / 6.0

    # t <= -2.0 or 2.0 <= t
    else 
      return 0.0
    end
  end

  def line_coefficent(t)
    t = t.abs

    if t <= 1.0 
      return 1 - t
    # t <= -1.0 or 1.0 <= t
    else 
      return 0.0
    end
  end
end

class Control #デバッグ支援機能
  def put_control_tree(space_count)
    space = ""
    space_count.times do
      space +="  "
    end
    puts space + "->" + @id.to_s + " [ " + self.class.to_s + " ]"
    space_count +=1
    @control_list.each do |control|
      control.put_control_tree(space_count)
    end
  end

  #コントロールツリーを出力する
  def _DEBUG_TREE_(**)
    put_control_tree(0)
  end

  #プロパティの現在値を出力する
  def _DEBUG_PROP_(**)
    methods.each do |method|
      method = method.to_s
      if method[-1] == "=" and not(["===", "==", "!="].index(method))
        puts method.chop! + " : " + send(method).to_s
      end
    end
  end

  #コマンドリストを出力する
  def _DEBUG_COMMAND_(**)
    @command_list.each do |command|
      p command
    end
  end
end

end

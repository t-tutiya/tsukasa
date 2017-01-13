# メッセージ指向ゲーム記述言語「司エンジン（Tsukasa Engine）」

# 概要

*  司エンジンはメッセージ指向ゲーム開発言語「司スクリプト」の実装系です。rubyの内部ＤＳＬとして実装され、開発環境を含むフレームワークとして構成されています。
*  Ruby用DirectXゲームライブラリDXRuby上で動作しています。Windows専用です。
*  また、ノベルゲームの開発に特化した「tksスクリプト」も使用できます。tksスクリプトは内部で司スクリプトに変換され、ユーザーは必要に応じてシームレスに扱うことができます。

# 内部メカニズムの特徴

*  ゲームで用いる全てのオブジェクトをみなし、単一のツリーに連結させている
    *  画像、サウンドはもちろん、テキストウィンドウ内の文字一個にいたるまでオブジェクトとして管理しています。
    *  これによって、ゲームのあらゆる要素に対して一貫した設計コンセプトを実現します。
*  全てのオブジェクトをＶＭ（計算機）とみなし、ツリーの上位からメッセージを送信して駆動する。
    *  上位から送信されたメッセージは各オブジェクト内にスタックされ、実行されます。
    *  各メッセージは処理を行ったのち、自律的に自身を削除するか、次フレームに再実行するかを判断します。
    *  同フレーム中に複数の上位オブジェクトから同一のオブジェクトに対しメッセージが送信された場合、その全てがスタックされ処理されます。
    *  メッセージには制御構文も含められるため、プログラムブロックをまるごと送信できます。
    *  これらの挙動により、とかく状態遷移機械としての実装が複雑になりがちなゲームプログラミングのオブジェクトの実装効率の向上を狙っています。
*  全てのオブジェクトは疑似マルチスレッド的に駆動する。
    *  それぞれのオブジェクトは受け取ったメッセージ（≒プログラムブロック）を非同期に処理するので、ゲームのように複雑な並列処理が必要とされるプログラムを、平坦に記述できます。

#ドキュメント

　司エンジンに関するドキュメントについては、下記の各サイトを参照してください。

*  リファレンスマニュアル
    *  同梱のリファレンスマニュアルを参照してください。
*  サンプルコード
    *  [準備中。script/sampleフォルダに入っているサンプルコードを参照してください]

#その他の資料

##司エンジンの設計コンセプト

　司エンジンは「既存のゲーム開発そのもの」を再定義するために土屋つかさが進めている個人プロジェクトです。下記記事で紹介しています。

DXRuby Advent Calendar 2015 ３日目：汎用ゲームフレームワーク（を目指す）司エンジンの紹介
http://d.hatena.ne.jp/t_tutiya/20151202/1449068891

　上記記事にもリンクしていますが、下記のＰＤＦでは司エンジンが問題領域としている課題について、より専門的な議論を展開しています。
司エンジン解説本第１部サンプル（１２月２日版）
http://someiyoshino.main.jp/file/1218_tsukasa_engine_book_sample_chap1.pdf

## キーコード定数
　キー入力判定時に使用するキーコード定数はDXRubyと同じです。

DXRuby キーコード定数
http://mirichi.github.io/dxruby-doc/api/constant_keycode.html

## フォルダ構成
　司エンジン開発フォルダルート直下のフォルダとファイル構成を簡単に解説しておきます。
*  system 司エンジンのソースコードが格納されています。
*  default 初期値を設定するconfig.rb／デフォルトのスクリプトを格納するdefault_script.rbなどが格納されています。
*  script 司/tksスクリプトを配置するフォルダです。このフォルダのfirst.rbが最初に実行されます。
*  resource サンプルで使うリソースファイルが入っています。
    * githubからインストールする場合は、下記ファイルを直接ダウンロードし、展開後に配置してください。
    * https://github.com/t-tutiya/tsukasa/releases/download/v1.2.0/resource.zip
*  datastore データストアを保存するフォルダです。初期状態では空です。
    *  githubからインストールする場合はこのフォルダが存在しないので、手動で空フォルダを作成してください。
*  main.rb 実行スクリプト。これ自体は司エンジンには含まれません。
*  readme.md 簡易ドキュメント

##更新履歴

v2.2

■フォルダ構成
・プラグインフォルダをネイティブファイルのフォルダとスクリプトファイルのフォルダに分離した

■ユニットテスト関連
・テスト実行用のRakeFileを配置
・テストコードの命名ルールを設定

■内部ロジック
・カスタムコントロールのメソッド定義インターフェイスを変更

■サンプル
・ブロック崩しゲームをサンプルに追加
・カスタムシェーダーサンプルを更新

■default_script.rb
・追加
　・_GC_GARBAGE_COLLECT_
　・_GC_ENABLE_
　・_GC_DISABLE_
　・_GC_LATEST_GC_INFO_
　・_GC_STATUS_
・廃止
　・_PAD_ARROW_
　・_WINDOW_STATUS_
　・_SCREEN_MODES_
　・_FULL_SCREEN_
　・_MOUSE_WHEEL_POS_

■test_utility_script.rb
・_CHAR_IMAGE_の引数をpathから_ARGUMENT_に変更
・_TEXT_WINDOW_のフラグを管理する専用のDataコントロールを用意

■Controlコントロール
・_NEXT_/_BREAK_コマンドにブロックを付与できる仕様を廃止
・_SEND_コマンドで設定したプロパティの値をブロック内で利用できるようにした
・_SCOPE_コマンド廃止
・_LOAD_NATIVE_コマンド廃止
・（内部処理）exitプロパティを読み出し専用に変更（元々ドキュメントにはない）
・（内部処理）Control#unshift/push_command_arrayメソッドを追加

■Windowコントロール
・Window.caption/bgcolor/icon_path/cursor_type/full_screen/screen_modes/mouse_wheel_posプロパティ追加

■Drawableコントロール
・shaderプロパティをDXRuby::Shaderを直接保持する形式に変更

■Imageコントロール
・_PIXEL_コマンドのブロック引数名を_ARGUMENT_からcolorに変更

■TileMapコントロール
・_MAP_STATUS_コマンドのブロック引数名を_ARGUMENT_からstatusに変更

■Inputコントロール
・パッド番号をpad_codeプロパティで決定する形式にした
・x/yプロパティ追加

■RuleShaderコントロール
・コア機能を分離したShaderクラスを継承する形に変更し、RuleTransition.rbに改名

■Shaderコントロール
・新規追加

■pluginフォルダ
・HorrorTextShader.rb追加

v2.1

■main.rb処理
・初期設定をmain.rb上で構築するように変更
・Dataコントロール:_TEMP_/:_LOCAL_/:_SYSTEM_追加

■ファイル構成
・requireの依存関係を整理
・ファイルインクルードを統合するTsukasa.rbを作成
・ppを司エンジンの必須ライブラリから外した
・削除
　・bootstrap_script.rb
　・config.rb
・text_layer_script.rbを新設しtksパーサー関連スクリプトを整理

■テスト
・テストコード構築中

■司スクリプト
・インラインデータ記法を廃止（パーサーには残っている）

■default_script.rb
・requested_closeコントロールを廃止
・_CHECK_INPUT_ユーザー定義コマンドをControlから移動
・_CHECK_MOUSE_ユーザー定義コマンドをClickableLayoutから移動
・追加
　・_SYSTEM_SAVE_
　・_SYSTEM_LOAD_
　・_LOCAL_SAVE_
　・_LOCAL_LOAD_
　・_QUICK_SAVE_
　・_QUICK_LOAD_
・削除
　・_MOUSE_ENABLE_
　・_CHECK_REQUESTED_CLOSE_

■_SYSTEM_環境変数
・環境変数を仕様から廃止したため、以下の全環境変数を廃止
　・_PAD_NUMBER_
　・_SAVE_DATA_PATH_
　・_SYSTEM_FILENAME_
　・_LOCAL_FILENAME_
　・_QUICK_DATA_FILENAME_
　・_MOUSE_OFFSET_X_
　・_MOUSE_OFFSET_Y_
　・_MOUSE_POS_X_
　・_MOUSE_POS_Y_
　・_PLUGIN_PATH_
　・_CURSOR_VISIBLE_
　・_PAD_NUMBER_

■Controlコントロール
・_CHECK_のdatastoreプロパティ廃止
・_GET_の各要素の取得先コントロール名と格納名を指定できるようにした
・単体でルートコントロールになれるように実装を更新
・_SCRIPT_PARSER_/_LOAD_NATIVE_をWindowからControlに移動
・_SERIALIZE_追加
・_CHECK_INPUT_をユーザー定義コマンドに移動
・_INCLUDE_コマンドの簡易記法を廃止
・SET/CHECKの第１引数をコントロールパスに変更
・_RESIZE_をClickableLayoutに移動
・_PUTS_の仕様を更新
・_INCLUDE_コマンドのforceオプションを廃止。これに伴い_TEMP_環境変数で保持していた_LOADED_FEATURES_を廃止。

■Windowコントロール
・Window#mouse_x/mouse_yプロパティを読み出し可能に変更（暫定処置）
・派生元をClickableLayoutクラスに変更
・ファイル名をTsukasa.rbからWindow.rbに変更
・Window#mouse_enableプロパティ追加
・_RESIZE_コマンドで実ウィンドウのサイズが変わるように修正
・終了判定をrootコントロールのexitプロパティを見て判定する形式に変更
・close/close?メソッドを廃止
・auto_closeプロパティ追加
・_CHECK_REQUESTED_CLOSE_をユーザー定義コマンドから移動
・廃止
　・_SAVE_
　・_LOAD_
　・_QUICK_SAVE_
　・_QUICK_LOAD_

■ClickableLayoutコントロール
・_CHECK_MOUSE_での安定を汎用_CHECK_での判定に変更
・_CHECK_MOUSE_をユーザー定義コマンドに移動
・_RESIZE_をControlから移動

■TextPageコントロール
・_TEXT_コマンドの簡易記法を廃止

■Dataコントロール
・新規追加

■Inputコントロール
・新規追加
・第１引数でパッド番号を指定出来る様にした

v2.0

■司スクリプト記法の変更
　・コントロール送信文を廃止
　・付与ブロックの引数をキーワード引数のみに限定し、第１引数を廃止

■Window（旧：Tsukasa）
・コントロール名／ファイル名を変更
・デフォルトid廃止
・mouse_x/yプロパティを書き込み専用に変更
・_SCRIPT_PARSER_　file_pathオプションをpathに改名

■Control
・_ALIAS_　追加
・_CHECK_INPUT_　追加
・_CHECK_BLOCK_　追加
・_DEFINE_PROPERTY_　追加
・_DEBUG_TREE_　追加
・_DEBUG_PROP_　追加
・_DEBUG_COMMAND_　追加
・_DEBUG_TEMP_　追加
・_DEBUG_LOCAL_　追加
・_DEBUG_SYSTEM_　追加

・_YIELD_　引数が設定できるようにした。
・_DELETE_　第一引数で削除するコントロールをパス指定出来るようにした
・_INCLUDE_/_PARSE_　file_pathオプションをpathに改名
・_CHECK_
　・upperをoverに改名
　・ブロックが引数を受け取らないように変更
　・count/child_exist/child_not_exist/null/not_null条件項目を廃止
　・キー入力関連の条件項目を廃止し、_CHECK_INPUT_に移動
　・requested_close条件項目を廃止し、_CHECK_BLOCK_に移動（その際systemオプションの名称をmouseに変更し、内部のキーもmouse_push/mouse_down/mouse_up/right_mouse_down/right_mouse_push/right_mouse_upをそれぞれpush/down/up/right_down/right_push/right_upに変更
・_MOVE_/_PATH_
　・第１引数の仕様を変更
　・_OPTIONS_オプションを廃止。
・_LOOP_
　・条件判定を受け付ける仕様廃止
　・第一引数でカウンタを指定するように変更
　・現在のカウント値をブロック引数で取れるようにした

・_STACK_LOOP_　廃止
・_WAIT_　廃止（仕様を更新し、ユーザー定義コマンドに変更）

■Char（旧：CharControl）
・コントロール名／ファイル名を変更
・image_pathプロパティを追加

・_CLEAR_　追加

■Image（旧：ImageControl）
・コントロール名／ファイル名を変更
・file_pathプロパティをpathに改名
・初期化時のみentityを設定出来ていた仕様を廃止

・_DRAW_　追加

■DrawableLayout（旧：RenderTargetControl）
・コントロール名／ファイル名を変更

・_LINE_　追加
・_BOX_　追加
・_CIRCLE_　追加
・_TEXT_　追加

■TextPage（旧：TextPageControl）
・コントロール名／ファイル名を変更
・character_pitchの誤字を修正

■TileMap（旧：TileMapControl）
・コントロール名／ファイル名を変更
・_SET_TILE_　file_pathオプションをpathに改名
・_SET_TILE_GROUP_　file_pathオプションをpathに改名

■Layoutable(旧：LayoutableControl）
・コントロール名／ファイル名を変更
・ユーザーが直接生成できないように変更

・_TO_IMAGE_　廃止

■Drawable(旧：DrawableControl）
・コントロール名／ファイル名を変更
・ユーザーが直接生成できないように変更

■RuleShader（旧：RuleShaderControl）
・コントロール名／ファイル名を変更

■Sound（旧：SoundControl）
・コントロール名／ファイル名を変更
・file_pathプロパティをpathに改名

■Layout（旧：LayoutControl）
・コントロール名／ファイル名を変更

■ClickableLayout（旧：ClickableLayoutControl）
・コントロール名／ファイル名を変更
・_CHECK_MOUSE_　追加し、衝突判定を_CHECK_から分離（その際、cursor_move条件項目を廃止）
・cursor_offset_x/yプロパティ廃止

■標準ユーザー定義コマンド（default_script.rb）
・_INSTALL_PRERENDER_FONT_　追加
・_INSTALL_FONT_　追加
・_IMAGE_REGIST_　追加
・_IMAGE_DISPOSE_　追加
・_CHECK_REQUESTED_CLOSE_　追加
・ラベルのヘッダーフッターを廃止

■ユーティリティーユーザー定義コマンド（utility_script.rb）
・_WAIT_　追加
・_TO_IMAGE_　追加
・_BUTTON_BASE_　追加
・_TEXT_BUTTON_　_BUTTON_BASE_ベースで実装し直しインターフェイスを刷新
・_IMAGE_BUTTON_　_BUTTON_BASE_ベースで実装し直しインターフェイスを刷新
・_TEXT_WINDOW_修正
　・実行時に付与ブロックがある場合に実行するようにした
　・初期化パラメーターを全てTextPageに委譲するようにした
・_CHAR_SET_追加
・_CHAR_RUBI_追加
・_CHAR_IMAGE_追加
・_CHECK_ARRAY_INCLUDE_　追加

■データストア
　・_TEMP_でカーソルの絶対座標と前フレームからの相対座標を取得できるようにした

■定数定義
　・ファイルConstant.rbを導入し、以下のDXRuby定数を司エンジン上で再定義した。
　　・キーコード定数
　　・マウスボタン定数
　　・パッド定数
　　・マウスカーソル定数
　　・色定数

v1.2.1p9

* 条件項目upperをoverに変更
* ドキュメント更新

v1.2.1p8

* float_xの:bottomオプション廃止
* float_yの:leftオプション廃止
* float_x/yの初期値をnilに統一
* ImageControl#_TEXT_の引数x/yに初期値0を設定。
* サンプルコード更新

v1.2.1p7
* テキスト関連の初期設定を更新
    * 袋文字／影文字をデフォルトでオフに変更
    * 影文字の初期オフセットを[0,0]から[8,8]に。色を[255,255,255]に
* _TEXT_WINDOW_でedgeの有無指定を可能に
* _SEND_に設定した引数をハッシュで受け取れるようにした。

v1.2.1p6

* TextPageControl#charctor_pitchプロパティの初期値を０に変更
* _TEXT_WINDOW_の袋文字オプションをデフォルトでfalseに変更

v1.2.1p5

* bugfix

v1.2.1p4

* _TEXT_WINDOW_コマンドの描画順を1000000に統一
* コントロールのセンタリングの設計を更新
　・align_xプロパティを追加
　・align_x:にright/centerを設定可能に更新
　・align_y:にbottom/centerを設定可能に更新

v1.2.1p3

* _RETURN_/_NEXT_/_BREAK_に付与ブロックを追加

v1.2.1p2

※今回からDXRuby v1.4.4以降対応になります。

* Fontのauto_fitting(DXRuby1.4.4昨日)に対応
* 条件項目にunder/upperを追加
* CharControlのcharに値を代入した場合、無条件でto_sが実行されるようにした。
* resouseフォルダに仮配置のテキストファイルを配置
* サンプルコード更新

v1.2.1p1

* サンプルコード更新

v1.2.1

* ファイル構成
    * colorkey_control.rbを削除
    * サンプルコードの追加

* Control
    * 無名コントロールのidに"Anonymous_"を付与するのを廃止
    * _WAIT_/_MOVE_/_PATH_の付与ブロックを_BREAK_で抜けられるようにした
    * マウスボタンクリック系の仕様を更新
        * system: key_down/upをmouse_down/upに改名
        * system: mouse_pushを追加。mouse_downの仕様を変更

* ImageControl
    * entityプロパティ追加

* TextPageControl
    * _CHAR_COMMAND_コマンドを追加

* TileMapControl
    * _ADD_TILE_GROUP_で開始タイル番号を指定できるようにした
    * _ADD_TILE_/_ADD_TILE_GROUP_を_SET_TILE_/_SET_TILE_GROUP_に改名

* ClickableLayoutControl
    * colorkey_id/colorkey_border追加。これに伴いcolorkeyを廃止
    * cursor_x/cursor_yの値が正しく更新されないバグを修正
    * mouse: key_down系をkey_pushに変更＆key_down系を追加
    * key_right_up_outをright_key_up_outに変更（誤字）

* RenderTargetControl
　・枠線表示機能を削除

* ユーザー定義コマンド
    * _WINDOW_STATUS_にbgcolorプロパティを追加
    * _INPUT_UPDATE_を廃止
    * _WAIT_FRAME_をグローバルユーザー定義コマンドに

v1.2.0(2016/4/1)

* 司スクリプト
    * データストアへの簡易アクセスできる仕様を廃止
    * controlをブロック引数で取得できる仕様を廃止

* クラス構成
    * Layoutable/DrawableモジュールをControl派生クラスLayoutableControl/DrawableControlに変更
    * ClickableモジュールをLayoutControl派生クラスClickableLayoutControlに変更
    * TileMapControlの継承元クラスをRenderTargetControlに変更
    * CharaControlの継承元クラスをDrawableControlに変更

* Control
    * プロパティ
        * child_index追加
        * child_update（子コントロール更新フラグ）追加
    * _SEND_
        * 第１引数を設定しない場合、自コントロールを対象とするように変更
        * interruptオプションを追加
        * 特殊コントロールＩＤ:_ROOT_/:_PARENT_を対応
    * _SEND_ALL_コマンドを追加
    * _SEND_ROOT_コマンド廃止
    * _SET_OFFSET_コマンドを追加
    * _GET_のインターフェイスを刷新
        * 指定した値はブロック経由で参照する形式に変更
        * _RESULT_を廃止
    * _MOVE_/_PATH_の仕様を更新
        * 移動が終わるまでウェイトをかけ、実行中はブロックが実行されるように変更
        *optionプロパティ名を_OPTION_に変更
        * 無効のeasingオプションが設定された場合:linerに差し替えるように修正
    * _INCLUDE_で多重読み込みを抑制する処理を追加：forceオプションを追加
    * 条件判定
        * コントロールプロパティの比較を可能にした
        * パッドボタン判定を追加
        * childをchild_existに変更
        * child_not_existを追加
    * _DEBUG_変数削除
    * デフォルト設定を廃止

* LayoutableControl
    * width/heightの初期値を１に変更
    * _TO_IMAGE_をLayoutableControlに移動

* DrawableControl
    * visibleプロパティをLayoutableControlから移動
    * entityを非プロパティ化した
    * 未使用プロパティreal_width/real_heightを廃止

* ImageControl
    * _LINE_/_BOX_/_CIRCLE_/_TRIANGLE_/_TEXT_/_FILL_/_CLEAR_/_PIXEL_/_COMPARE_コマンドを追加

* CharControl
    * 空文字列を受けた時、widthを１とした
    * 縁文字のオフセット処理他を廃止した
    * charactorプロパティをcharに改名

* Tsukasa
    * cursor_x/cursor_yはmouse_x/mouse_yに改名（ハードの絶対値を取得／設定する）
    * _SAVE_/_LOAD_/_LOAD_NATIVE_コマンドをControlからTsukasaに移動
    * _SYSTEM_/_LOCAL_/_TEMP_をTsukasaからしか取得できないように変更

* ClickableLayoutControl
    * 条件判定にcursor_on/offを追加
    * mouse_pos_x/yを読み取り専用プロパティcursor_x/yに変更（相対座標）
    * 読み取り専用プロパティcursor_offset_x/cursor_offset_yを追加

* TileMapControl
    * _SET_IMAGE_/_SET_IMAGE_MAPPING_/_SET_TILE_コマンドを、ロジックを修正した上で_ADD_TILE_/_ADD_TILE_GROUP_/_MAP_STATUS_に改名
    * サイズ初期値を32,32に設定
    * 画像共有しないをデフォルトとした（キャッシュ機構が不完全なため）

* 標準ユーザー定義コマンド
    * ファイルダイアログ関連：_OPEN_FILENAME_/_SAVE_FILENAME_/_FOLDER_DIALOG_
    * ウィンドウ操作関連：_RESIZE_/_FULL_SCREEN_/_RUNNING_TIME_/_SCREEN_MODES_（組み込みコマンドから変更）/_FPS_
    * ウィンドウ情報取得：_WINDOW_STATUS_（cursor_type/caption/icon_pathをtsukasaから集約）
    * インターフェイス操作関連：_INPUT_UPDATE_/_MOUSE_WHEEL_POS_/_PAD_ARROW_（_PAD_コマンドから変更）/_PAD_CONFIG_/_CURSOR_VISIBLE_（また、cursor_visibleプロパティをシステム変数に変更）
    * _CAPTURE_SS_を組み込みから変更
    * _LABEL_の内部変数を変更（ロジックも刷新）
    * _CURSOR_VISIBLE_を_MOUSE_ENABLE_に改名
    * button/TextButton/TextWindowを_IMAGE_BUTTON_/_TEXT_BUTTON_/_TEXT_WINDOW_に改名
    * pause/line_pause/end_pauseを_PAUSE_/_LINE_PAUSE_/_END_PAUSE_に改名


v1.1.0(2016/1/8)

* Controlクラス
    * 追加コマンド
        * _LOAD_NATIVE_：ネイティブrubyコードの読み込み。
        * _NEXT_LOOP_：_LOOP_の特殊版
        * _PARSE_：tks/司スクリプトをパースする
        * _QUICK_SAVE_ / _QUICK_LOAD_ ：クイックセーブ／ロードを実現するメカニズム。
    * 追加条件判定項目
        * command_stack / not_command_stack（旧command）
    * システム全体の判定を行うsystemを追加。
        * key_down/key_up/right_key_down/right_key_up
        * block_given/requested_close(mouseから移動)
    * 機能追加／変更
        * _TO_IMAGE_コマンド：任意の拡大率でImageControlを作れるようにした
        * _YILED_コマンド：付与ブロック無しに呼びだされた場合は例外で落とすようにした
        * _INCLUDE_コマンド：任意のparserクラスをオプションで指定できるようにした
        * 条件判定で単一要素を渡す際に、[]で囲まなくても良いようにした。
        * _PARSER_データストア追加

* TextPageControlクラス
    * 文字間待機、行間待機をユーザー定義関数で定義する形式に変更
    * 文字レンダラをユーザー定義関数で定義する形式に変更（それに伴い_CHAR_RENDERER_コマンドを削除）
    * TextPageControlのwait_frame/line_feed_wait_frame各プロパティを廃止。

* ImageControlクラス
    * _SAVE_IMAGE_（ImageControl）：ImageControlを画像保存する

* 司スクリプト
    * _TEMP_/_SYSYTEM_/_LOCAL_の各データストアをスクリプト上から直接参照できるようにした。
    * データストア_TEMP_/_LOCAL_/_SYSTEM_にそれぞれ_T_/_L_/_S_の短縮名を用意した

* 標準テキストウィンドウ
    * 構造を簡略化し、背景画像を廃止した。
    * 左クリックでウェイトスキップされるようにした。
    * ページ送りアイコンの表示にend_page/epユーザー定義コマンドを用いる物とした（これにともないpage_pauseを廃止）
    * スキップ時にクリック待ちアイコンを表示しないように修正
    * ユーザー定義コマンド追加
    * _SEND_TO_ACTIVE_LINE_：テキストウィンドウのアクティブ行にコマンドを送信する

* 追加ユーザー定義コマンド
    * _LABEL_：既読フラグ管理機能（これに伴いlabel組み込みコマンドを削除）
    * _CAPTURE_SS_：組み込みからユーザー定義に変更

* サンプルコード
    * ランチャーを用意
    * 既読フラグ管理のサンプルコードを追加
    * シリアライズのサンプルコードを追加
    * サンプルゲームにあおいたくさんの「野メイド」移植版を追加

v1.0.0(2015/12/24)　1stリリース

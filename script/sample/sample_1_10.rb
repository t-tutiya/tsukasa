_CREATE_ :RenderTargetControl, id: :test0, width: 800, height: 600 do
  _CREATE_ :ImageControl, file_path: "./resource/bg_test.jpg"
  _CREATE_ :ImageControl, file_path: "./resource/char/B-1.png", x: 250
end

_CREATE_ :ImageControl, id: :test1, file_path: "./resource/bg_sample.png" do
  _CREATE_ :RuleShaderControl, id: :rule0, vague: 40,
            file_path: "./resource/rule/horizontal_rule.png"
  _SET_ shader: :rule0
end

_WAIT_ key_push: K_SPACE, system: [:mouse_push]

_SEND_ :test1 do
  _SEND_ :rule0 do
    _MOVE_ 240, counter:[0,255]
    _DELETE_
  end

  _WAIT_ child_not_exist: :rule0
  _DELETE_
end

_END_PAUSE_
_DELETE_ :test0
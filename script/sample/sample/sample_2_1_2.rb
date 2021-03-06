#ボタンコントロール
_CREATE_ :ClickableLayout, 
  width: 256,
  height: 256,
  id: :test01,
  shape: [128,128,128] do
  _CREATE_ :Image, id: :normal, width:256, height:256 do
    _CIRCLE_ x: 128,  y: 128, r: 128, color: C_BLUE, fill: true
    _TEXT_ "NORMAL", x:80, y:120, color: [0,255,0]
  end
  _CREATE_ :Image, id: :over, visible: false, width:256, height:256 do
    _CIRCLE_ x: 128,  y: 128, r: 128, color: C_YELLOW, fill: true
    _TEXT_ "OVER", x:80, y:120, option: {color: [0,0,0]}
  end
  _CREATE_ :Image, id: :key_down, visible: false, width:256, height:256 do
    _CIRCLE_ x: 128,  y: 128, r: 128, color: C_GREEN, fill: true
    _TEXT_ "DOWN", x:80, y:120, option: {color: [0,0,0]}
  end
  _DEFINE_ :inner_loop do
    _CHECK_ collision: :cursor_over do
      _SEND_(:normal)  {_SET_ visible: false}
      _SEND_(:over)    {_SET_ visible: true}
      _SEND_(:key_down){_SET_ visible: false}
    end
    _CHECK_ collision: :cursor_out do
      _SEND_(:normal)  {_SET_ visible: true}
      _SEND_(:over)    {_SET_ visible: false}
      _SEND_(:key_down){_SET_ visible: false}
    end
    _CHECK_ collision: :key_down do
      _SEND_(:normal)  {_SET_ visible: false}
      _SEND_(:over)    {_SET_ visible: false}
      _SEND_(:key_down){_SET_ visible: true}
    end
    _CHECK_ collision: :key_up do
      _SEND_(:normal)  {_SET_ visible: false}
      _SEND_(:over)    {_SET_ visible: true}
      _SEND_(:key_down){_SET_ visible: false}
    end
    _HALT_
    _RETURN_ do
      inner_loop
    end
  end
  inner_loop
end

_WAIT_ input:{mouse: :right_push}

_SEND_ :test01, interrupt: true do
  _DELETE_
end

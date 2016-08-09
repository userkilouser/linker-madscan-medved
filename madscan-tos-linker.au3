#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <Misc.au3>
#include <Array.au3>


; Ссылка на xml, содержащий название комании
; Global Const $yqlAPICompanyNameRequest = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=<SYMBOL>&callback=YAHOO.Finance.SymbolSuggest.ssCallback"

; Ссылка на текст, содержащий сектор и индустрии компании
Global Const $yqlAPICompanySectorRequest = "http://www.stock-watcher.com/quote/<SYMBOL>"

; регистрация нажатия ESC для выхода из программы
HotKeySet("{ESC}", "Terminate")

; Создаем окно формы
$pic = GUICreate("Linker", 400, 60, 620, 80, $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_TOPMOST)) ;

; Кладем на форму картинку с прозрачным фоном
$basti_stay = GUICtrlCreatePic("bground.gif", 0, 0, 400, 60,-1, $GUI_WS_EX_PARENTDRAG)

; Создаем надпись (пока пустую)
$hDC = GUICtrlCreateLabel("",0, 0, 400, 60)
; Настройка надписи
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor($hDC, 0xffd800)

; Отображаем окно формы
GUISetState(@SW_SHOW)

; Инициализация тикера
$symbPrev = ""

; "Вечный" цикл отображения окна формы
While 1

   ; Берем видимый текст с активного окна
   Local $hActiveText = WinGetText("[ACTIVE]", "")

   ;ConsoleWrite("HH" & $hActiveText & @CRLF)

   ; Сравниваем полученную выше строку с известным значением WinGetText() для фильтров Madscan
   If StringInStr($hActiveText, "toolStripContainer1") = 2 Then

	  ;ConsoleWrite("MS: " & $hActiveText & @CRLF)

	  ; Обнулям предыдущее значение надписи
      ;ControlSetText($pic, "", $hDC, "")

	  ; Если активное окно - это фильтр Madscan, то посылаем ему Ctrl+C для копирования в буфер всей строки, которая под мышкой
      Send("{CTRLDOWN}C{CTRLUP}")

	  ; Убираем из строки часть из времени алерта (которое в американском формате, например 1:13 PM)
      Local $Clip = StringRegExpReplace (ClipGet(), ":\d+\s[A|P]M", "", 0)

      ; Выбираем из отстатка строки тикер
      Local $TickerArray = StringRegExp($Clip, '([A-Z|\.\-\+]+)\s', 1, 1)
      Local $Ticker = _ArrayToString($TickerArray, "")
	  ; Замена "." в тикере на "/" для TOS
	  $Ticker = StringRegExpReplace ($Ticker, "\.", "/", 0)

	  ;ConsoleWrite("$TickerArray: " & $TickerArray & @CRLF)
	  ;ConsoleWrite("$Ticker: " & $Ticker & @CRLF)

	  ; Обновляем $symbPrev
	  $symbPrev = $Ticker

	  ; Активируем окно Medved
       _WinWaitActivate("[NAME:panelMain]", "")
      Local $hMedved = ControlGetHandle("[NAME:panelMain]", "", "")
	  ; ConsoleWrite("$hMedved: " & $hMedved & @CRLF)
	  ; ControlClick("", "", "[CLASS:SunAwtFrame]", "left", 2, 106, 66)

	  ; Отправляем тикер в поле для тикера окна TOS (весь целиком)
	  ControlSend ("", "", $hMedved, $Ticker & "{ENTER}", 0)
	  ; ConsoleWrite("@error: " & @error & @CRLF)

	  ; Вызов функции для получения инфо компании по тикеру
	  $Ticker = StringRegExpReplace ($Ticker, "/[A-Z]+", "", 0)
      $sSymbolInfo = GetCompanyInfo($Ticker)

	  ; Устанавливаем значения надписи в соответствии с инфо о компании
      GUICtrlSetData($hDC, $sSymbolInfo)

   EndIf

    ; Если нажата правая клавиша мышки - выход из цикла
   If _IsPressed("02") Then
      ExitLoop
   EndIf

	; Снятие нагрузки с процессора
	Sleep(500)

WEnd

; Функция активации окна
Func _WinWaitActivate($title,$text,$timeout=0)
    WinWait($title,$text,$timeout)
    If Not WinActive($title,$text) Then WinActivate($title,$text)
    WinWaitActive($title,$text,$timeout)
 EndFunc

; Выход из программы
Func Terminate()
    Exit 0
EndFunc

; Получение инфо о компании по тикеру
Func GetCompanyInfo($sSymbol)

   ; Получение информации о секторе и индустрии компании

   $sRequest = StringReplace($yqlAPICompanySectorRequest, "<SYMBOL>", $sSymbol)
   ; ConsoleWrite($sRequest & @CRLF)
   $bData = InetRead($sRequest)

   $aLines = BinaryToString($bData, 4)
   ; ConsoleWrite("$aLines-bs" & $aLines & @CRLF)

   $array = StringRegExp($aLines, 'Quote-fulname">\n.*>(.*), (.*)<\/b><br>(.*)<\/div', 1, 1)
   If @error = 0 then
      ; ConsoleWrite ("0: " & $array[0] & @CRLF)
      ; ConsoleWrite ("1: " & $array[1] & @CRLF)
	  ; ConsoleWrite ("2: " & $array[2] & @CRLF)
	  ; ConsoleWrite ("3: " & $array[3] & @CRLF)
      $sCompanyInfo = $array[0] & @CRLF & $array[1] & $array[2]; & $array[3]
   Else
	  $sCompanyInfo = "N/A"
   EndIf

   Return $sCompanyInfo

EndFunc
;;; ============================================================
;;; CHANGE.TYPE - Desk Accessory
;;;
;;; Shows the ProDOS type and auxtype of selected files, and lets the
;;; user edit either or both.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "change.type.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/letk.inc"
        .include "../toolkits/icontk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Window

        kDialogWidth = 287
        kDialogHeight = 75

        kDAWindowId = $80

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
mincontheight:  .word   100
maxcontwidth:   .word   500
maxcontheight:  .word   500
port:
        DEFINE_POINT viewloc, (kScreenWidth-kDialogWidth)/2, (kScreenHeight-kDialogHeight)/2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDialogWidth, kDialogHeight
pattern:        .res    8,$FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME frame_rect, kDialogWidth, kDialogHeight

;;; ============================================================
;;; Buttons

        kControlMarginX = 16

        kOKButtonLeft = kDialogWidth - kButtonWidth - kControlMarginX
        kCancelButtonLeft = kControlMarginX
        kButtonTop = kDialogHeight - kButtonHeight - 7

        DEFINE_BUTTON ok_button, kDAWindowId, res_string_button_ok, kGlyphReturn, kOKButtonLeft, kButtonTop
        DEFINE_BUTTON cancel_button, kDAWindowId, res_string_button_cancel, res_string_button_cancel_shortcut, kCancelButtonLeft, kButtonTop

;;; ============================================================
;;; Line Edits

auxtype_focused_flag:
        .byte   0

str_type:
        PASCAL_STRING "00"
str_auxtype:
        PASCAL_STRING "0000"

        kTextBoxLeft = 145
        kTextBoxWidth = 40
        kTypeY = 18
        kAuxtypeY = 35

        DEFINE_LINE_EDIT type_line_edit_rec, kDAWindowId, str_type, kTextBoxLeft, kTypeY, kTextBoxWidth, 2
        DEFINE_LINE_EDIT_PARAMS type_le_params, type_line_edit_rec
        DEFINE_RECT_SZ type_rect, kTextBoxLeft, kTypeY, kTextBoxWidth, kTextBoxHeight

        DEFINE_LINE_EDIT auxtype_line_edit_rec, kDAWindowId, str_auxtype, kTextBoxLeft, kAuxtypeY, kTextBoxWidth, 4
        DEFINE_LINE_EDIT_PARAMS auxtype_le_params, auxtype_line_edit_rec
        DEFINE_RECT_SZ auxtype_rect, kTextBoxLeft, kAuxtypeY, kTextBoxWidth, kTextBoxHeight

        DEFINE_LABEL type, res_string_label_type, kTextBoxLeft-2, kTypeY+kSystemFontHeight+1
        DEFINE_LABEL auxtype, res_string_label_auxtype, kTextBoxLeft-2, kAuxtypeY+kSystemFontHeight+1

;;; ============================================================
;;; Alerts

.params AlertNoFilesSelected
        .addr   str_err_no_files_selected
        .byte   AlertButtonOptions::OK
        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams
str_err_no_files_selected:
        PASCAL_STRING res_string_err_no_files_selected

;;; ============================================================

        .include "../lib/event_params.s"

;;; ============================================================

;;; Copied from/to main
.params data
type_valid:     .byte   0
type:           .byte   SELF_MODIFIED_BYTE

auxtype_valid:  .byte   0
auxtype:        .word   SELF_MODIFIED
.endparams

;;; ============================================================

.proc RunDA
        bit     data::type_valid
    IF_NC
        copy8   #0, str_type
    ELSE
        copy8   #2, str_type
        lda     data::type
        jsr     GetDigits
        sta     str_type+1
        stx     str_type+2
    END_IF

        bit     data::auxtype_valid
    IF_NC
        copy8   #0, str_auxtype
    ELSE
        copy8   #4, str_auxtype
        lda     data::auxtype+1
        jsr     GetDigits
        sta     str_auxtype+1
        stx     str_auxtype+2
        lda     data::auxtype
        jsr     GetDigits
        sta     str_auxtype+3
        stx     str_auxtype+4
    END_IF

        MGTK_CALL MGTK::OpenWindow, winfo
        LETK_CALL LETK::Init, type_le_params
        LETK_CALL LETK::Init, auxtype_le_params

        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents

        LETK_CALL LETK::Activate, type_le_params

        FALL_THROUGH_TO InputLoop
.endproc ; RunDA

;;; ============================================================
;;; Input loop

.proc InputLoop
        bit     auxtype_focused_flag
    IF_NC
        LETK_CALL LETK::Idle, type_le_params
    ELSE
        LETK_CALL LETK::Idle, auxtype_le_params
    END_IF

        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        jsr     GetNextEvent

        cmp     #kEventKindMouseMoved
        jeq     HandleMouseMoved

        cmp     #MGTK::EventKind::button_down
        jeq     HandleButtonDown

        cmp     #MGTK::EventKind::key_down
        jeq     HandleKeyDown

        jmp     InputLoop
.endproc ; InputLoop

;;; ==================================================

.proc HandleMouseMoved
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, type_rect
    IF_NOT_ZERO
        jsr     SetCursorIBeam
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, auxtype_rect
    IF_NOT_ZERO
        jsr     SetCursorIBeam
        jmp     InputLoop
    END_IF

        jsr     SetCursorPointer
        jmp     InputLoop

cursor_ibeam_flag: .byte   0

.proc SetCursorIBeam
        bit     cursor_ibeam_flag
        RTS_IF_NS

        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        copy8   #$80, cursor_ibeam_flag
        rts
.endproc ; SetCursorIBeam

.proc SetCursorPointer
        bit     cursor_ibeam_flag
        RTS_IF_NC

        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        copy8   #0, cursor_ibeam_flag
        rts
.endproc ; SetCursorPointer
.endproc ; HandleMouseMoved

;;; ============================================================

.proc HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        jne     InputLoop

        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, ok_button
        jpl     ExitOK
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, cancel_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
        jpl     ExitCancel
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, type_rect
    IF_NE
        jsr     FocusType
        COPY_STRUCT MGTK::Point, screentowindow_params::window, type_le_params::coords
        LETK_CALL LETK::Click, type_le_params
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, auxtype_rect
    IF_NE
        jsr     FocusAuxtype
        COPY_STRUCT MGTK::Point, screentowindow_params::window, auxtype_le_params::coords
        LETK_CALL LETK::Click, auxtype_le_params
        jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc ; HandleButtonDown

;;; ============================================================

.proc HandleKeyDown
        lda     event_params::key

        ldx     event_params::modifiers
    IF_NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        jeq     ExitCancel

        jmp     InputLoop
    END_IF

        cmp     #CHAR_ESCAPE
    IF_EQ
        BTK_CALL BTK::Flash, cancel_button
        jmp     ExitCancel
    END_IF

        cmp     #CHAR_RETURN
    IF_EQ
        BTK_CALL BTK::Flash, ok_button
        jmp     ExitOK
    END_IF

        cmp     #CHAR_TAB
    IF_EQ
        bit     auxtype_focused_flag
      IF_NC
        jsr     FocusAuxtype
      ELSE
        jsr     FocusType
      END_IF
        jmp     InputLoop
    END_IF

        jsr     IsControlChar
        bcc     :+
        jsr     IsHexChar
        bcc     :+
        jmp     InputLoop
:
        bit     auxtype_focused_flag
    IF_NC
        sta     type_le_params::key
        copy8   event_params::modifiers, type_le_params::modifiers
        LETK_CALL LETK::Key, type_le_params
    ELSE
        sta     auxtype_le_params::key
        copy8   event_params::modifiers, auxtype_le_params::modifiers
        LETK_CALL LETK::Key, auxtype_le_params
    END_IF

        jmp     InputLoop

;;; Input: A=character
;;; Output: C=0 if control, C=1 if not
.proc IsControlChar
        cmp     #CHAR_DELETE
        bcs     yes

        cmp     #' '
        rts                     ; C=0 (if less) or 1

yes:    clc                     ; C=0
        rts
.endproc ; IsControlChar

;;; Input: A=character
;;; Output: C=0 if valid hex character, C=1 otherwise
.proc IsHexChar
        jsr     ToUpperCase

        cmp     #'0'
        bcc     no
        cmp     #'9'+1
        bcc     yes

        cmp     #'A'
        bcc     no
        cmp     #'F'+1
        bcc     yes

no:     sec
        rts

yes:    clc
        rts
.endproc ; IsHexChar
.endproc ; HandleKeyDown

;;; ============================================================

;;; No-op if type already focused
.proc FocusType
        bit     auxtype_focused_flag
        RTS_IF_NC

        LETK_CALL LETK::Deactivate, auxtype_le_params
        LETK_CALL LETK::Activate, type_le_params
        copy8   #0, auxtype_focused_flag

        rts
.endproc ; FocusType

;;; No-op if auxtype already focused
.proc FocusAuxtype
        bit     auxtype_focused_flag
        RTS_IF_NS

        LETK_CALL LETK::Deactivate, type_le_params
        LETK_CALL LETK::Activate, auxtype_le_params
        copy8   #$80, auxtype_focused_flag

        rts
.endproc ; FocusAuxtype

;;; ============================================================

.proc PadType
:       lda     str_type
        cmp     #2
        beq     :+
        copy8   str_type+1, str_type+2
        copy8   #'0', str_type+1
        inc     str_type
        bne     :-              ; always
:
        rts
.endproc ; PadType

.proc PadAuxtype
:       lda     str_auxtype
        cmp     #4
        beq     :+
        copy8   str_auxtype+3, str_auxtype+4
        copy8   str_auxtype+2, str_auxtype+3
        copy8   str_auxtype+1, str_auxtype+2
        copy8   #'0', str_auxtype+1
        inc     str_auxtype
        bne     :-              ; always
:
        rts
.endproc ; PadAuxtype

;;; ============================================================

.proc ExitOK
        lda     #$80
        bne     Exit            ; always
.endproc ; ExitOK

.proc ExitCancel
        lda     #0
        FALL_THROUGH_TO Exit
.endproc ; ExitCancel

.proc Exit
        pha
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        lda     str_type
    IF_ZERO
        copy8   #0, data::type_valid
    ELSE
        copy8   #$80, data::type_valid
        jsr     PadType
        lda     str_type+1
        ldx     str_type+2
        jsr     DigitsToByte
        sta     data::type
    END_IF

        lda     str_auxtype
    IF_ZERO
        copy8   #0, data::auxtype_valid
    ELSE
        copy8   #$80, data::auxtype_valid
        jsr     PadAuxtype
        lda     str_auxtype+1
        ldx     str_auxtype+2
        jsr     DigitsToByte
        sta     data::auxtype+1
        lda     str_auxtype+3
        ldx     str_auxtype+4
        jsr     DigitsToByte
        sta     data::auxtype
    END_IF

        pla
        rts

;;; Input: A = ASCII digit
;;; Output A = value in low nibble
.proc DigitToNibble
        cmp     #'9'+1
        bcs     :+
        and     #%00001111
        rts

:       sec
        sbc     #('A' - 10)
        rts
.endproc ; DigitToNibble

;;; Inputs: A,X = ASCII digits (first, second)
;;; Output: A = byte
.proc DigitsToByte
        jsr     DigitToNibble
        asl
        asl
        asl
        asl
        sta     mod
        txa
        jsr     DigitToNibble
        mod := *+1
        ora     #SELF_MODIFIED_BYTE
        rts
.endproc ; DigitsToByte

.endproc ; Exit

;;; ============================================================
;;; Render the window contents

.proc DrawWindow
        MGTK_CALL MGTK::SetPort, winfo::port

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, type_label_pos
        param_call DrawStringRight, type_label_str

        MGTK_CALL MGTK::MoveTo, auxtype_label_pos
        param_call DrawStringRight, auxtype_label_str

        MGTK_CALL MGTK::FrameRect, type_rect
        MGTK_CALL MGTK::FrameRect, auxtype_rect

        BTK_CALL BTK::Draw, ok_button
        BTK_CALL BTK::Draw, cancel_button

        rts
.endproc ; DrawWindow

;;; ============================================================

;;; Input: A = value
;;; Output: A,X = high/low nibbles as ASCII digits
.proc GetDigits
        tay

        lsr                     ; high nibble
        lsr
        lsr
        lsr
        tax
        lda     digits,x
        pha

        tya

        and     #$0F            ; low nibble
        tax
        lda     digits,x
        tax                     ; X = low digit

        pla                     ; A = high digit
        rts

digits: .byte   "0123456789ABCDEF"
.endproc ; GetDigits

;;; ============================================================

.proc DrawStringRight
        params := $6
        textptr := $6
        textlen := $8
        result := $9

        stax    textptr
        ldy     #0
        lda     (textptr),y
        sta     textlen
        inc16   textptr
        MGTK_CALL MGTK::TextWidth, params
        sub16   #0, result, result
        lda     #0
        sta     result+2
        sta     result+3
        MGTK_CALL MGTK::Move, result
        MGTK_CALL MGTK::DrawText, params
        rts
.endproc ; DrawStringRight

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/get_next_event.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        jmp     Main

;;; ============================================================

;;; Copied to/from aux
.params data
type_valid:     .byte   0
type:           .byte   SELF_MODIFIED_BYTE

auxtype_valid:  .byte   0
auxtype:        .word   SELF_MODIFIED
.endparams
.assert .sizeof(data) = .sizeof(aux::data), error, "size mismatch"

;;; ============================================================

stash_stack:
        .byte   0

.proc Main
        tsx
        stx     stash_stack

        jsr     JUMP_TABLE_GET_SEL_WIN
    IF_ZERO
        param_jump JUMP_TABLE_SHOW_ALERT_PARAMS, aux::AlertNoFilesSelected
    END_IF

        jsr     JUMP_TABLE_GET_SEL_COUNT
    IF_ZERO
        param_jump JUMP_TABLE_SHOW_ALERT_PARAMS, aux::AlertNoFilesSelected
    END_IF

        jsr     GetTypes

        copy16  #data, STARTLO
        copy16  #data+.sizeof(data)-1, ENDLO
        copy16  #aux::data, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE

        JSR_TO_AUX aux::RunDA
        RTS_IF_NC               ; cancel

        copy16  #aux::data, STARTLO
        copy16  #aux::data+.sizeof(data)-1, ENDLO
        copy16  #data, DESTINATIONLO
        clc                     ; aux>main
        jsr     AUXMOVE

        jsr     ApplyTypes

        jsr     JUMP_TABLE_GET_SEL_WIN
        jmp     JUMP_TABLE_ACTIVATE_WINDOW
.endproc ; Main

.proc Abort
        ldx     stash_stack
        txs
        rts
.endproc ; Abort

;;; ============================================================


path:           .res    ::kPathBufferSize

        DEFINE_GET_FILE_INFO_PARAMS gfi_params, path

;;; Assert: at least one file selected
.proc GetTypes
        copy16  #callback, IterationCallback
        jsr     IterateSelectedFiles
        rts

callback:
        pha                     ; A = index
        jsr     GetFileInfo
        pla
    IF_ZERO
        ;; First - use this type/auxtype
        copy8   gfi_params::file_type, data::type
        copy16  gfi_params::aux_type, data::auxtype
        lda     #$80
        sta     data::type_valid
        sta     data::auxtype_valid
    ELSE
        ;; Rest - determine if same type/auxtype
        lda     gfi_params::file_type
        cmp     data::type
      IF_NE
        copy8   #0, data::type_valid
      END_IF

        ecmp16  gfi_params::aux_type, data::auxtype
      IF_NE
        copy8   #0, data::auxtype_valid
      END_IF

    END_IF
        rts
.endproc ; GetTypes

;;; Assert: at least one file selected
.proc ApplyTypes
        lda     data::type_valid
        ora     data::auxtype_valid
        RTS_IF_NC

        copy16  #callback, IterationCallback
        jsr     IterateSelectedFiles
        rts

callback:
        jsr     GetFileInfo
        RTS_IF_NOT_ZERO

        bit     data::type_valid
    IF_NS
        copy8   data::type, gfi_params::file_type
    END_IF

        bit     data::auxtype_valid
    IF_NS
        copy16  data::auxtype, gfi_params::aux_type
    END_IF

        jmp     SetFileInfo
.endproc ; ApplyTypes

IterationCallback:
        .word   SELF_MODIFIED

.proc IterateSelectedFiles
        copy8   #0, index
        ptr := $06

        ;; Get win path
        jsr     JUMP_TABLE_GET_SEL_WIN
        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path,y
        dey
        bpl     :-

loop:
        lda     path
        pha

        ;; Get icon ptr
        lda     index
        jsr     JUMP_TABLE_GET_SEL_ICON
        addax   #IconEntry::name, ptr

        ;; Compose path
        ldx     path
        inx
        lda     #'/'
        sta     path,x

        ldy     #0
        lda     (ptr),y
        sta     len
:       iny
        inx
        lda     (ptr),y
        sta     path,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :-
        stx     path

        ;; Execute callback
        lda     index
        jsr     do_callback

        ;; Next
        pla
        sta     path

        inc     index
        jsr     JUMP_TABLE_GET_SEL_COUNT
        cmp     index
        bne     loop

        rts

do_callback:
        jmp     (IterationCallback)

index:  .byte   0
.endproc ; IterateSelectedFiles

.proc GetFileInfo
        copy8   #$A, gfi_params::param_count ; GET_FILE_INFO
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, gfi_params
        jcs     Abort
        rts
.endproc ; GetFileInfo

.proc SetFileInfo
        copy8   #7, gfi_params::param_count ; SET_FILE_INFO
        JUMP_TABLE_MLI_CALL SET_FILE_INFO, gfi_params
        jcs     Abort
        rts
.endproc ; SetFileInfo

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================

;;; ============================================================
;;; INVERT - Desk Accessory
;;;
;;; Inverts the screen.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Graphics Resources

event_params:   .tag MGTK::Event
grafport:       .tag MGTK::GrafPort
penXOR:         .byte   MGTK::penXOR
        DEFINE_RECT rect, 0, 0, kScreenWidth-1, kScreenHeight-1

;;; ============================================================
;;; DA Init

.proc Init
        jsr     Invert
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        ;; No yielding as we don't want the clock to refresh.
loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     exit
        jmp     loop

exit:   jmp     Invert
.endproc

;;; ============================================================
;;; Invert

.proc Invert
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

        DA_END_AUX_SEGMENT
;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================

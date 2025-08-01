;;; ============================================================
;;; Requires: `hex_digits` to be defined as "0123456789ABCDEF"
;;; ============================================================

;;; Populated by call to `ComposeFileTypeString`
str_file_type:
        PASCAL_STRING "$00"

;;; Input: A = ProDOS file type
;;; Output: `str_file_type` populated (3 chars, length prefixed)
;;;         "BIN", "SYS" etc if known, "$xx" otherwise
.proc ComposeFileTypeString
        sta     file_type

        ;; Search `type_table` for type
        ldy     #kNumFileTypes-1
:       lda     type_table,y
        file_type := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     found
        dey
        bpl     :-
        jmp     not_found

        ;; Found - copy string from `type_names_table`
found:  tya
        sta     add
        asl     a
        clc
        add := *+1
        adc     #SELF_MODIFIED_BYTE
        tay

        ldx     #0
:       lda     type_names_table,y
        sta     str_file_type+1,x
        iny
        inx
        cpx     #3
        bne     :-

        rts

        ;; Type not found - use generic "$xx"
not_found:
        copy8   #'$', str_file_type+1

        lda     file_type
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        copy8   hex_digits,x, str_file_type+2

        pla                     ; A = file_type
        and     #$0F
        tax
        copy8   hex_digits,x, str_file_type+3

        rts

;;; Map ProDOS file type to string (for listings/Get Info).
;;; If not found, $XX is used (like CATALOG).

        kNumFileTypes = 26
type_table:
        .byte   FT_TYPELESS   ; unknown
        .byte   FT_BAD        ; bad block
        .byte   FT_TEXT       ; text
        .byte   FT_BINARY     ; binary
        .byte   FT_FONT       ; font
        .byte   FT_GRAPHICS   ; graphics
        .byte   FT_DIRECTORY  ; directory
        .byte   FT_ADB        ; appleworks db
        .byte   FT_AWP        ; appleworks wp
        .byte   FT_ASP        ; appleworks sp
        .byte   FT_ANIMATION  ; animation
        .byte   FT_S16        ; IIgs application
        .byte   FT_PNT        ; IIgs Packed Super Hi-Res picture
        .byte   FT_PIC        ; IIgs Super Hi-Res picture
        .byte   FT_MUSIC      ; music
        .byte   FT_SOUND      ; sampled sound
        .byte   FT_SPEECH     ; speech
        .byte   FT_ARCHIVE    ; archival library
        .byte   FT_LINK       ; link
        .byte   FT_CMD        ; command
        .byte   FT_INT        ; intbasic
        .byte   FT_IVR        ; intbasic variables
        .byte   FT_BASIC      ; basic
        .byte   FT_VAR        ; applesoft variables
        .byte   FT_REL        ; rel
        .byte   FT_SYSTEM     ; system
        ASSERT_TABLE_SIZE type_table, kNumFileTypes

type_names_table:
        ;; Types marked with * are known to BASIC.SYSTEM.
        .byte   "NON" ; unknown
        .byte   "BAD" ; bad block
        .byte   "TXT" ; text *
        .byte   "BIN" ; binary *
        .byte   "FNT" ; font
        .byte   "FOT" ; graphics
        .byte   "DIR" ; directory *
        .byte   "ADB" ; appleworks db *
        .byte   "AWP" ; appleworks wp *
        .byte   "ASP" ; appleworks sp *
        .byte   "ANM" ; animation
        .byte   "S16" ; IIgs application
        .byte   "PNT" ; IIgs Packed Super Hi-Res picture
        .byte   "PIC" ; IIgs Super Hi-Res picture
        .byte   "MUS" ; music
        .byte   "SND" ; sampled sound
        .byte   "TTS" ; speech
        .byte   "LBR" ; archival library
        .byte   "LNK" ; link
        .byte   "CMD" ; command *
        .byte   "INT" ; basic *
        .byte   "IVR" ; variables *
        .byte   "BAS" ; basic *
        .byte   "VAR" ; variables *
        .byte   "REL" ; rel *
        .byte   "SYS" ; system *
        ASSERT_RECORD_TABLE_SIZE type_names_table, kNumFileTypes, 3

.endproc ; ComposeFileTypeString

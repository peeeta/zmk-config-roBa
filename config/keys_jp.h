#pragma once

// Japanese keyboard layout (JP106) keycode aliases for ZMK
// Maps ZMK keycodes to characters that appear on JP Windows layout

#define JP_QUOTE        AMPERSAND         // '  (LS(N7) → JP Shift+7 = ')
#define JP_DOUBLE_QUOTE AT_SIGN           // "  (LS(N2) → JP Shift+2 = ")
#define JP_AMPERSAND    CARET             // &  (LS(N6) → JP Shift+6 = &)
#define JP_EQUAL        UNDERSCORE        // =  (LS(MINUS) → JP Shift+- = =)
#define JP_CARET      EQUAL             // ^
#define JP_YEN        INT3              // ¥  (HID 0x89)
#define JP_PLUS       COLON             // +  (LS(SEMICOLON) → JP Shift+; = +)
#define JP_TILDE      PLUS              // ~  (LS(EQUAL) → JP Shift+^ = ~)
#define JP_PIPE       LS(INT3)          // |  (LS(0x89))
#define JP_AT         LEFT_BRACKET      // @
#define JP_COLON      SINGLE_QUOTE      // :
#define JP_ASTERISK   DOUBLE_QUOTES     // *  (LS(SINGLE_QUOTE) → JP Shift+: = *)
#define JP_BACKQUOTE  LEFT_BRACE        // `  (LS(LEFT_BRACKET) → JP Shift+@ = `)
#define JP_UNDERSCORE LS(INT1)          // _  (LS(0x87))
#define JP_LBRACKET   RIGHT_BRACKET     // [
#define JP_RBRACKET   BACKSLASH         // ]
#define JP_LPAREN     ASTERISK          // (  (LS(N8) → JP Shift+8 = ()
#define JP_RPAREN     LEFT_PARENTHESIS  // )  (LS(N9) → JP Shift+9 = ))
#define JP_LBRACE     RIGHT_BRACE       // {  (LS(RIGHT_BRACKET) → JP Shift+[ = {)
#define JP_RBRACE     PIPE              // }  (LS(BACKSLASH) → JP Shift+] = })
#define JP_KANA       LANGUAGE_1        // かな
#define JP_EISU       LANGUAGE_2        // 英数
#define JP_HANZEN     GRAVE             // 半角/全角

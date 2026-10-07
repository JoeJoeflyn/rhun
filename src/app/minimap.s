# minimap: a zoomed-out document preview at the editor's right edge, modeled on
# Zed's: every document line is a 3px row of tiny syntax-colored text, so the
# strip is a shrunken view of the code rather than a rescaled summary. When the
# document is taller than the strip the content scrolls under the thumb, exactly
# like Zed's calculate_minimap_top_offset. Pressing/dragging scrolls the editor.
.include "rhun.inc"

.equ ID_MINIMAP, 0x1006
.equ MM_LH, 3                   # px per document line on the map
.equ MM_PX, 3                   # baked glyph size
.equ MM_RUNS, 12                # colored runs per line, rest merges into the last
.equ MM_PREP, 4096              # syntax states warmed up per frame
.equ MM_PREP_MAX, 65536         # lines worth warming at all: bigger files stay plain past it

.bss
.p2align 3
mm_classes: .zero SB_SIZE       # per-byte syntax classes of the line being drawn
mm_face:    .zero FACE_SIZE     # the tiny text face
mm_keyfont: .quad 0             # g_font_code the face was built from

.text

# minimap_w() -> px reserved for the minimap, 0 when disabled
FN minimap_w
    cmp dword ptr [rip + cfg_minimap], 0
    je 1f
    mov eax, [rip + g_ed_w]
    xor edx, edx
    mov ecx, 10
    div ecx                         # ~1/10 of the editor
    M ecx, MI_64
    cmp eax, ecx
    jge 2f
    mov eax, ecx
2:  add ecx, ecx
    cmp eax, ecx
    jle 3f
    mov eax, ecx
3:  ret
1:  xor eax, eax
    ret

# mm_top256(doc, vis_lines, map_rows) -> first minimap line in 1/256 units.
# Zed's calculate_minimap_top_offset: the strip scrolls so its visible window
# tracks the editor's scroll fraction.
#   mm_top = clamp(scrolly / max(nlines - vis, 0), 0..1) * max(nlines - rows, 0)
mm_top256:
    PROLOGUE
    mov rbx, rdi                    # doc
    mov r12, rsi                    # vis (lines, qword)
    mov r13, rdx                    # rows
    mov rax, [rbx + DOC_nlines]
    mov r14, rax
    sub rax, r12                    # scrollable = nlines - vis
    test rax, rax
    jle .Lmt_zero                   # the whole file fits: no map scroll
    mov rcx, [rbx + DOC_scrolly]    # 1/256 lines
    # frac256 = min(scrolly, scrollable<<8): scroll fraction in 1/256
    mov rdx, rax
    shl rdx, 8
    cmp rcx, rdx
    cmova rcx, rdx                  # clamp to 1.0
    # mm_top256 = frac * max(nlines - rows, 0) / scrollable
    mov rdx, r14
    sub rdx, r13
    test rdx, rdx
    jle .Lmt_zero                   # map shows the whole file
    imul rcx, rdx                   # fits: 1/256 * lines << 2^63 range below
    # rcx = frac256 * (nlines - rows); divide by scrollable
    mov r15, rax                    # scrollable
    mov rax, rcx
    cqo
    idiv r15
    EPILOGUE
.Lmt_zero:
    xor eax, eax
    EPILOGUE

# mm_runs(doc, line, dst) -> eax runs (0 on a blank line), rdx text.
# dst: u32[MM_RUNS] packed start:16 | len:8 | class:8, positions in bytes.
mm_runs:
    PROLOGUE 48
    mov rbx, rdi
    mov r12, rsi                    # line
    mov r13, rdx                    # dst
    mov rdi, rbx
    mov rsi, r12
    call doc_line_text              # rax ptr, rdx len
    mov r14, rax                    # text
    mov r15, rdx                    # len
    # end: drop trailing \r \n
    mov rcx, r15
1:  test rcx, rcx
    jz 2f
    movzx eax, byte ptr [r14 + rcx - 1]
    cmp eax, 10
    je 3f
    cmp eax, 13
    jne 2f
3:  dec rcx
    jmp 1b
2:  mov [rsp], rcx                  # end
    # indent: first byte that is not space/tab
    xor ecx, ecx
4:  cmp rcx, [rsp]
    jae 5f
    movzx eax, byte ptr [r14 + rcx]
    cmp eax, ' '
    je 6f
    cmp eax, 9
    jne 5f
6:  inc rcx
    jmp 4b
5:  mov [rsp + 8], rcx              # indent
    cmp rcx, [rsp]
    jae .Lmr_none
    # real classes need a grammar, a prepared state and a sane length
    cmp qword ptr [rbx + DOC_lang], 0
    je .Lmr_plain
    cmp r12, [rbx + DOC_svalid]
    jae .Lmr_plain
    mov rax, [rsp]
    cmp rax, 2048
    ja .Lmr_plain
    lea rdi, [rip + mm_classes]
    mov qword ptr [rdi + SB_len], 0
    lea rsi, [rax + 16]
    call sb_reserve
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r14
    mov rcx, r15
    mov r8, [rip + mm_classes + SB_ptr]
    call syntax_line
    # merge equal classes into runs
    mov r8, [rip + mm_classes + SB_ptr]
    mov rcx, [rsp + 8]              # i = indent
    xor r9d, r9d                    # nrun
.Lmr_scan:
    cmp rcx, [rsp]
    jae .Lmr_done
    movzx eax, byte ptr [r8 + rcx]
    mov rdx, rcx
7:  inc rdx
    cmp rdx, [rsp]
    jae 8f
    cmp al, [r8 + rdx]
    je 7b
8:  cmp r9d, MM_RUNS
    jae .Lmr_extend
    mov esi, ecx
    shl esi, 16
    mov edi, edx
    sub edi, ecx
    cmp edi, 255
    jle 9f
    mov edi, 255
9:  shl edi, 8
    or esi, edi
    movzx eax, al
    or esi, eax
    mov [r13 + r9*4], esi
    inc r9d
    mov rcx, rdx
    jmp .Lmr_scan
.Lmr_extend:                        # run cap hit: stretch the last one to the end
    mov esi, [r13 + r9*4 - 4]
    mov eax, esi
    shr eax, 16
    mov edx, [rsp]
    sub edx, eax
    cmp edx, 255
    jle 10f
    mov edx, 255
10: and esi, 0xffff00ff
    mov edi, edx
    shl edi, 8
    or esi, edi
    mov [r13 + r9*4 - 4], esi
    jmp .Lmr_done
.Lmr_plain:                         # one text-colored run over the content
    mov ecx, [rsp + 8]
    mov edx, [rsp]
    sub edx, ecx
    cmp edx, 255
    jle 11f
    mov edx, 255
11: mov esi, ecx
    shl esi, 16
    mov edi, edx
    shl edi, 8
    or esi, edi
    or esi, C_TEXT
    mov [r13], esi
    mov eax, 1
    mov rdx, r14
    EPILOGUE
.Lmr_done:
    mov eax, r9d
    mov rdx, r14
    EPILOGUE
.Lmr_none:
    xor eax, eax
    EPILOGUE

# minimap_draw(doc): called from editor_draw inside the editor clip, after the
# scrollbars, so its strip lands left of the vertical one.
FN minimap_draw
    PROLOGUE 160
    mov rbx, rdi
    cmp dword ptr [rip + cfg_minimap], 0
    je .Lmm_ret
    mov rax, [rbx + DOC_nlines]
    test rax, rax
    jz .Lmm_ret
    cmp qword ptr [rbx + DOC_diff], 0 # no map on the diff view
    jne .Lmm_ret
    mov [rsp + 32], rax             # nlines
    call minimap_w
    test eax, eax
    jz .Lmm_ret
    mov [rsp + 4], eax              # map_w
    mov ecx, [rip + g_ed_x]
    add ecx, [rip + g_ed_w]
    sub ecx, [rip + g_mt + 4*MI_12]
    sub ecx, eax
    mov [rsp], ecx                  # map_x
    mov eax, [rip + g_ed_y]
    mov [rsp + 8], eax              # map_y
    mov eax, [rip + g_ed_h]
    cmp dword ptr [rip + hs_on], 0  # leave the hscrollbar its strip
    je 21f
    sub eax, [rip + g_mt + 4*MI_12]
21: mov [rsp + 12], eax             # map_h
    # rows and visible lines
    mov ecx, [rip + g_lh]
    test ecx, ecx
    jz .Lmm_ret
    mov eax, [rip + g_ed_h]
    xor edx, edx
    div ecx
    mov [rsp + 24], rax             # vis
    mov eax, [rsp + 12]
    xor edx, edx
    mov ecx, MM_LH
    div ecx
    mov [rsp + 16], rax             # nr
    # the strip's top line, Zed's offset math in 1/256 lines
    mov rdi, rbx
    mov rsi, [rsp + 24]
    mov rdx, [rsp + 16]
    call mm_top256
    mov [rsp + 48], rax             # mm_top256
    # the tiny face rides g_font_code; rebuild it if the font changed
    mov rax, [rip + g_font_code]
    cmp rax, [rip + mm_keyfont]
    je 22f
    mov [rip + mm_keyfont], rax
    lea rdi, [rip + mm_face]
    mov rsi, rax
    mov edx, MM_PX
    call face_init
22: # input: press/drag scrolls the document to the pressed line
    mov edi, ID_MINIMAP
    mov esi, [rsp]
    mov edx, [rsp + 8]
    mov ecx, [rsp + 4]
    mov r8d, [rsp + 12]
    call ui_btn
    mov [rsp + 96], eax             # bits
    test eax, UB_PRESS | UB_HELD
    jz 1f
    mov eax, [rip + g_my]
    sub eax, [rsp + 8]
    # pressed line = mm_top + (my - map_y)/MM_LH, all in 1/256
    shl eax, 8
    xor edx, edx
    mov ecx, MM_LH
    div ecx
    movsxd rax, eax
    add rax, [rsp + 48]
    sar rax, 8                      # line under the pointer
    cmp rax, [rsp + 32]
    jl 2f
    mov rax, [rsp + 32]
    dec rax
2:  mov rcx, [rsp + 24]
    shr rcx, 1                      # half the visible lines
    sub rax, rcx                    # center the view on it
    shl rax, 8
    mov [rbx + DOC_scrolly], rax
    mov rdi, rbx
    call clamp_scroll
    mov dword ptr [rip + g_dirty], 1
1:  mov rdi, rbx
    call git_doc_marks
    mov [rsp + 40], rax             # GM_* per line or 0
    # warm syntax states a bounded way ahead so deeper rows get colors over time
    cmp qword ptr [rbx + DOC_lang], 0
    je 3f
    mov rax, [rbx + DOC_svalid]
    cmp rax, MM_PREP_MAX
    jae 3f
    cmp rax, [rsp + 32]
    jae 3f
    add rax, MM_PREP
    cmp rax, [rsp + 32]
    jbe 23f
    mov rax, [rsp + 32]
23: mov rdi, rbx
    mov rsi, rax
    call syntax_prepare
3:  # clip to the strip, then draw one row per document line
    mov edi, [rsp]
    mov esi, [rsp + 8]
    mov edx, [rsp + 4]
    mov ecx, [rsp + 12]
    call gfx_clip_push
    mov eax, [rip + mm_face + FACE_ascent]
    mov [rsp + 84], eax             # baseline inside a row
    mov eax, [rip + mm_face + FACE_cellw]
    mov [rsp + 88], eax             # px advance per char
    mov rax, [rsp + 48]
    sar rax, 8
    mov [rsp + 56], rax             # first line
    mov rax, [rsp + 48]
    and eax, 255
    imul eax, MM_LH
    shr eax, 8                      # px of the top line scrolled off
    neg eax
    mov [rsp + 80], eax             # y0 = -frac_px
    xor r12d, r12d                  # row
.Lmm_row:
    lea eax, [r12 + r12]
    add eax, r12d                   # row * 3
    add eax, [rsp + 80]             # + y0
    mov [rsp + 76], eax             # y offset inside the strip
    cmp eax, [rsp + 12]
    jge .Lmm_rows_done              # past the strip bottom
    mov rax, [rsp + 56]
    add rax, r12
    cmp rax, [rsp + 32]
    jae .Lmm_rows_done              # past the document end
    mov [rsp + 64], rax             # line
    mov edi, [rsp]
    add edi, [rsp + 4]
    sub edi, 1                      # marks sliver at the strip's right edge
    mov [rsp + 92], edi
    mov rax, [rsp + 40]
    test rax, rax
    jz 4f
    mov rcx, [rsp + 64]
    movzx r9d, byte ptr [rax + rcx] # this line's git mark
    test r9d, GM_ADD | GM_MOD | GM_DELUP | GM_DELDOWN
    jz 4f
    COLOR r8d, T_GIT_ADD
    test r9d, GM_MOD
    jz 30f
    COLOR r8d, T_GIT_MOD
30: test r9d, GM_DELUP | GM_DELDOWN
    jz 31f
    COLOR r8d, T_GIT_DEL
31: mov edi, [rsp + 92]
    mov esi, [rsp + 8]
    add esi, [rsp + 76]
    M edx, MI_3
    mov ecx, MM_LH
    call gfx_fill
4:  mov rdi, rbx
    mov rsi, [rsp + 64]
    lea rdx, [rsp + 104]
    call mm_runs
    test eax, eax
    jz .Lmm_next
    mov r13d, eax                   # nruns
    mov r15, rdx                    # text
    mov eax, [rsp + 104]
    shr eax, 16                     # first run's indent
    imul eax, [rsp + 88]
    add eax, [rsp]                  # + map_x
    mov [rsp + 72], eax             # pen
    xor r14d, r14d                  # run
.Lmm_run:
    cmp r14d, r13d
    jae .Lmm_next
    mov eax, [rsp + r14*4 + 104]
    mov r10d, eax
    shr r10d, 8
    and r10d, 0xff                  # len
    movzx r8d, al                   # class
    # color = theme[T_SYN + class] at ~85%
    lea r9d, [r8 + T_SYN]
    lea rdx, [rip + g_theme]
    mov r9d, [rdx + r9*4]
    and r9d, 0x00ffffff
    or r9d, 0xd8000000
    lea rdi, [rip + mm_face]
    mov esi, [rsp + 72]             # pen
    mov edx, [rsp + 8]
    add edx, [rsp + 76]             # map_y + y_off
    add edx, [rsp + 84]             # baseline
    mov eax, [rsp + r14*4 + 104]
    shr eax, 16                     # start again (clobbered above)
    lea rcx, [r15 + rax]            # text + start
    mov r8d, r10d                   # len
    call text_draw
    mov [rsp + 72], eax             # runs are contiguous: pen carries over
    inc r14d
    jmp .Lmm_run
.Lmm_next:
    inc r12d
    jmp .Lmm_row
.Lmm_rows_done:
    call gfx_clip_pop
    # viewport thumb: [first_vis, first_vis + vis) in map px
    mov rax, [rbx + DOC_scrolly]    # 1/256 lines
    sub rax, [rsp + 48]             # above the strip's top line
    imul rax, MM_LH
    sar rax, 8                      # px offset from map_y
    add eax, [rsp + 8]
    mov ecx, [rsp + 8]
    cmp eax, ecx
    cmovl eax, ecx                  # keep it inside the map
    mov r14d, eax                   # vy
    mov rax, [rsp + 24]
    imul rax, MM_LH                 # vh
    M ecx, MI_8
    cmp eax, ecx
    cmovl eax, ecx
    mov r15d, eax
    mov eax, [rsp + 8]
    add eax, [rsp + 12]
    sub eax, r14d                   # keep it inside the map
    cmp r15d, eax
    cmovg r15d, eax
    mov edi, [rsp]
    mov esi, r14d
    mov edx, [rsp + 4]
    mov ecx, r15d
    COLOR r8d, T_FG
    and r8d, 0x00ffffff
    or r8d, 0x14000000
    call gfx_fill
    mov edi, [rsp]
    mov esi, r14d
    mov edx, [rsp + 4]
    mov ecx, r15d
    xor r8d, r8d
    COLOR r9d, T_FG
    and r9d, 0x00ffffff
    or r9d, 0x3c000000
    xor eax, eax                    # transparent fill: border only
    push rax
    push rax
    call gfx_frame
    add rsp, 16
.Lmm_ret:
    EPILOGUE

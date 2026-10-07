# file-type icons: name/extension -> explorer icon + theme color slot
.include "rhun.inc"

.text

# file_icon(name cstr) -> eax icon, edx theme slot: the icon an explorer row gets
FN file_icon
    PROLOGUE
    mov rbx, rdi
    call strlen
    mov r13, rax
    mov rdi, rbx
    mov rsi, r13
    call path_ext                  # rax ptr, rdx len (0 for no/dotfile extension)
    mov r14, rax
    mov r15, rdx
    lea r12, [rip + ficon_table]
1:  movzx ecx, byte ptr [r12 + 3]  # pattern length, 0 ends the table
    test cl, cl
    jz 8f
    mov rdi, r14                   # kind 0: match the extension
    mov rsi, r15
    cmp byte ptr [r12 + 2], 0
    je 2f
    mov rdi, rbx                   # kind 1: match the whole name
    mov rsi, r13
2:  lea rdx, [r12 + 4]
    call str_ieq
    test eax, eax
    jnz 9f
    movzx eax, byte ptr [r12 + 3]
    lea r12, [r12 + rax + 4]
    jmp 1b
8:  mov eax, IC_FILE
    mov edx, T_MUTED
    EPILOGUE
9:  movzx eax, byte ptr [r12]
    movzx edx, byte ptr [r12 + 1]
    EPILOGUE

# table row: icon, theme slot, kind (0 ext, 1 exact name), inline pattern
.macro FIENT icon, slot, kind, txt
    .byte \icon, \slot, \kind, 999f - 998f
998:.ascii "\txt"
999:
.endm

.section .rodata
.p2align 3
ficon_table:
    # exact names first: a file's name beats its extension
    FIENT IC_BRANCH, T_GIT_MOD, 1, .gitignore
    FIENT IC_BRANCH, T_GIT_MOD, 1, .gitattributes
    FIENT IC_BRANCH, T_GIT_MOD, 1, .gitmodules
    FIENT IC_BRANCH, T_GIT_MOD, 1, .gitconfig
    FIENT IC_F_ARC, T_TERM+4, 1, .dockerignore
    FIENT IC_F_ARC, T_TERM+4, 1, dockerfile
    FIENT IC_F_ARC, T_TERM+4, 1, containerfile
    FIENT IC_F_CFG, T_WARNING, 1, makefile
    FIENT IC_F_CFG, T_WARNING, 1, gnumakefile
    FIENT IC_F_CFG, T_WARNING, 1, cmakelists.txt
    FIENT IC_F_CFG, T_WARNING, 1, meson.build
    FIENT IC_F_CFG, T_WARNING, 1, build.ninja
    FIENT IC_F_CFG, T_WARNING, 1, vagrantfile
    FIENT IC_F_CFG, T_WARNING, 1, gemfile
    FIENT IC_F_CFG, T_WARNING, 1, rakefile
    FIENT IC_F_CFG, T_WARNING, 1, justfile
    FIENT IC_F_CFG, T_WARNING, 1, brewfile
    FIENT IC_F_CFG, T_WARNING, 1, procfile
    FIENT IC_F_CFG, T_WARNING, 1, go.mod
    FIENT IC_F_CFG, T_WARNING, 1, go.sum
    FIENT IC_F_CFG, T_WARNING, 1, .env
    FIENT IC_F_CFG, T_WARNING, 1, .envrc
    FIENT IC_F_CFG, T_WARNING, 1, .editorconfig
    FIENT IC_F_CFG, T_WARNING, 1, .npmrc
    FIENT IC_F_CFG, T_WARNING, 1, .nvmrc
    FIENT IC_F_CFG, T_WARNING, 1, .vimrc
    FIENT IC_F_CFG, T_WARNING, 1, .clang-format
    FIENT IC_TERMINAL, T_GIT_ADD, 1, .bashrc
    FIENT IC_TERMINAL, T_GIT_ADD, 1, .zshrc
    FIENT IC_TERMINAL, T_GIT_ADD, 1, .bash_profile
    FIENT IC_TERMINAL, T_GIT_ADD, 1, .zprofile
    FIENT IC_TERMINAL, T_GIT_ADD, 1, .profile
    FIENT IC_TERMINAL, T_GIT_ADD, 1, .xinitrc
    FIENT IC_F_DOC, T_MUTED, 1, license
    FIENT IC_F_DOC, T_MUTED, 1, licence
    FIENT IC_F_DOC, T_MUTED, 1, copying
    FIENT IC_F_DOC, T_MUTED, 1, notice
    FIENT IC_F_DOC, T_MUTED, 1, readme
    FIENT IC_F_DOC, T_MUTED, 1, changelog
    FIENT IC_F_DOC, T_MUTED, 1, authors
    FIENT IC_F_DOC, T_MUTED, 1, contributors
    # shell scripts and executables
    FIENT IC_TERMINAL, T_GIT_ADD, 0, sh
    FIENT IC_TERMINAL, T_GIT_ADD, 0, bash
    FIENT IC_TERMINAL, T_GIT_ADD, 0, zsh
    FIENT IC_TERMINAL, T_GIT_ADD, 0, fish
    FIENT IC_TERMINAL, T_GIT_ADD, 0, ksh
    FIENT IC_TERMINAL, T_GIT_ADD, 0, csh
    FIENT IC_TERMINAL, T_GIT_ADD, 0, ps1
    FIENT IC_TERMINAL, T_GIT_ADD, 0, psm1
    FIENT IC_TERMINAL, T_GIT_ADD, 0, bat
    FIENT IC_TERMINAL, T_GIT_ADD, 0, cmd
    FIENT IC_TERMINAL, T_GIT_ADD, 0, com
    FIENT IC_TERMINAL, T_GIT_ADD, 0, exe
    FIENT IC_TERMINAL, T_GIT_ADD, 0, msi
    FIENT IC_TERMINAL, T_GIT_ADD, 0, appimage
    FIENT IC_TERMINAL, T_GIT_ADD, 0, run
    FIENT IC_TERMINAL, T_GIT_ADD, 0, bin
    FIENT IC_TERMINAL, T_GIT_ADD, 0, so
    FIENT IC_TERMINAL, T_GIT_ADD, 0, dll
    FIENT IC_TERMINAL, T_GIT_ADD, 0, dylib
    FIENT IC_TERMINAL, T_GIT_ADD, 0, o
    FIENT IC_TERMINAL, T_GIT_ADD, 0, a
    FIENT IC_TERMINAL, T_GIT_ADD, 0, obj
    FIENT IC_TERMINAL, T_GIT_ADD, 0, lib
    FIENT IC_TERMINAL, T_GIT_ADD, 0, wasm
    FIENT IC_TERMINAL, T_GIT_ADD, 0, class
    FIENT IC_TERMINAL, T_GIT_ADD, 0, pyc
    FIENT IC_TERMINAL, T_GIT_ADD, 0, pyo
    # source code
    FIENT IC_F_CODE, T_FG, 0, s
    FIENT IC_F_CODE, T_FG, 0, asm
    FIENT IC_F_CODE, T_FG, 0, nasm
    FIENT IC_F_CODE, T_TERM+4, 0, c
    FIENT IC_F_CODE, T_TERM+4, 0, h
    FIENT IC_F_CODE, T_TERM+4, 0, cc
    FIENT IC_F_CODE, T_TERM+4, 0, cpp
    FIENT IC_F_CODE, T_TERM+4, 0, cxx
    FIENT IC_F_CODE, T_TERM+4, 0, hpp
    FIENT IC_F_CODE, T_TERM+4, 0, hh
    FIENT IC_F_CODE, T_TERM+4, 0, hxx
    FIENT IC_F_CODE, T_TERM+4, 0, i
    FIENT IC_F_CODE, T_TERM+4, 0, ii
    FIENT IC_F_CODE, T_TERM+4, 0, m
    FIENT IC_F_CODE, T_TERM+4, 0, mm
    FIENT IC_F_CODE, T_GIT_MOD, 0, rs
    FIENT IC_F_CODE, T_TERM+4, 0, py
    FIENT IC_F_CODE, T_TERM+4, 0, pyi
    FIENT IC_F_CODE, T_TERM+4, 0, pyw
    FIENT IC_F_CODE, T_TERM+4, 0, ipynb
    FIENT IC_F_CODE, T_WARNING, 0, js
    FIENT IC_F_CODE, T_WARNING, 0, mjs
    FIENT IC_F_CODE, T_WARNING, 0, cjs
    FIENT IC_F_CODE, T_WARNING, 0, jsx
    FIENT IC_F_CODE, T_TERM+4, 0, ts
    FIENT IC_F_CODE, T_TERM+4, 0, mts
    FIENT IC_F_CODE, T_TERM+4, 0, cts
    FIENT IC_F_CODE, T_TERM+4, 0, tsx
    FIENT IC_F_CODE, T_GIT_ADD, 0, vue
    FIENT IC_F_CODE, T_GIT_MOD, 0, svelte
    FIENT IC_F_CODE, T_TERM+5, 0, astro
    FIENT IC_F_CODE, T_GIT_MOD, 0, html
    FIENT IC_F_CODE, T_GIT_MOD, 0, htm
    FIENT IC_F_CODE, T_GIT_MOD, 0, xhtml
    FIENT IC_F_CODE, T_TERM+4, 0, css
    FIENT IC_F_CODE, T_TERM+5, 0, scss
    FIENT IC_F_CODE, T_TERM+5, 0, sass
    FIENT IC_F_CODE, T_TERM+4, 0, less
    FIENT IC_F_CODE, T_TERM+4, 0, styl
    FIENT IC_F_CODE, T_GIT_MOD, 0, java
    FIENT IC_F_CODE, T_TERM+6, 0, go
    FIENT IC_F_CODE, T_ERROR, 0, rb
    FIENT IC_F_CODE, T_ERROR, 0, erb
    FIENT IC_F_CODE, T_TERM+5, 0, php
    FIENT IC_F_CODE, T_TERM+5, 0, phtml
    FIENT IC_F_CODE, T_TERM+5, 0, cs
    FIENT IC_F_CODE, T_TERM+5, 0, csx
    FIENT IC_F_CODE, T_GIT_MOD, 0, swift
    FIENT IC_F_CODE, T_TERM+5, 0, kt
    FIENT IC_F_CODE, T_TERM+5, 0, kts
    FIENT IC_F_CODE, T_ERROR, 0, scala
    FIENT IC_F_CODE, T_ERROR, 0, sc
    FIENT IC_F_CODE, T_GIT_ADD, 0, clj
    FIENT IC_F_CODE, T_GIT_ADD, 0, cljs
    FIENT IC_F_CODE, T_GIT_ADD, 0, edn
    FIENT IC_F_CODE, T_TERM+5, 0, ex
    FIENT IC_F_CODE, T_TERM+5, 0, exs
    FIENT IC_F_CODE, T_TERM+5, 0, eex
    FIENT IC_F_CODE, T_TERM+5, 0, heex
    FIENT IC_F_CODE, T_ERROR, 0, erl
    FIENT IC_F_CODE, T_ERROR, 0, hrl
    FIENT IC_F_CODE, T_TERM+5, 0, hs
    FIENT IC_F_CODE, T_TERM+5, 0, lhs
    FIENT IC_F_CODE, T_GIT_MOD, 0, ml
    FIENT IC_F_CODE, T_GIT_MOD, 0, mli
    FIENT IC_F_CODE, T_TERM+4, 0, fs
    FIENT IC_F_CODE, T_TERM+4, 0, fsx
    FIENT IC_F_CODE, T_TERM+5, 0, f
    FIENT IC_F_CODE, T_TERM+5, 0, f90
    FIENT IC_F_CODE, T_TERM+5, 0, f95
    FIENT IC_F_CODE, T_TERM+5, 0, for
    FIENT IC_F_CODE, T_FG, 0, pas
    FIENT IC_F_CODE, T_FG, 0, pp
    FIENT IC_F_CODE, T_FG, 0, dpr
    FIENT IC_F_CODE, T_TERM+4, 0, lua
    FIENT IC_F_CODE, T_GIT_ADD, 0, vim
    FIENT IC_F_CODE, T_TERM+6, 0, pl
    FIENT IC_F_CODE, T_TERM+6, 0, pm
    FIENT IC_F_CODE, T_TERM+4, 0, r
    FIENT IC_F_CODE, T_TERM+4, 0, rmd
    FIENT IC_F_CODE, T_TERM+5, 0, jl
    FIENT IC_F_CODE, T_WARNING, 0, nim
    FIENT IC_F_CODE, T_GIT_MOD, 0, zig
    FIENT IC_F_CODE, T_TERM+4, 0, v
    FIENT IC_F_CODE, T_FG, 0, sv
    FIENT IC_F_CODE, T_FG, 0, svh
    FIENT IC_F_CODE, T_FG, 0, vhd
    FIENT IC_F_CODE, T_FG, 0, vhdl
    FIENT IC_F_CODE, T_ERROR, 0, d
    FIENT IC_F_CODE, T_TERM+6, 0, dart
    FIENT IC_F_CODE, T_FG, 0, cr
    FIENT IC_F_CODE, T_TERM+6, 0, groovy
    FIENT IC_F_CODE, T_GIT_MOD, 0, coffee
    FIENT IC_F_CODE, T_TERM+4, 0, elm
    FIENT IC_F_CODE, T_FG, 0, purs
    FIENT IC_F_CODE, T_FG, 0, sol
    FIENT IC_F_CODE, T_TERM+4, 0, move
    FIENT IC_F_CODE, T_FG, 0, proto
    FIENT IC_F_CODE, T_TERM+4, 0, ada
    FIENT IC_F_CODE, T_TERM+4, 0, adb
    FIENT IC_F_CODE, T_TERM+4, 0, tcl
    FIENT IC_F_CODE, T_FG, 0, awk
    FIENT IC_F_CODE, T_TERM+5, 0, nu
    FIENT IC_F_CODE, T_TERM+5, 0, vala
    FIENT IC_F_CODE, T_TERM+5, 0, lisp
    FIENT IC_F_CODE, T_TERM+5, 0, el
    FIENT IC_F_CODE, T_TERM+5, 0, scm
    FIENT IC_F_CODE, T_ERROR, 0, rkt
    FIENT IC_F_CODE, T_GIT_MOD, 0, hx
    FIENT IC_F_CODE, T_GIT_ADD, 0, cu
    FIENT IC_F_CODE, T_TERM+6, 0, ino
    FIENT IC_F_CODE, T_TERM+5, 0, wat
    FIENT IC_F_CODE, T_TERM+5, 0, graphql
    FIENT IC_F_CODE, T_TERM+5, 0, gql
    FIENT IC_F_CODE, T_TERM+4, 0, prisma
    FIENT IC_F_CODE, T_GIT_MOD, 0, hbs
    FIENT IC_F_CODE, T_GIT_MOD, 0, mustache
    FIENT IC_F_CODE, T_GIT_MOD, 0, twig
    FIENT IC_F_CODE, T_GIT_MOD, 0, njk
    FIENT IC_F_CODE, T_GIT_MOD, 0, jinja
    FIENT IC_F_CODE, T_GIT_MOD, 0, jinja2
    FIENT IC_F_CODE, T_GIT_MOD, 0, tpl
    FIENT IC_F_CODE, T_GIT_MOD, 0, haml
    FIENT IC_F_CODE, T_GIT_MOD, 0, slim
    # markup/config
    FIENT IC_F_CFG, T_WARNING, 0, json
    FIENT IC_F_CFG, T_WARNING, 0, jsonc
    FIENT IC_F_CFG, T_WARNING, 0, json5
    FIENT IC_F_CFG, T_WARNING, 0, jsonl
    FIENT IC_F_CFG, T_WARNING, 0, ndjson
    FIENT IC_F_CFG, T_WARNING, 0, toml
    FIENT IC_F_CFG, T_WARNING, 0, yaml
    FIENT IC_F_CFG, T_WARNING, 0, yml
    FIENT IC_F_CFG, T_WARNING, 0, ini
    FIENT IC_F_CFG, T_WARNING, 0, cfg
    FIENT IC_F_CFG, T_WARNING, 0, conf
    FIENT IC_F_CFG, T_WARNING, 0, config
    FIENT IC_F_CFG, T_WARNING, 0, cnf
    FIENT IC_F_CFG, T_WARNING, 0, properties
    FIENT IC_F_CFG, T_WARNING, 0, env
    FIENT IC_F_CFG, T_WARNING, 0, xml
    FIENT IC_F_CFG, T_WARNING, 0, xsd
    FIENT IC_F_CFG, T_WARNING, 0, xsl
    FIENT IC_F_CFG, T_WARNING, 0, xslt
    FIENT IC_F_CFG, T_WARNING, 0, dtd
    FIENT IC_F_CFG, T_WARNING, 0, plist
    FIENT IC_F_CFG, T_WARNING, 0, desktop
    FIENT IC_F_CFG, T_WARNING, 0, service
    FIENT IC_F_CFG, T_WARNING, 0, socket
    FIENT IC_F_CFG, T_WARNING, 0, timer
    FIENT IC_F_CFG, T_WARNING, 0, mount
    FIENT IC_F_CFG, T_WARNING, 0, automount
    FIENT IC_F_CFG, T_WARNING, 0, tf
    FIENT IC_F_CFG, T_WARNING, 0, tfvars
    FIENT IC_F_CFG, T_WARNING, 0, hcl
    FIENT IC_F_CFG, T_WARNING, 0, bazel
    FIENT IC_F_CFG, T_WARNING, 0, bzl
    FIENT IC_F_CFG, T_WARNING, 0, cmake
    FIENT IC_F_CFG, T_WARNING, 0, mk
    FIENT IC_F_CFG, T_WARNING, 0, am
    FIENT IC_F_CFG, T_WARNING, 0, gradle
    FIENT IC_F_CFG, T_WARNING, 0, sbt
    FIENT IC_F_CFG, T_WARNING, 0, spec
    FIENT IC_F_CFG, T_WARNING, 0, ebuild
    FIENT IC_F_CFG, T_WARNING, 0, webmanifest
    FIENT IC_F_CFG, T_WARNING, 0, lock
    # documents
    FIENT IC_F_DOC, T_MUTED, 0, txt
    FIENT IC_F_DOC, T_MUTED, 0, md
    FIENT IC_F_DOC, T_MUTED, 0, markdown
    FIENT IC_F_DOC, T_MUTED, 0, mdown
    FIENT IC_F_DOC, T_MUTED, 0, rst
    FIENT IC_F_DOC, T_MUTED, 0, adoc
    FIENT IC_F_DOC, T_MUTED, 0, asciidoc
    FIENT IC_F_DOC, T_MUTED, 0, org
    FIENT IC_F_DOC, T_MUTED, 0, tex
    FIENT IC_F_DOC, T_MUTED, 0, latex
    FIENT IC_F_DOC, T_MUTED, 0, sty
    FIENT IC_F_DOC, T_MUTED, 0, cls
    FIENT IC_F_DOC, T_MUTED, 0, bib
    FIENT IC_F_DOC, T_MUTED, 0, doc
    FIENT IC_F_DOC, T_MUTED, 0, docx
    FIENT IC_F_DOC, T_MUTED, 0, odt
    FIENT IC_F_DOC, T_MUTED, 0, ott
    FIENT IC_F_DOC, T_MUTED, 0, rtf
    FIENT IC_F_DOC, T_MUTED, 0, epub
    FIENT IC_F_DOC, T_MUTED, 0, mobi
    FIENT IC_F_DOC, T_MUTED, 0, log
    FIENT IC_F_DOC, T_MUTED, 0, me
    FIENT IC_F_DOC, T_MUTED, 0, nfo
    FIENT IC_F_DOC, T_MUTED, 0, textile
    FIENT IC_F_DOC, T_MUTED, 0, pod
    FIENT IC_F_DOC, T_MUTED, 0, wiki
    FIENT IC_F_DOC, T_MUTED, 0, po
    FIENT IC_F_DOC, T_ERROR, 0, pdf
    # images
    FIENT IC_F_IMG, T_TERM+5, 0, png
    FIENT IC_F_IMG, T_TERM+5, 0, jpg
    FIENT IC_F_IMG, T_TERM+5, 0, jpeg
    FIENT IC_F_IMG, T_TERM+5, 0, jpe
    FIENT IC_F_IMG, T_TERM+5, 0, gif
    FIENT IC_F_IMG, T_TERM+5, 0, webp
    FIENT IC_F_IMG, T_TERM+5, 0, bmp
    FIENT IC_F_IMG, T_TERM+5, 0, dib
    FIENT IC_F_IMG, T_TERM+5, 0, ico
    FIENT IC_F_IMG, T_TERM+5, 0, cur
    FIENT IC_F_IMG, T_TERM+5, 0, icns
    FIENT IC_F_IMG, T_TERM+5, 0, svg
    FIENT IC_F_IMG, T_TERM+5, 0, svgz
    FIENT IC_F_IMG, T_TERM+5, 0, tif
    FIENT IC_F_IMG, T_TERM+5, 0, tiff
    FIENT IC_F_IMG, T_TERM+5, 0, avif
    FIENT IC_F_IMG, T_TERM+5, 0, heic
    FIENT IC_F_IMG, T_TERM+5, 0, heif
    FIENT IC_F_IMG, T_TERM+5, 0, raw
    FIENT IC_F_IMG, T_TERM+5, 0, cr2
    FIENT IC_F_IMG, T_TERM+5, 0, nef
    FIENT IC_F_IMG, T_TERM+5, 0, arw
    FIENT IC_F_IMG, T_TERM+5, 0, dng
    FIENT IC_F_IMG, T_TERM+5, 0, exr
    FIENT IC_F_IMG, T_TERM+5, 0, hdr
    FIENT IC_F_IMG, T_TERM+5, 0, ppm
    FIENT IC_F_IMG, T_TERM+5, 0, pgm
    FIENT IC_F_IMG, T_TERM+5, 0, pbm
    FIENT IC_F_IMG, T_TERM+5, 0, pnm
    FIENT IC_F_IMG, T_TERM+5, 0, xpm
    FIENT IC_F_IMG, T_TERM+5, 0, psd
    FIENT IC_F_IMG, T_TERM+5, 0, xcf
    FIENT IC_F_IMG, T_TERM+5, 0, kra
    FIENT IC_F_IMG, T_TERM+5, 0, ai
    FIENT IC_F_IMG, T_TERM+5, 0, eps
    # audio/video
    FIENT IC_F_MEDIA, T_TERM+1, 0, mp3
    FIENT IC_F_MEDIA, T_TERM+1, 0, wav
    FIENT IC_F_MEDIA, T_TERM+1, 0, flac
    FIENT IC_F_MEDIA, T_TERM+1, 0, ogg
    FIENT IC_F_MEDIA, T_TERM+1, 0, oga
    FIENT IC_F_MEDIA, T_TERM+1, 0, m4a
    FIENT IC_F_MEDIA, T_TERM+1, 0, aac
    FIENT IC_F_MEDIA, T_TERM+1, 0, opus
    FIENT IC_F_MEDIA, T_TERM+1, 0, mid
    FIENT IC_F_MEDIA, T_TERM+1, 0, midi
    FIENT IC_F_MEDIA, T_TERM+1, 0, mod
    FIENT IC_F_MEDIA, T_TERM+1, 0, xm
    FIENT IC_F_MEDIA, T_TERM+1, 0, aiff
    FIENT IC_F_MEDIA, T_TERM+1, 0, aif
    FIENT IC_F_MEDIA, T_TERM+1, 0, wma
    FIENT IC_F_MEDIA, T_TERM+1, 0, mp4
    FIENT IC_F_MEDIA, T_TERM+1, 0, m4v
    FIENT IC_F_MEDIA, T_TERM+1, 0, mkv
    FIENT IC_F_MEDIA, T_TERM+1, 0, mov
    FIENT IC_F_MEDIA, T_TERM+1, 0, avi
    FIENT IC_F_MEDIA, T_TERM+1, 0, webm
    FIENT IC_F_MEDIA, T_TERM+1, 0, mpg
    FIENT IC_F_MEDIA, T_TERM+1, 0, mpeg
    FIENT IC_F_MEDIA, T_TERM+1, 0, wmv
    FIENT IC_F_MEDIA, T_TERM+1, 0, flv
    FIENT IC_F_MEDIA, T_TERM+1, 0, vob
    FIENT IC_F_MEDIA, T_TERM+1, 0, 3gp
    FIENT IC_F_MEDIA, T_TERM+1, 0, m2ts
    FIENT IC_F_MEDIA, T_TERM+1, 0, rm
    FIENT IC_F_MEDIA, T_TERM+1, 0, ogv
    # archives/packages
    FIENT IC_F_ARC, T_GIT_MOD, 0, zip
    FIENT IC_F_ARC, T_GIT_MOD, 0, tar
    FIENT IC_F_ARC, T_GIT_MOD, 0, gz
    FIENT IC_F_ARC, T_GIT_MOD, 0, tgz
    FIENT IC_F_ARC, T_GIT_MOD, 0, bz2
    FIENT IC_F_ARC, T_GIT_MOD, 0, tbz2
    FIENT IC_F_ARC, T_GIT_MOD, 0, xz
    FIENT IC_F_ARC, T_GIT_MOD, 0, txz
    FIENT IC_F_ARC, T_GIT_MOD, 0, 7z
    FIENT IC_F_ARC, T_GIT_MOD, 0, rar
    FIENT IC_F_ARC, T_GIT_MOD, 0, zst
    FIENT IC_F_ARC, T_GIT_MOD, 0, lz
    FIENT IC_F_ARC, T_GIT_MOD, 0, lz4
    FIENT IC_F_ARC, T_GIT_MOD, 0, jar
    FIENT IC_F_ARC, T_GIT_MOD, 0, war
    FIENT IC_F_ARC, T_GIT_MOD, 0, deb
    FIENT IC_F_ARC, T_GIT_MOD, 0, rpm
    FIENT IC_F_ARC, T_GIT_MOD, 0, apk
    FIENT IC_F_ARC, T_GIT_MOD, 0, dmg
    FIENT IC_F_ARC, T_GIT_MOD, 0, pkg
    FIENT IC_F_ARC, T_GIT_MOD, 0, iso
    FIENT IC_F_ARC, T_GIT_MOD, 0, img
    FIENT IC_F_ARC, T_GIT_MOD, 0, cab
    FIENT IC_F_ARC, T_GIT_MOD, 0, nupkg
    FIENT IC_F_ARC, T_GIT_MOD, 0, gem
    FIENT IC_F_ARC, T_GIT_MOD, 0, egg
    FIENT IC_F_ARC, T_GIT_MOD, 0, whl
    FIENT IC_F_ARC, T_GIT_MOD, 0, crate
    FIENT IC_F_ARC, T_GIT_MOD, 0, vsix
    FIENT IC_F_ARC, T_GIT_MOD, 0, snap
    FIENT IC_F_ARC, T_GIT_MOD, 0, flatpak
    FIENT IC_F_ARC, T_GIT_MOD, 0, cpio
    # databases/data
    FIENT IC_F_DB, T_TERM+4, 0, db
    FIENT IC_F_DB, T_TERM+4, 0, sqlite
    FIENT IC_F_DB, T_TERM+4, 0, sqlite3
    FIENT IC_F_DB, T_TERM+4, 0, sql
    FIENT IC_F_DB, T_TERM+4, 0, mdb
    FIENT IC_F_DB, T_TERM+4, 0, accdb
    FIENT IC_F_DB, T_TERM+4, 0, db3
    FIENT IC_F_DB, T_TERM+4, 0, duckdb
    FIENT IC_F_DB, T_TERM+4, 0, parquet
    # keys/certs
    FIENT IC_F_LOCK, T_WARNING, 0, pem
    FIENT IC_F_LOCK, T_WARNING, 0, key
    FIENT IC_F_LOCK, T_WARNING, 0, crt
    FIENT IC_F_LOCK, T_WARNING, 0, cer
    FIENT IC_F_LOCK, T_WARNING, 0, der
    FIENT IC_F_LOCK, T_WARNING, 0, pub
    FIENT IC_F_LOCK, T_WARNING, 0, asc
    FIENT IC_F_LOCK, T_WARNING, 0, gpg
    FIENT IC_F_LOCK, T_WARNING, 0, p12
    FIENT IC_F_LOCK, T_WARNING, 0, pfx
    FIENT IC_F_LOCK, T_WARNING, 0, p7b
    FIENT IC_F_LOCK, T_WARNING, 0, keystore
    FIENT IC_F_LOCK, T_WARNING, 0, jks
    FIENT IC_F_LOCK, T_WARNING, 0, kdbx
    FIENT IC_F_LOCK, T_WARNING, 0, sig
    # fonts
    FIENT IC_F_FONT, T_FG, 0, ttf
    FIENT IC_F_FONT, T_FG, 0, otf
    FIENT IC_F_FONT, T_FG, 0, woff
    FIENT IC_F_FONT, T_FG, 0, woff2
    FIENT IC_F_FONT, T_FG, 0, eot
    FIENT IC_F_FONT, T_FG, 0, ttc
    FIENT IC_F_FONT, T_FG, 0, fon
    # spreadsheets
    FIENT IC_F_SHEET, T_GIT_ADD, 0, csv
    FIENT IC_F_SHEET, T_GIT_ADD, 0, tsv
    FIENT IC_F_SHEET, T_GIT_ADD, 0, xls
    FIENT IC_F_SHEET, T_GIT_ADD, 0, xlsx
    FIENT IC_F_SHEET, T_GIT_ADD, 0, xlsm
    FIENT IC_F_SHEET, T_GIT_ADD, 0, ods
    FIENT IC_F_SHEET, T_GIT_ADD, 0, numbers
    .zero 4

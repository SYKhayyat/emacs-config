;;; -*- lexical-binding: t; -*-

(setq gc-cons-threshold most-positive-fixnum)
(setq gc-cons-percentage 0.6)
(setq package-enable-at-startup nil)

(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Silence native-comp warnings
(setq native-comp-async-report-warnings-errors 'silent)

(setq native-comp-async-report-warnings-errors 'silent)
(when (boundp 'native-comp-jit-compilation)
  (setq native-comp-jit-compilation t))
(when (boundp 'native-comp-deferred-compilation)
  (setq native-comp-deferred-compilation t))
(setq byte-compile-warnings '(not free-vars unresolved))

(setq warning-suppress-types '((comp) (bytecomp)))
(setq warning-minimum-level :error)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist my/file-name-handler-alist)))

(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(unless (bound-and-true-p package--initialized)
  (package-initialize))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)
(setq use-package-always-defer t)
(setq use-package-expand-minimally t)

(use-package diminish :demand t)

(use-package gcmh
  :demand t
  :diminish
  :config
  (setq gcmh-idle-delay 5)
  (setq gcmh-high-cons-threshold (* 64 1024 1024))
  (setq gcmh-low-cons-threshold (* 16 1024 1024))
  (gcmh-mode 1))

(setq read-process-output-max (* 1024 1024))
(setq process-adaptive-read-buffering nil)
(setq auto-window-vscroll nil)
(setq fast-but-imprecise-scrolling t)
(setq jit-lock-defer-time 0)

(setq-default bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)
(global-so-long-mode 1)

(setq inhibit-startup-message t)
(setq initial-scratch-message nil)
(setq ring-bell-function 'ignore)

(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(menu-bar-mode -1)
(set-fringe-mode 10)

(setq display-line-numbers-type 'relative)
(setq display-line-numbers-width 3)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(add-hook 'conf-mode-hook #'display-line-numbers-mode)

(dolist (mode '(org-mode-hook term-mode-hook shell-mode-hook
                eshell-mode-hook vterm-mode-hook pdf-view-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(global-hl-line-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0)
(column-number-mode 1)
(fset 'yes-or-no-p 'y-or-n-p)
(save-place-mode 1)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

(setq scroll-conservatively 101)
(setq scroll-margin 3)
(setq scroll-preserve-screen-position t)

(add-to-list 'default-frame-alist '(fullscreen . maximized))

(setq make-backup-files nil)
(setq auto-save-default nil)
(setq create-lockfiles nil)

(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(use-package recentf
  :ensure nil
  :demand t
  :config
  (setq recentf-max-saved-items 200)
  (setq recentf-max-menu-items 15)
  (setq recentf-auto-cleanup 'never)
  (add-to-list 'recentf-exclude "\\.?cache")
  (add-to-list 'recentf-exclude ".*\\.elc$")
  (add-to-list 'recentf-exclude "/nix/store/")
  (recentf-mode 1))

(use-package savehist
  :ensure nil
  :demand t
  :config
  (setq history-length 1000)
  (setq savehist-additional-variables
        '(search-ring regexp-search-ring kill-ring compile-command))
  (savehist-mode 1))

(with-eval-after-load 'dired
  (require 'dired-x))

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold t)
  (setq doom-themes-enable-italic t)
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(use-package nerd-icons
  :demand t)

(use-package doom-modeline
  :demand t
  :after nerd-icons
  :config
  (setq doom-modeline-height 28)
  (setq doom-modeline-buffer-encoding t)
  (setq doom-modeline-input-method t)
  (setq doom-modeline-minor-modes nil)
  (setq doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-mode 1))

(use-package all-the-icons
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :after all-the-icons
  :hook (dired-mode . all-the-icons-dired-mode)
  :config
  (setq all-the-icons-dired-monochrome nil))

(use-package pulsar
  :demand t
  :config
  (setq pulsar-pulse t)
  (setq pulsar-delay 0.04)
  (setq pulsar-iterations 8)
  (setq pulsar-face 'pulsar-magenta)
  (pulsar-global-mode 1)
  (add-hook 'next-error-hook #'pulsar-pulse-line))

(when (display-graphic-p)
  (set-face-attribute 'default nil
                      :family "JetBrains Mono"
                      :height 105
                      :weight 'regular)

  (set-fontset-font t 'hebrew (font-spec :family "David CLM"))
  (set-fontset-font t 'hebrew (font-spec :family "Noto Sans Hebrew") nil 'append)
  (set-fontset-font t 'unicode (font-spec :family "DejaVu Sans") nil 'append)

  (set-face-attribute 'mode-line nil :height 95)
  (set-face-attribute 'mode-line-inactive nil :height 95))

(setq-default bidi-display-reordering t)
(setq-default bidi-paragraph-direction nil)
(setq bidi-inhibit-bpa t)

(defvar-local my/bidi-direction 'right-to-left)

(defun my/set-rtl ()
  "Set buffer to RTL."
  (interactive)
  (setq-local bidi-paragraph-direction 'right-to-left)
  (setq-local my/bidi-direction 'right-to-left)
  (message "Direction: RTL"))

(defun my/set-ltr ()
  "Set buffer to LTR."
  (interactive)
  (setq-local bidi-paragraph-direction 'left-to-right)
  (setq-local my/bidi-direction 'left-to-right)
  (message "Direction: LTR"))

(defun my/toggle-direction ()
  "Toggle RTL/LTR."
  (interactive)
  (if (eq bidi-paragraph-direction 'right-to-left)
      (my/set-ltr)
    (my/set-rtl)))

(defun my/toggle-bidi-reordering ()
  "Toggle bidi reordering."
  (interactive)
  (setq bidi-display-reordering (not bidi-display-reordering))
  (message "Bidi: %s" (if bidi-display-reordering "ON" "OFF")))

(defun my/setup-rtl-mode ()
  "Setup RTL for prose."
  (setq-local bidi-paragraph-direction 'right-to-left))

(defun my/setup-ltr-mode ()
  "Setup LTR for code."
  (setq-local bidi-paragraph-direction 'left-to-right))

(dolist (hook '(org-mode-hook text-mode-hook markdown-mode-hook))
  (add-hook hook #'my/setup-rtl-mode))

(add-hook 'prog-mode-hook #'my/setup-ltr-mode)

(defun my/toggle-hebrew-input ()
  "Toggle Hebrew input."
  (interactive)
  (if current-input-method
      (deactivate-input-method)
    (set-input-method "hebrew")))

(defun my/large-file-hook ()
  "Optimize large files."
  (when (> (buffer-size) (* 5 1024 1024))
    (setq-local bidi-display-reordering nil)
    (font-lock-mode -1)
    (message "Large file mode")))

(add-hook 'find-file-hook #'my/large-file-hook)

(global-set-key (kbd "<f9>") #'my/toggle-hebrew-input)
(global-set-key (kbd "C-c d") #'my/toggle-direction)
(global-set-key (kbd "C-c r") #'my/set-rtl)
(global-set-key (kbd "C-c l") #'my/set-ltr)
(global-set-key (kbd "C-c B") #'my/toggle-bidi-reordering)

(use-package jinx
  :ensure nil
  :hook ((text-mode . jinx-mode)
         (org-mode . jinx-mode)
         (LaTeX-mode . jinx-mode))
  :bind ("M-$" . jinx-correct)
  :config
  (setq jinx-languages "en_US he_IL"))

(defun my/spell-hebrew ()
  (interactive)
  (setq-local jinx-languages "he_IL")
  (jinx-mode 1)
  (message "Spell: Hebrew"))

(defun my/spell-english ()
  (interactive)
  (setq-local jinx-languages "en_US")
  (jinx-mode 1)
  (message "Spell: English"))

(defun my/spell-both ()
  (interactive)
  (setq-local jinx-languages "en_US he_IL")
  (jinx-mode 1)
  (message "Spell: Both"))

(use-package vertico
  :demand t
  :config
  (setq vertico-count 15)
  (setq vertico-resize nil)
  (vertico-mode 1))

(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :demand t
  :config
  (marginalia-mode 1))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-s r" . consult-ripgrep)
         ("M-s f" . consult-fd)
         ("M-y" . consult-yank-pop)
         ("C-x r b" . consult-bookmark))
  :config
  (setq consult-narrow-key "<")
  (setq consult-preview-key '(:debounce 0.2 any)))

(use-package corfu
  :demand t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  :config
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :config
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package avy
  :bind (("M-j" . avy-goto-char-timer)
         ("M-g j" . avy-goto-line)
         ("M-g w" . avy-goto-word-1))
  :config
  (setq avy-timeout-seconds 0.3)
  (setq avy-background t))

(use-package ace-window
  :bind ("M-o" . ace-window)
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (setq aw-scope 'frame))

(use-package winner
  :ensure nil
  :demand t
  :config
  (winner-mode 1)
  :bind (("C-c <left>" . winner-undo)
         ("C-c <right>" . winner-redo)))

(use-package tab-bar
  :ensure nil
  :config
  (setq tab-bar-show 1)
  (setq tab-bar-close-button-show nil)
  (setq tab-bar-new-tab-choice "*scratch*")
  (setq tab-bar-tab-hints t)
  (setq tab-bar-format '(tab-bar-format-tabs tab-bar-separator))
  (tab-bar-mode 1)
  :bind (("C-<tab>" . tab-bar-switch-to-next-tab)
         ("C-S-<tab>" . tab-bar-switch-to-prev-tab)
         ("C-x t n" . tab-bar-new-tab)
         ("C-x t k" . tab-bar-close-tab)
         ("C-x t r" . tab-bar-rename-tab)))

(defun my/kill-current-buffer ()
  (interactive)
  (kill-buffer (current-buffer)))

(defun my/kill-other-buffers ()
  (interactive)
  (let ((kept 0) (killed 0))
    (dolist (buf (buffer-list))
      (let ((name (buffer-name buf)))
        (cond
         ((eq buf (current-buffer)) (cl-incf kept))
         ((string-prefix-p " " name) (cl-incf kept))
         ((string-prefix-p "*" name) (cl-incf kept))
         (t (kill-buffer buf) (cl-incf killed)))))
    (message "Killed %d, kept %d" killed kept)))

(defun my/revert-buffer-no-confirm ()
  (interactive)
  (revert-buffer t t)
  (message "Reverted"))

(global-set-key (kbd "C-x K") #'my/kill-current-buffer)
(global-set-key (kbd "C-c k") #'my/kill-other-buffers)
(global-set-key (kbd "C-c R") #'my/revert-buffer-no-confirm)

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer)
  :config
  (setq ibuffer-saved-filter-groups
        '(("default"
           ("Org" (mode . org-mode))
           ("LaTeX" (or (mode . latex-mode) (mode . LaTeX-mode)))
           ("Typst" (mode . typst-ts-mode))
           ("Seforim" (filename . "seforim"))
           ("Roam" (filename . "roam"))
           ("Dired" (mode . dired-mode))
           ("PDF" (mode . pdf-view-mode))
           ("Magit" (name . "^magit"))
           ("Help" (or (mode . help-mode) (mode . helpful-mode)))
           ("Emacs" (or (name . "^\\*scratch\\*$") (name . "^\\*Messages\\*$"))))))
  (add-hook 'ibuffer-mode-hook
            (lambda () (ibuffer-switch-to-saved-filter-groups "default"))))

(use-package undo-tree
  :diminish
  :demand t
  :config
  (setq undo-tree-auto-save-history t)
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo-tree-history/")))
  (setq undo-limit (* 80 1024 1024))
  (setq undo-strong-limit (* 120 1024 1024))
  (setq undo-outer-limit (* 300 1024 1024))
  (global-undo-tree-mode 1)
  :bind (("C-x u" . undo-tree-visualize)
         ("C-/" . undo-tree-undo)
         ("C-?" . undo-tree-redo)))

(use-package goto-last-change
  :bind ("C-c ;" . goto-last-change))

(use-package beginend
  :diminish beginend-global-mode
  :demand t
  :config
  (beginend-global-mode 1))

(use-package anzu
  :diminish
  :demand t
  :config
  (global-anzu-mode 1)
  :bind (([remap query-replace] . anzu-query-replace)
         ([remap query-replace-regexp] . anzu-query-replace-regexp)
         ("M-s %" . anzu-query-replace-at-cursor)))

(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-S-c C-S-c" . mc/edit-lines)))

(use-package expand-region
  :bind ("C-=" . er/expand-region))

(use-package move-text
  :bind (("M-<up>" . move-text-up)
         ("M-<down>" . move-text-down)))

(global-set-key (kbd "C-c C-d") #'duplicate-dwim)

(use-package crux
  :bind (("C-a" . crux-move-beginning-of-line)
         ("C-k" . crux-smart-kill-line)
         ("C-S-<return>" . crux-smart-open-line-above)
         ("S-<return>" . crux-smart-open-line)))

(use-package visual-regexp
  :bind (("C-c q" . vr/query-replace)
         ("C-c M" . vr/mc-mark)))

(use-package wgrep
  :config
  (setq wgrep-auto-save-buffer t))

(add-hook 'prog-mode-hook #'electric-pair-local-mode)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package visual-fill-column
  :config
  (setq-default visual-fill-column-width 80)
  (setq-default visual-fill-column-center-text t))

(defvar-local my/focused-writing nil)

(defun my/toggle-focused-writing ()
  (interactive)
  (if my/focused-writing
      (progn
        (visual-fill-column-mode -1)
        (visual-line-mode -1)
        (setq my/focused-writing nil)
        (message "Focused: OFF"))
    (visual-line-mode 1)
    (visual-fill-column-mode 1)
    (setq my/focused-writing t)
    (message "Focused: ON")))

(defun my/set-focused-width (width)
  (interactive "nWidth: ")
  (setq visual-fill-column-width width)
  (when visual-fill-column-mode
    (visual-fill-column-adjust)))

(global-set-key (kbd "C-c w") #'my/toggle-focused-writing)
(global-set-key (kbd "C-c W") #'my/set-focused-width)

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind ("C-x C-j" . dired-jump)
  :config
  (setq dired-listing-switches "-alh --group-directories-first")
  (setq dired-dwim-target t)
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq delete-by-moving-to-trash t))

(use-package dirvish
  :after dired
  :demand t
  :config
  (setq dirvish-reuse-session t)
  (setq dirvish-attributes '(subtree-state collapse file-size))
  (dirvish-override-dired-mode 1)
  :bind (:map dirvish-mode-map
              ("TAB" . dirvish-subtree-toggle)))

(use-package projectile
  :diminish
  :demand t
  :config
  (setq projectile-project-search-path '("~/projects/" "~/Documents/"))
  (setq projectile-sort-order 'recentf)
  (setq projectile-switch-project-action #'projectile-dired)
  (projectile-mode 1)
  :bind-keymap ("C-c p" . projectile-command-map))

(use-package consult-projectile
  :ensure nil  ; Nix-provided
  :after (consult projectile)
  :bind (:map projectile-command-map
              ("f" . consult-projectile-find-file)
              ("p" . consult-projectile-switch-project)))

(use-package yasnippet
  :diminish yas-minor-mode
  :hook ((prog-mode . yas-minor-mode)
         (text-mode . yas-minor-mode))
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package deadgrep
  :bind (("C-c / d" . deadgrep)
         ("C-c / D" . deadgrep-directory))
  :config
  (setq deadgrep-max-buffers 4))

(defun deadgrep-directory (search-term directory)
  (interactive
   (list (deadgrep--read-search-term)
         (read-directory-name "Directory: ")))
  (let ((default-directory directory))
    (deadgrep search-term)))

(use-package vterm
  :ensure nil
  :commands vterm
  :bind (("C-c t" . vterm)
         ("C-c T" . vterm-other-window))
  :config
  (setq vterm-max-scrollback 10000)
  (setq vterm-kill-buffer-on-exit t)
  (add-hook 'vterm-mode-hook
            (lambda () (setq-local bidi-paragraph-direction 'left-to-right))))

(defun vterm-other-window ()
  (interactive)
  (let ((buf (get-buffer "*vterm*")))
    (if buf
        (switch-to-buffer-other-window buf)
      (split-window-right)
      (other-window 1)
      (vterm))))

(use-package org
  :ensure nil
  :hook ((org-mode . visual-line-mode)
         (org-mode . my/setup-rtl-mode))
  :config
  (setq org-startup-indented t)
  (setq org-hide-leading-stars t)
  (setq org-ellipsis " ▾")
  (setq org-pretty-entities t)

  (setq org-src-fontify-natively t)
  (setq org-src-tab-acts-natively t)
  (setq org-confirm-babel-evaluate nil)
  (setq org-edit-src-content-indentation 0)

  (setq org-n-level-faces 20)
  (setq org-cycle-level-faces t)

  (setq org-list-indent-offset 2)
  (setq org-list-allow-alphabetical t)
  (setq org-list-demote-modify-bullet '(("+" . "-") ("-" . "+") ("*" . "-")))

  (setq org-return-follows-link t)
  (setq org-log-done 'time)
  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(p)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))

  (setq org-directory "~/Documents/org/")
  (setq org-agenda-files '("~/Documents/org/"))

  (setq org-tag-alist
        '(("research" . ?r) ("hebrew" . ?h) ("english" . ?e)
          ("urgent" . ?u) ("writing" . ?w) ("reading" . ?R))))

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (python . t)
     (latex . t))))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star '("◉" "○" "◈" "◇" "✦" "✧" "✶" "✷")))

(with-eval-after-load 'org
  (setq org-capture-templates
        '(("t" "Todo" entry (file+headline "~/Documents/org/inbox.org" "Tasks")
           "* TODO %?\n  %i\n  %a")
          ("n" "Note" entry (file+headline "~/Documents/org/inbox.org" "Notes")
           "* %?\n  %i\n  %a")
          ("h" "Hebrew Note" entry (file+headline "~/Documents/org/inbox.org" "Notes")
           "* %?\n  :PROPERTIES:\n  :LANG: hebrew\n  :END:\n  %i")
          ("j" "Journal" entry (file+datetree "~/Documents/org/journal.org")
           "* %?\n  Entered on %U\n  %i")
          ("r" "Research" entry (file+headline "~/Documents/org/research.org" "Inbox")
           "* %?\n  :PROPERTIES:\n  :SOURCE: \n  :END:\n  %i\n  %a"))))

(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

(use-package org-download
  :after org
  :hook (org-mode . org-download-enable)
  :config
  (setq org-download-method 'directory)
  (setq org-download-image-dir "./images")
  (setq org-download-heading-lvl nil))

(with-eval-after-load 'org
  (advice-add 'org-footnote-new :after
              (lambda (&rest _)
                (when (eq bidi-paragraph-direction 'right-to-left)
                  (insert ?\x200F)))))

(defun my/org-fix-all-footnotes-rtl ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0))
      (while (re-search-forward "^\\(\\[fn:[^]]+\\]\\)" nil t)
        (unless (looking-at (char-to-string ?\x200F))
          (insert ?\x200F)
          (cl-incf count)))
      (message "Fixed %d footnotes" count))))

(global-set-key (kbd "C-c h f") #'my/org-fix-all-footnotes-rtl)

(with-eval-after-load 'ox-latex
  (setq org-latex-compiler "lualatex")
  (setq org-latex-pdf-process
        '("latexmk -pdflatex='lualatex -shell-escape -interaction nonstopmode' -pdf -bibtex -f %f"))
  (setq org-latex-packages-alist
        '(("" "fontspec" t)
          ("bidi=basic" "babel" t)
          ("" "bigfoot" t)
          ("" "titlesec" t)
          ("" "enumitem" t)))
  (add-to-list 'org-latex-classes
               '("article-hebrew"
                 "\\documentclass[11pt]{article}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
\\babelprovide[main, import]{hebrew}
\\babelprovide[import]{english}
\\babelfont{rm}{David CLM}
\\babelfont{sf}{Nachlieli CLM}
\\babelfont{tt}{Miriam Mono CLM}
\\DeclareNewFootnote{default}
\\DeclareNewFootnote{B}
\\DeclareNewFootnote{C}
\\DeclareNewFootnote{D}
\\DeclareNewFootnote{E}
\\setcounter{secnumdepth}{10}
\\setcounter{tocdepth}{10}
\\setlistdepth{20}
\\renewlist{itemize}{itemize}{20}
\\renewlist{enumerate}{enumerate}{20}
[EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  (setq org-latex-default-class "article-hebrew"))

(defun my/tangle-config ()
  (when (string-equal (buffer-file-name)
                      (expand-file-name "config.org" user-emacs-directory))
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'after-save-hook #'my/tangle-config nil t)))

(use-package org-roam
  :ensure nil
  :demand t
  :custom
  (org-roam-directory "~/Documents/roam/")
  (org-roam-completion-everywhere t)
  (org-roam-dailies-directory "daily/")
  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n l" . org-roam-buffer-toggle)
         ("C-c n c" . org-roam-capture)
         ("C-c n g" . org-roam-graph)
         ("C-c n t" . org-roam-tag-add)
         ("C-c n d" . org-roam-dailies-goto-today)
         ("C-c n D" . org-roam-dailies-goto-date))
  :config
  (org-roam-db-autosync-mode 1)

  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: \n\n")
           :unnarrowed t)
          ("h" "hebrew" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: hebrew\n\n")
           :unnarrowed t)
          ("r" "research" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: research\n\n* Source\n\n* Notes\n\n")
           :unnarrowed t)))

  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d>\n#+filetags: daily\n\n")))))

(use-package org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t)
  (setq org-roam-ui-follow t)
  (setq org-roam-ui-update-on-save t)
  :bind ("C-c n u" . org-roam-ui-mode))

(defun my/org-roam-find-hebrew ()
  (interactive)
  (org-roam-node-find nil nil
                      (lambda (node) (member "hebrew" (org-roam-node-tags node)))))

(defun my/org-roam-find-research ()
  (interactive)
  (org-roam-node-find nil nil
                      (lambda (node) (member "research" (org-roam-node-tags node)))))

(global-set-key (kbd "C-c n h") #'my/org-roam-find-hebrew)
(global-set-key (kbd "C-c n R") #'my/org-roam-find-research)

(defvar my/doc-latex-hebrew-preamble
  "\\babelprovide[main, import]{hebrew}
\\babelprovide[import]{english}
\\babelfont{rm}{David CLM}
\\babelfont{sf}{Nachlieli CLM}
\\babelfont{tt}{Miriam Mono CLM}")

(defvar my/doc-latex-polyglossia-preamble
  "\\usepackage{polyglossia}
\\setmainlanguage{hebrew}
\\setotherlanguage{english}
\\setmainfont{David CLM}
\\setsansfont{Nachlieli CLM}
\\setmonofont{Miriam Mono CLM}")

(defvar my/doc-latex-footnotes-preamble
  "\\usepackage{bigfoot}
\\DeclareNewFootnote{default}
\\DeclareNewFootnote{B}
\\DeclareNewFootnote{C}
\\DeclareNewFootnote{D}
\\DeclareNewFootnote{E}
\\DeclareNewFootnote{F}
\\DeclareNewFootnote{G}
\\DeclareNewFootnote{H}
\\DeclareNewFootnote{I}
\\DeclareNewFootnote{J}")

(defvar my/doc-latex-unlimited-preamble
  "\\usepackage{titlesec}
\\setcounter{secnumdepth}{10}
\\setcounter{tocdepth}{10}
\\usepackage{enumitem}
\\setlistdepth{20}
\\renewlist{itemize}{itemize}{20}
\\renewlist{enumerate}{enumerate}{20}")

(use-package tex
  :ensure auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  :hook ((LaTeX-mode . my/setup-rtl-mode)
         (LaTeX-mode . TeX-source-correlate-mode)
         (LaTeX-mode . turn-on-reftex)
         (LaTeX-mode . LaTeX-math-mode)
         (LaTeX-mode . visual-line-mode)
         (LaTeX-mode . electric-pair-local-mode))
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)
  (setq-default TeX-engine 'luatex)
  (setq TeX-PDF-mode t)
  (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
  (setq TeX-source-correlate-start-server t)
  (setq reftex-plug-into-AUCTeX t)
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

(defun my/latex-word-count ()
  (interactive)
  (if (executable-find "detex")
      (let* ((file (buffer-file-name))
             (result (if file
                         (shell-command-to-string
                          (format "detex %s 2>/dev/null | wc -w"
                                  (shell-quote-argument file)))
                       (let ((temp-file (make-temp-file "latex-wc" nil ".tex")))
                         (write-region (point-min) (point-max) temp-file)
                         (prog1
                             (shell-command-to-string
                              (format "detex %s 2>/dev/null | wc -w"
                                      (shell-quote-argument temp-file)))
                           (delete-file temp-file))))))
        (message "Words: %s" (string-trim result)))
    (message "detex not found")))

(with-eval-after-load 'latex
  (define-key LaTeX-mode-map (kbd "C-c C-w") #'my/latex-word-count))

(defun my/insert-footnote-1 () (interactive) (insert "\\footnote{}") (backward-char 1))
(defun my/insert-footnote-2 () (interactive) (insert "\\footnoteB{}") (backward-char 1))
(defun my/insert-footnote-3 () (interactive) (insert "\\footnoteC{}") (backward-char 1))
(defun my/insert-footnote-4 () (interactive) (insert "\\footnoteD{}") (backward-char 1))
(defun my/insert-footnote-5 () (interactive) (insert "\\footnoteE{}") (backward-char 1))
(defun my/insert-footnote-6 () (interactive) (insert "\\footnoteF{}") (backward-char 1))
(defun my/insert-footnote-7 () (interactive) (insert "\\footnoteG{}") (backward-char 1))
(defun my/insert-footnote-8 () (interactive) (insert "\\footnoteH{}") (backward-char 1))
(defun my/insert-footnote-9 () (interactive) (insert "\\footnoteI{}") (backward-char 1))
(defun my/insert-footnote-10 () (interactive) (insert "\\footnoteJ{}") (backward-char 1))

(defun my/insert-footnotemark-2 () (interactive) (insert "\\footnotemarkB"))
(defun my/insert-footnotemark-3 () (interactive) (insert "\\footnotemarkC"))
(defun my/insert-footnotemark-4 () (interactive) (insert "\\footnotemarkD"))
(defun my/insert-footnotemark-5 () (interactive) (insert "\\footnotemarkE"))

(defun my/insert-footnotetext-2 () (interactive) (insert "\\footnotetextB{}") (backward-char 1))
(defun my/insert-footnotetext-3 () (interactive) (insert "\\footnotetextC{}") (backward-char 1))
(defun my/insert-footnotetext-4 () (interactive) (insert "\\footnotetextD{}") (backward-char 1))
(defun my/insert-footnotetext-5 () (interactive) (insert "\\footnotetextE{}") (backward-char 1))

(defun my/insert-nested-footnote-template ()
  (interactive)
  (insert "\\footnote{%\n  Text\\footnotemarkB.\n  \\footnotetextB{Nested.}%\n}")
  (search-backward "Text"))

(defun my/insert-latex-hebrew-preamble () (interactive) (insert my/doc-latex-hebrew-preamble))
(defun my/insert-latex-polyglossia-preamble () (interactive) (insert my/doc-latex-polyglossia-preamble))
(defun my/insert-latex-footnotes-preamble () (interactive) (insert my/doc-latex-footnotes-preamble))
(defun my/insert-latex-unlimited-preamble () (interactive) (insert my/doc-latex-unlimited-preamble))

(with-eval-after-load 'latex
  (define-key LaTeX-mode-map (kbd "C-c f 1") #'my/insert-footnote-1)
  (define-key LaTeX-mode-map (kbd "C-c f 2") #'my/insert-footnote-2)
  (define-key LaTeX-mode-map (kbd "C-c f 3") #'my/insert-footnote-3)
  (define-key LaTeX-mode-map (kbd "C-c f 4") #'my/insert-footnote-4)
  (define-key LaTeX-mode-map (kbd "C-c f 5") #'my/insert-footnote-5)
  (define-key LaTeX-mode-map (kbd "C-c f 6") #'my/insert-footnote-6)
  (define-key LaTeX-mode-map (kbd "C-c f 7") #'my/insert-footnote-7)
  (define-key LaTeX-mode-map (kbd "C-c f 8") #'my/insert-footnote-8)
  (define-key LaTeX-mode-map (kbd "C-c f 9") #'my/insert-footnote-9)
  (define-key LaTeX-mode-map (kbd "C-c f 0") #'my/insert-footnote-10)
  (define-key LaTeX-mode-map (kbd "C-c f n") #'my/insert-nested-footnote-template))

(with-eval-after-load 'tex
  (add-to-list 'TeX-command-list
               '("ConTeXt" "context --batchmode %s" TeX-run-command nil t)))

(defun my/insert-context-hebrew-preamble ()
  (interactive)
  (insert "\\mainlanguage[he]
\\setupalign[r2l]
\\definefontfamily[hebrew][rm][David CLM]
\\definefontfamily[hebrew][ss][Nachlieli CLM]
\\definefontfamily[hebrew][tt][Miriam Mono CLM]
\\setupbodyfont[hebrew]

\\starttext
\\startsection[title={כותרת}]
\\stopsection
\\stoptext")
  (search-backward "כותרת"))

(defun my/insert-context-local-footnote ()
  (interactive)
  (insert "\\startlocalfootnotes
\\localfootnote{}
\\placelocalfootnotes
\\stoplocalfootnotes")
  (search-backward "\\localfootnote{}")
  (forward-char 15))

(use-package treesit-auto
  :demand t
  :config
  (setq treesit-auto-install 'prompt)
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

(use-package typst-ts-mode
  :mode "\\.typ\\'"
  :hook ((typst-ts-mode . my/setup-rtl-mode)
         (typst-ts-mode . electric-pair-local-mode))
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(typst-ts-mode . ("tinymist")))))

(defun my/typst-compile ()
  (interactive)
  (compile (format "typst compile %s" (shell-quote-argument buffer-file-name))))

(defun my/typst-watch ()
  (interactive)
  (async-shell-command (format "typst watch %s" (shell-quote-argument buffer-file-name))))

(defun my/typst-view ()
  (interactive)
  (let ((pdf (concat (file-name-sans-extension buffer-file-name) ".pdf")))
    (if (file-exists-p pdf)
        (find-file-other-window pdf)
      (message "PDF not found"))))

(defun my/insert-typst-hebrew-preamble ()
  (interactive)
  (insert "#set text(lang: \"he\", font: \"David CLM\")
#set page(flipped: true)
#set heading(numbering: \"1.1.1\")

"))

(defun my/insert-typst-nested-footnote ()
  (interactive)
  (insert "#show footnote.entry: it => { block(it) }

"))

(with-eval-after-load 'typst-ts-mode
  (when (boundp 'typst-ts-mode-map)
    (define-key typst-ts-mode-map (kbd "C-c C-c") #'my/typst-compile)
    (define-key typst-ts-mode-map (kbd "C-c C-w") #'my/typst-watch)
    (define-key typst-ts-mode-map (kbd "C-c C-v") #'my/typst-view)
    (define-key typst-ts-mode-map (kbd "C-c t h") #'my/insert-typst-hebrew-preamble)
    (define-key typst-ts-mode-map (kbd "C-c t f") #'my/insert-typst-nested-footnote)))

(use-package pdf-tools
  :ensure nil
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq pdf-view-display-size 'fit-page)
  (setq pdf-view-resize-factor 1.1)
  (setq pdf-view-use-scaling t)
  (add-hook 'pdf-view-mode-hook #'auto-revert-mode)
  (add-hook 'pdf-view-mode-hook
            (lambda ()
              (pdf-view-midnight-minor-mode 1)
              (display-line-numbers-mode 0))))

(use-package citar
  :custom
  (citar-bibliography '("~/Documents/bibliography.bib"))
  (org-cite-global-bibliography '("~/Documents/bibliography.bib"))
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar)
  :bind (("C-c b o" . citar-open)
         ("C-c b i" . citar-insert-citation)
         ("C-c b n" . citar-open-notes)
         ("C-c b r" . citar-refresh)))

(use-package citar-org-roam
  :after (citar org-roam)
  :config
  (citar-org-roam-mode 1)
  (setq citar-org-roam-note-title-template "${author} - ${title}"))

(defgroup seforim nil "Seforim library." :group 'applications)

(defcustom seforim-directory "~/Documents/seforim/" "Seforim directory." :type 'directory :group 'seforim)
(defcustom seforim-extensions '("org" "pdf" "epub" "docx" "doc" "odt") "Extensions." :type '(repeat string) :group 'seforim)
(defcustom seforim-plocate-db "/var/cache/locatedb" "Plocate DB." :type 'file :group 'seforim)

(defvar seforim-masechtot
  '("Berakhot" "Shabbat" "Eruvin" "Pesachim" "Shekalim" "Yoma" "Sukkah" "Beitzah"
    "Rosh Hashanah" "Taanit" "Megillah" "Moed Katan" "Chagigah" "Yevamot" "Ketubot"
    "Nedarim" "Nazir" "Sotah" "Gittin" "Kiddushin" "Bava Kamma" "Bava Metzia"
    "Bava Batra" "Sanhedrin" "Makkot" "Shevuot" "Avodah Zarah" "Horayot" "Zevachim"
    "Menachot" "Chullin" "Bekhorot" "Arakhin" "Temurah" "Keritot" "Meilah" "Kinnim"
    "Tamid" "Middot" "Niddah"))

(defun seforim--executable-p (name) (executable-find name))

(defun seforim--plocate-available-p ()
  (and (seforim--executable-p "plocate") (file-readable-p seforim-plocate-db)))

(defun seforim--run-plocate (query)
  (let ((buf (generate-new-buffer " *plocate*")))
    (unwind-protect
        (progn
          (call-process "plocate" nil buf nil "--database" seforim-plocate-db "-i" query)
          (with-current-buffer buf (split-string (buffer-string) "\n" t)))
      (kill-buffer buf))))

(defun seforim--filter-files (files)
  (let ((root (expand-file-name seforim-directory)))
    (seq-filter
     (lambda (f)
       (and (string-prefix-p root f)
            (member (downcase (or (file-name-extension f) "")) seforim-extensions)
            (file-exists-p f)))
     files)))

(defun seforim--make-candidates (files)
  (let ((root (expand-file-name seforim-directory)))
    (mapcar (lambda (f) (cons (file-relative-name f root) f)) files)))

(defun seforim-find ()
  (interactive)
  (let* ((query (read-string "Find sefer: "))
         (files (if (seforim--plocate-available-p)
                    (seforim--run-plocate query)
                  (split-string
                   (shell-command-to-string
                    (format "fd -i -t f %s %s"
                            (shell-quote-argument query)
                            (shell-quote-argument (expand-file-name seforim-directory))))
                   "\n" t)))
         (filtered (seforim--filter-files files))
         (candidates (seforim--make-candidates filtered)))
    (if candidates
        (let* ((choice (completing-read "Select: " candidates nil t))
               (file (cdr (assoc choice candidates))))
          (when file (find-file file)))
      (user-error "No matches: %s" query))))

(defun seforim-find-recent ()
  (interactive)
  (let* ((root (expand-file-name seforim-directory))
         (files (seq-filter (lambda (f) (string-prefix-p root f)) recentf-list))
         (candidates (seforim--make-candidates files)))
    (if candidates
        (let* ((choice (completing-read "Recent: " candidates nil t))
               (file (cdr (assoc choice candidates))))
          (when file (find-file file)))
      (user-error "No recent seforim"))))

(defun seforim-search ()
  (interactive)
  (let* ((query (read-string "Search: "))
         (root (expand-file-name seforim-directory)))
    (if (seforim--executable-p "recoll")
        (seforim--search-recoll query root)
      (consult-ripgrep root query))))

(defun seforim--search-recoll (query dir)
  (let* ((cmd (format "recoll -t -q %s dir:%s 2>/dev/null"
                      (shell-quote-argument query)
                      (shell-quote-argument dir)))
         (output (shell-command-to-string cmd))
         (candidates (seforim--parse-recoll output dir)))
    (if candidates
        (let* ((choice (completing-read (format "「%s」: " query) candidates nil t))
               (file (cdr (assoc choice candidates))))
          (when file
            (find-file file)
            (goto-char (point-min))
            (search-forward query nil t)))
      (user-error "No results: %s" query))))

(defun seforim--parse-recoll (output dir)
  (let ((results nil) (seen (make-hash-table :test 'equal)))
    (dolist (line (split-string output "\n" t))
      (when (string-match "\\(/[^[:cntrl:]]+\\)" line)
        (let* ((file (match-string 1 line))
               (ext (downcase (or (file-name-extension file) ""))))
          (when (and (member ext seforim-extensions)
                     (file-exists-p file)
                     (string-prefix-p dir (expand-file-name file))
                     (not (gethash file seen)))
            (puthash file t seen)
            (push (cons (file-relative-name file dir) file) results)))))
    (nreverse results)))

(defun seforim--number-to-hebrew (num)
  (let* ((ones '("" "א" "ב" "ג" "ד" "ה" "ו" "ז" "ח" "ט"))
         (tens '("" "י" "כ" "ל" "מ" "נ" "ס" "ע" "פ" "צ"))
         (hundreds '("" "ק" "ר" "ש" "ת"))
         (h (/ num 100)) (t-val (/ (mod num 100) 10)) (o (mod num 10)))
    (cond
     ((= (mod num 100) 15) (concat (nth h hundreds) "טו"))
     ((= (mod num 100) 16) (concat (nth h hundreds) "טז"))
     (t (concat (nth h hundreds) (nth t-val tens) (nth o ones))))))

(defun seforim-goto-daf ()
  (interactive)
  (let* ((masechet (completing-read "Masechet: " seforim-masechtot nil t))
         (daf-num (read-number "Daf: " 2))
         (daf-side (completing-read "Side: " '("א" "ב") nil t))
         (daf-heading (format "דף %s ע\"%s" (seforim--number-to-hebrew daf-num) daf-side))
         (file (expand-file-name (concat "Bavli/" masechet ".org") seforim-directory)))
    (if (file-exists-p file)
        (progn
          (find-file file)
          (goto-char (point-min))
          (if (re-search-forward (format "^\\*+ %s" (regexp-quote daf-heading)) nil t)
              (progn (org-reveal) (recenter))
            (user-error "Daf %s not found" daf-heading)))
      (user-error "File not found: %s" file))))

(defun seforim-goto-daf-current ()
  (interactive)
  (unless (and buffer-file-name (string-match-p "Bavli" buffer-file-name))
    (user-error "Not in Bavli file"))
  (let* ((daf-num (read-number "Daf: " 2))
         (daf-side (completing-read "Side: " '("א" "ב") nil t))
         (daf-heading (format "דף %s ע\"%s" (seforim--number-to-hebrew daf-num) daf-side)))
    (goto-char (point-min))
    (if (re-search-forward (format "^\\*+ %s" (regexp-quote daf-heading)) nil t)
        (progn (org-reveal) (recenter))
      (user-error "Daf %s not found" daf-heading))))

(defun seforim-browse () (interactive) (dired seforim-directory))
(defun seforim-outline () (interactive) (consult-outline))
(defun seforim-reindex ()
  (interactive)
  (when (seforim--executable-p "recollindex")
    (start-process "recollindex" "*seforim-index*" "recollindex"))
  (message "Indexing started"))

(defun seforim-status ()
  (interactive)
  (with-current-buffer (get-buffer-create "*Seforim Status*")
    (erase-buffer)
    (insert "Seforim Library Status\n======================\n\n")
    (insert (format "Directory: %s\n" seforim-directory))
    (insert (format "Extensions: %s\n\n" (string-join seforim-extensions ", ")))
    (insert "Tools:\n")
    (dolist (tool '("plocate" "recoll" "rga" "fd"))
      (insert (format "  %s: %s\n" tool (if (seforim--executable-p tool) "✓" "✗"))))
    (insert (format "\nPlocate DB: %s\n"
                    (if (file-readable-p seforim-plocate-db) "✓" "✗")))
    (display-buffer (current-buffer))))

;; Keybindings - C-c S for hydra, direct keys here
(global-set-key (kbd "C-c s f") #'seforim-find)
(global-set-key (kbd "C-c s r") #'seforim-find-recent)
(global-set-key (kbd "C-c s s") #'seforim-search)
(global-set-key (kbd "C-c s b") #'seforim-browse)
(global-set-key (kbd "C-c s o") #'seforim-outline)
(global-set-key (kbd "C-c s d") #'seforim-goto-daf)
(global-set-key (kbd "C-c s D") #'seforim-goto-daf-current)
(global-set-key (kbd "C-c s I") #'seforim-reindex)
(global-set-key (kbd "C-c s ?") #'seforim-status)

(use-package eglot
  :ensure nil
  :hook ((python-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (java-mode . eglot-ensure)
         (nix-mode . eglot-ensure))
  :config
  (setq eglot-autoshutdown t)
  (setq eglot-send-changes-idle-time 0.5)
  (with-eval-after-load 'typst-ts-mode
    (add-to-list 'eglot-server-programs '(typst-ts-mode . ("tinymist")))
    (add-hook 'typst-ts-mode-hook #'eglot-ensure)))

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-mode)
  :config
  (setq python-indent-offset 4))

(use-package rust-mode
  :mode "\\.rs\\'"
  :config
  (setq rust-format-on-save t))

(use-package cargo
  :hook (rust-mode . cargo-minor-mode))

(use-package eglot-java
  :hook (java-mode . eglot-java-mode))

(use-package nix-mode
  :mode "\\.nix\\'"
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(nix-mode . ("nil")))))

(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :hook (markdown-mode . my/setup-rtl-mode)
  :config
  (setq markdown-command "pandoc"))

(use-package editorconfig
  :diminish
  :demand t
  :config
  (editorconfig-mode 1))

(use-package envrc
  :diminish
  :demand t
  :config
  (envrc-global-mode 1))

(use-package magit
  :ensure nil
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c v g" . magit-file-dispatch)))

(use-package git-gutter
  :diminish
  :hook (prog-mode . git-gutter-mode)
  :config
  (setq git-gutter:update-interval 0.5))

(use-package git-timemachine
  :bind ("C-c v t" . git-timemachine))

(use-package which-key
  :diminish
  :demand t
  :config
  (setq which-key-idle-delay 0.5)
  (setq which-key-prefix-prefix "◉ ")
  (which-key-mode 1))

(use-package helpful
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-command] . helpful-command)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-key] . helpful-key)))

(use-package hydra
  :demand t
  :config

  (defhydra hydra-direction (:color blue :hint nil)
    "
Direction: _r_: RTL  _l_: LTR  _t_: toggle  _B_: bidi
Spell:     _h_: Hebrew  _e_: English  _b_: both
Writing:   _w_: focused  _W_: width
"
    ("r" my/set-rtl)
    ("l" my/set-ltr)
    ("t" my/toggle-direction)
    ("B" my/toggle-bidi-reordering)
    ("h" my/spell-hebrew)
    ("e" my/spell-english)
    ("b" my/spell-both)
    ("w" my/toggle-focused-writing)
    ("W" my/set-focused-width)
    ("q" nil))

  (global-set-key (kbd "C-c D") #'hydra-direction/body)

  (defhydra hydra-roam (:color blue :hint nil)
    "
Roam: _f_: find  _i_: insert  _c_: capture  _l_: buffer
      _d_: daily  _D_: date  _g_: graph  _u_: UI
      _h_: hebrew  _R_: research  _t_: tag
"
    ("f" org-roam-node-find)
    ("i" org-roam-node-insert)
    ("c" org-roam-capture)
    ("l" org-roam-buffer-toggle)
    ("d" org-roam-dailies-goto-today)
    ("D" org-roam-dailies-goto-date)
    ("g" org-roam-graph)
    ("u" org-roam-ui-mode)
    ("h" my/org-roam-find-hebrew)
    ("R" my/org-roam-find-research)
    ("t" org-roam-tag-add)
    ("q" nil))

  (global-set-key (kbd "C-c N") #'hydra-roam/body)

  (defhydra hydra-seforim (:color blue :hint nil)
    "
Seforim: _f_: find  _r_: recent  _s_: search  _b_: browse
         _o_: outline  _d_: daf  _D_: daf (current)
         _I_: reindex  _?_: status
"
    ("f" seforim-find)
    ("r" seforim-find-recent)
    ("s" seforim-search)
    ("b" seforim-browse)
    ("o" seforim-outline)
    ("d" seforim-goto-daf)
    ("D" seforim-goto-daf-current)
    ("I" seforim-reindex)
    ("?" seforim-status)
    ("q" nil))

  (global-set-key (kbd "C-c S") #'hydra-seforim/body)

  (defhydra hydra-document (:color blue :hint nil)
    "
Documents: LaTeX: _p_: Babel  _g_: Polyglossia  _u_: Unlimited  _f_: Footnotes  _n_: Nested
           ConTeXt: _c_: Hebrew  _C_: Local footnote
           Typst: _t_: Hebrew  _T_: Nested
"
    ("p" my/insert-latex-hebrew-preamble)
    ("g" my/insert-latex-polyglossia-preamble)
    ("u" my/insert-latex-unlimited-preamble)
    ("f" my/insert-latex-footnotes-preamble)
    ("n" my/insert-nested-footnote-template)
    ("c" my/insert-context-hebrew-preamble)
    ("C" my/insert-context-local-footnote)
    ("t" my/insert-typst-hebrew-preamble)
    ("T" my/insert-typst-nested-footnote)
    ("q" nil))

  (global-set-key (kbd "C-c P") #'hydra-document/body)

  (defhydra hydra-latex-footnotes (:color blue :hint nil)
    "
Footnotes: _1_-_0_: levels  _n_: nested  _m_: marks  _t_: texts
"
    ("1" my/insert-footnote-1)
    ("2" my/insert-footnote-2)
    ("3" my/insert-footnote-3)
    ("4" my/insert-footnote-4)
    ("5" my/insert-footnote-5)
    ("6" my/insert-footnote-6)
    ("7" my/insert-footnote-7)
    ("8" my/insert-footnote-8)
    ("9" my/insert-footnote-9)
    ("0" my/insert-footnote-10)
    ("n" my/insert-nested-footnote-template)
    ("m" hydra-latex-footnote-marks/body)
    ("t" hydra-latex-footnote-texts/body)
    ("q" nil))

  (defhydra hydra-latex-footnote-marks (:color blue :hint nil)
    "Marks: _2_-_5_  _b_: back"
    ("2" my/insert-footnotemark-2)
    ("3" my/insert-footnotemark-3)
    ("4" my/insert-footnotemark-4)
    ("5" my/insert-footnotemark-5)
    ("b" hydra-latex-footnotes/body)
    ("q" nil))

  (defhydra hydra-latex-footnote-texts (:color blue :hint nil)
    "Texts: _2_-_5_  _b_: back"
    ("2" my/insert-footnotetext-2)
    ("3" my/insert-footnotetext-3)
    ("4" my/insert-footnotetext-4)
    ("5" my/insert-footnotetext-5)
    ("b" hydra-latex-footnotes/body)
    ("q" nil))

  (with-eval-after-load 'latex
    (define-key LaTeX-mode-map (kbd "C-c F") #'hydra-latex-footnotes/body)))

(use-package server
  :ensure nil
  :demand t
  :config
  (unless (server-running-p)
    (server-start)))

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs ready in %.2f seconds with %d GCs."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

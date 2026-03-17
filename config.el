;; Increase garbage collection threshold for faster startup
(setq gc-cons-threshold (* 50 1000 1000))

;; Disable package.el in favor of use-package (built-in Emacs 29+)
(setq package-enable-at-startup t)

;; Silence harmless async native-compilation warnings
(setq native-comp-async-report-warnings-errors nil)

;; Add Nix profile binaries to exec-path
(when (eq system-type 'gnu/linux)
  (setq exec-path
        (append '("/run/current-system/sw/bin"
                  "/etc/profiles/per-user/shaul/bin"
                  "~/.nix-profile/bin")
                exec-path))
  (setenv "PATH" (concat "/run/current-system/sw/bin:"
                         "/etc/profiles/per-user/shaul/bin:"
                         (getenv "PATH"))))

;; Core performance settings for snappy typing with Hebrew
(setq bidi-inhibit-bpa t)
(setq bidi-display-reordering t)
(setq bidi-paragraph-direction 'right-to-left)

;; Faster rendering
(setq auto-window-vscroll nil)
(setq fast-but-imprecise-scrolling t)
(setq jit-lock-defer-time 0)
(setq read-process-output-max (* 1024 1024))

;; Reasonable undo limits
(setq undo-limit 20000000)
(setq undo-strong-limit 40000000)
(setq undo-outer-limit 60000000)

;; Lighter than relative line numbers
(setq display-line-numbers-type 'visual)

;; Large file performance guard (5MB threshold)
(defun my/large-file-performance ()
  "Disable expensive features in large buffers."
  (when (> (buffer-size) (* 5 1024 1024))
    (when (fboundp 'jinx-mode) (jinx-mode -1))
    (setq-local bidi-display-reordering nil)
    (message "Large-file performance mode activated")))

(add-hook 'find-file-hook #'my/large-file-performance)

;; Handle long lines better
(setq-default so-long-threshold 400)
(global-so-long-mode 1)

(use-package exec-path-from-shell
  :ensure nil
  :config
  (when (memq window-system '(mac ns x pgtk))
    (exec-path-from-shell-initialize)))

(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("melpa-stable" . "https://stable.melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)

;; Refresh package contents if needed
(unless package-archive-contents
  (package-refresh-contents))

;; use-package is built into Emacs 29+
(require 'use-package)
(setq use-package-always-ensure t)

;; Diminish for cleaner modeline
(use-package diminish)

;; Cleaner UI
(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(menu-bar-mode -1)
(set-fringe-mode 10)

;; Line numbers
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)

;; Disable line numbers in certain modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook
                pdf-view-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Highlight current line
(global-hl-line-mode 1)

;; Show matching parentheses
(show-paren-mode 1)

;; Use y/n instead of yes/no
(fset 'yes-or-no-p 'y-or-n-p)

;; Remember cursor position
(save-place-mode 1)

;; Refresh buffers when files change on disk
(global-auto-revert-mode 1)

;; Column number in modeline
(column-number-mode 1)

;; Smooth scrolling
(setq scroll-conservatively 101)
(setq scroll-margin 3)

;; Start maximized but respect Plasma panels
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Ensure new frames also respect panels
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (set-frame-parameter frame 'fullscreen 'maximized)))

;; Disable backup files
(setq make-backup-files nil)
(setq auto-save-default nil)
(setq create-lockfiles nil)

;; UTF-8 everywhere
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1)
  :config
  (setq history-length 1000)
  (setq savehist-additional-variables
        '(search-ring regexp-search-ring kill-ring)))

(use-package recentf
  :ensure nil
  :init
  (recentf-mode 1)
  :config
  (setq recentf-max-saved-items 100)
  (setq recentf-max-menu-items 15)
  (add-to-list 'recentf-exclude "\\.?cache")
  (add-to-list 'recentf-exclude ".*/\\.emacs\\.d/.*")
  (add-to-list 'recentf-exclude ".*\\.pdf$"))

(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 32)
  (setq doom-modeline-buffer-encoding t)
  (setq doom-modeline-input-method t)
  (setq doom-modeline-minor-modes nil))

(use-package all-the-icons
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

;; === Fast & Correct Hebrew/RTL Defaults ===
(setq bidi-inhibit-bpa t)
(setq bidi-display-reordering t)
(setq bidi-paragraph-direction 'right-to-left)

;; === Direction Indicator (updates only on change) ===
(defvar my/direction-indicator " [RTL עב]"
  "Current direction indicator for mode line.")

;; === Direction Functions ===
(defun my/set-rtl ()
  "Set buffer direction to RTL (Hebrew)."
  (interactive)
  (setq bidi-paragraph-direction 'right-to-left)
  (setq my/direction-indicator " [RTL עב]")
  (force-mode-line-update)
  (message "Direction: RTL (Hebrew)"))

(defun my/set-ltr ()
  "Set buffer direction to LTR (English)."
  (interactive)
  (setq bidi-paragraph-direction 'left-to-right)
  (setq my/direction-indicator " [LTR EN]")
  (force-mode-line-update)
  (message "Direction: LTR (English)"))

(defun my/toggle-direction ()
  "Toggle between RTL and LTR."
  (interactive)
  (if (eq bidi-paragraph-direction 'right-to-left)
      (my/set-ltr)
    (my/set-rtl)))

(defun my/toggle-bidi-reordering ()
  "Toggle bidirectional text reordering for performance."
  (interactive)
  (setq bidi-display-reordering (not bidi-display-reordering))
  (force-window-update)
  (message "Bidi reordering: %s"
           (if bidi-display-reordering "enabled" "disabled")))

;; === Apply Defaults by Mode ===
(defun my/set-rtl-mode ()
  "Hook function to set RTL direction."
  (setq bidi-paragraph-direction 'right-to-left))

(defun my/set-ltr-mode ()
  "Hook function to set LTR direction."
  (setq bidi-paragraph-direction 'left-to-right))

;; Prose modes: RTL
(add-hook 'org-mode-hook #'my/set-rtl-mode)
(add-hook 'LaTeX-mode-hook #'my/set-rtl-mode)
(add-hook 'context-mode-hook #'my/set-rtl-mode)
(add-hook 'typst-ts-mode-hook #'my/set-rtl-mode)
(add-hook 'text-mode-hook #'my/set-rtl-mode)
(add-hook 'markdown-mode-hook #'my/set-rtl-mode)

;; Code modes: LTR
(add-hook 'prog-mode-hook #'my/set-ltr-mode)

;; === Keybindings ===
(global-set-key (kbd "C-c d") 'my/toggle-direction)
(global-set-key (kbd "C-c r") 'my/set-rtl)
(global-set-key (kbd "C-c l") 'my/set-ltr)
(global-set-key (kbd "C-c B") 'my/toggle-bidi-reordering)

(defun my/toggle-hebrew-input ()
  "Smart toggle between no input method and hebrew-full."
  (interactive)
  (if current-input-method
      (deactivate-input-method)
    (set-input-method "hebrew-full")))

(global-set-key (kbd "<f9>") 'my/toggle-hebrew-input)

(use-package jinx
  :ensure nil
  :hook ((text-mode . jinx-mode)
         (org-mode . jinx-mode)
         (LaTeX-mode . jinx-mode))
  :bind ("M-$" . jinx-correct)
  :config
  (setq jinx-languages "en he"))

;; Spell check functions for hydra
(defun my/spell-hebrew ()
  "Set spell checking to Hebrew only."
  (interactive)
  (setq jinx-languages "he")
  (jinx-mode 1)
  (message "Spell check: Hebrew"))

(defun my/spell-english ()
  "Set spell checking to English only."
  (interactive)
  (setq jinx-languages "en")
  (jinx-mode 1)
  (message "Spell check: English"))

(defun my/spell-both ()
  "Set spell checking to both Hebrew and English."
  (interactive)
  (setq jinx-languages "en he")
  (jinx-mode 1)
  (message "Spell check: English + Hebrew"))

(use-package vertico
  :init
  (vertico-mode)
  :config
  (setq vertico-count 20))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init
  (marginalia-mode))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-s r" . consult-ripgrep)
         ("M-s f" . consult-find)
         ("C-x r b" . consult-bookmark)
         ("M-y" . consult-yank-pop))
  :config
  (setq consult-find-args "fd --color=never --full-path ARG OPTS"))

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :init
  (global-corfu-mode))

(use-package corfu-popupinfo
  :ensure nil
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :config
  (setq corfu-popupinfo-delay '(0.5 . 0.2)))

(use-package embark
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :demand t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package ace-window
  :bind ("M-o" . ace-window)
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package winner
  :ensure nil
  :init (winner-mode 1)
  :bind (("C-c <left>" . winner-undo)
         ("C-c <right>" . winner-redo)))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer)
  :config
  (setq ibuffer-saved-filter-groups
        '(("default"
           ("Org" (mode . org-mode))
           ("LaTeX" (or (mode . latex-mode)
                        (mode . LaTeX-mode)))
           ("ConTeXt" (mode . context-mode))
           ("Typst" (mode . typst-ts-mode))
           ("Roam" (directory . "~/Documents/roam/"))
           ("Dired" (mode . dired-mode))
           ("PDF" (mode . pdf-view-mode))
           ("Magit" (name . "^magit"))
           ("Help" (or (mode . help-mode)
                       (mode . helpful-mode)))
           ("Emacs" (or (name . "^\\*scratch\\*$")
                        (name . "^\\*Messages\\*$"))))))
  (add-hook 'ibuffer-mode-hook
            (lambda ()
              (ibuffer-switch-to-saved-filter-groups "default"))))

(use-package projectile
  :diminish projectile-mode
  :config
  (projectile-mode)
  (setq projectile-project-search-path '("~/projects/" "~/Documents/"))
  (setq projectile-sort-order 'recentf)
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  (setq projectile-switch-project-action #'projectile-dired))

(use-package consult-projectile
  :after (consult projectile)
  :bind (:map projectile-command-map
              ("f" . consult-projectile-find-file)
              ("p" . consult-projectile-switch-project)
              ("s" . consult-projectile-switch-project)))

(use-package undo-tree
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode)

  ;; Save undo history between sessions
  (setq undo-tree-auto-save-history t)
  (setq undo-tree-history-directory-alist
        '(("." . "~/.emacs.d/undo-tree-history/")))

  ;; Create undo history directory
  (make-directory "~/.emacs.d/undo-tree-history/" t)

  ;; Increase undo limits
  (setq undo-limit 80000000)
  (setq undo-strong-limit 120000000)
  (setq undo-outer-limit 300000000)

  :bind (("C-x u" . undo-tree-visualize)
         ("C-/" . undo-tree-undo)
         ("C-?" . undo-tree-redo)))

(use-package visual-fill-column
  :config
  (setq-default visual-fill-column-width 80)
  (setq-default visual-fill-column-center-text t))

(defvar my/focused-writing-mode nil
  "Track whether focused writing mode is active.")

(defun my/toggle-focused-writing ()
  "Toggle focused writing mode (80-column centered text)."
  (interactive)
  (if my/focused-writing-mode
      (progn
        (visual-fill-column-mode -1)
        (visual-line-mode -1)
        (setq my/focused-writing-mode nil)
        (message "Focused writing: OFF"))
    (progn
      (visual-line-mode 1)
      (visual-fill-column-mode 1)
      (setq my/focused-writing-mode t)
      (message "Focused writing: ON (80 columns, centered)"))))

(defun my/set-focused-writing-width (width)
  "Set focused writing column width."
  (interactive "nColumn width: ")
  (setq visual-fill-column-width width)
  (when visual-fill-column-mode
    (visual-fill-column-adjust))
  (message "Focused writing width: %d" width))

(global-set-key (kbd "C-c w") 'my/toggle-focused-writing)
(global-set-key (kbd "C-c W") 'my/set-focused-writing-width)

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

;; Electric pairs only in code and markup modes (not prose)
(electric-pair-mode -1)

;; Enable in programming modes
(add-hook 'prog-mode-hook 'electric-pair-local-mode)

;; Enable in document markup modes
(add-hook 'LaTeX-mode-hook 'electric-pair-local-mode)
(add-hook 'context-mode-hook 'electric-pair-local-mode)
(add-hook 'typst-ts-mode-hook 'electric-pair-local-mode)
(add-hook 'typst-mode-hook 'electric-pair-local-mode)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(add-hook 'prog-mode-hook 'whitespace-mode)
(setq whitespace-style '(face tabs tab-mark trailing))

(use-package yasnippet
  :diminish yas-minor-mode
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

(defun my/create-hebrew-snippets ()
    "Create custom Hebrew LaTeX snippets."
    (let ((latex-snippet-dir (expand-file-name "snippets/latex-mode" user-emacs-directory))
          (org-snippet-dir (expand-file-name "snippets/org-mode" user-emacs-directory)))
      ;; Create directories
      (make-directory latex-snippet-dir t)
      (make-directory org-snippet-dir t)

      ;; Hebrew environment for LaTeX
      (with-temp-file (expand-file-name "hebrew-env" latex-snippet-dir)
        (insert "# -*- mode: snippet -*-
# name: Hebrew environment
# key: heb
# --
\\begin{hebrew}
$0
\\end{hebrew}"))

      ;; English environment for LaTeX
      (with-temp-file (expand-file-name "english-env" latex-snippet-dir)
        (insert "# -*- mode: snippet -*-
# name: English environment
# key: eng
# --
\\begin{english}
$0
\\end{english}"))

      ;; Hebrew org template
      (with-temp-file (expand-file-name "hebrew-doc" org-snippet-dir)
        (insert "# -*- mode: snippet -*-
# name: Hebrew document
# key: hebdoc
# --
#+TITLE: ${1:כותרת}
#+AUTHOR: ${2:Author}
#+DATE: `(format-time-string \"%Y-%m-%d\")`
#+LATEX_CLASS: article-unlimited
#+LATEX_HEADER: \\babelprovide[main, import]{hebrew}
#+OPTIONS: toc:nil

$0"))))

  (my/create-hebrew-snippets)

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :config
  (setq dired-listing-switches "-alh --group-directories-first")
  (setq dired-dwim-target t)
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq delete-by-moving-to-trash t)
  (put 'dired-find-alternate-file 'disabled nil))

(use-package dirvish
  :init
  (dirvish-override-dired-mode)
  :config
  (setq dirvish-reuse-session t)
  (setq dirvish-show-hidden-files nil)
  (setq dirvish-preview-dispatchers nil)

  ;; Default attributes
  (setq dirvish-attributes '(vc-state subtree-state collapse file-time file-size))

  ;; Ultra-fast mode toggle
  (defvar my/dirvish-ultra-mode nil)

  (defun my/dirvish-toggle-ultra ()
    "Toggle between pretty and ultra-fast mode."
    (interactive)
    (if my/dirvish-ultra-mode
        (progn
          (setq dirvish-attributes '(vc-state subtree-state collapse file-time file-size))
          (setq my/dirvish-ultra-mode nil)
          (message "Dirvish: Pretty mode"))
      (setq dirvish-attributes '(subtree-state))
      (setq my/dirvish-ultra-mode t)
      (message "Dirvish: ULTRA mode"))
    (revert-buffer))

  :bind (:map dirvish-mode-map
              ("C-c d m" . my/dirvish-toggle-ultra)))

;; Fix RTL direction in Org footnotes
(defun my/org-footnote-rtl-fix ()
  "Add RTL mark after footnote definition marker for proper Hebrew display."
  (when (and (eq bidi-paragraph-direction 'right-to-left)
             (org-in-footnote-p))
    (save-excursion
      (let ((fn-start (org-footnote-at-definition-p)))
        (when fn-start
          (goto-char (nth 1 fn-start))
          (unless (looking-at (char-to-string ?\x200F))
            (insert ?\x200F)))))))

;; Run fix when entering footnotes
(advice-add 'org-footnote-new :after
            (lambda (&rest _)
              (when (eq bidi-paragraph-direction 'right-to-left)
                (insert ?\x200F))))

;; Command to fix existing footnotes in buffer
(defun my/org-fix-all-footnotes-rtl ()
  "Add RTL marks to all footnote definitions in buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0))
      (while (re-search-forward "^\\(\\[fn:[^]]+\\]\\)" nil t)
        (unless (looking-at (char-to-string ?\x200F))
          (insert ?\x200F)
          (setq count (1+ count))))
      (message "Fixed %d footnotes" count))))

(global-set-key (kbd "C-c h f") 'my/org-fix-all-footnotes-rtl)

(use-package org
  :ensure nil
  :hook (org-mode . visual-line-mode)
  :config
  ;; Basic settings
  (setq org-startup-indented t)
  (setq org-hide-leading-stars t)
  (setq org-ellipsis " ▾")
  (setq org-src-fontify-natively t)
  (setq org-src-tab-acts-natively t)
  (setq org-confirm-babel-evaluate nil)
  (setq org-edit-src-content-indentation 0)

  ;; Unlimited heading levels
  (setq org-n-level-faces 20)
  (setq org-cycle-level-faces t)

  ;; Unlimited list levels
  (setq org-list-indent-offset 2)
  (setq org-list-allow-alphabetical t)

  ;; Return follows links
  (setq org-return-follows-link t)

  ;; Log time when done
  (setq org-log-done 'time)

  ;; Org directory
  (setq org-directory "~/Documents/org/"))

(with-eval-after-load 'org
  (setq org-list-demote-modify-bullet
        '(("+" . "-")
          ("-" . "+")
          ("*" . "-")))

  (setq org-plain-list-ordered-item-terminator t)
  (setq org-list-indent-offset 2))

(with-eval-after-load 'org
  (setq org-agenda-files '("~/Documents/org/"))
  (setq org-agenda-start-on-weekday 0)

  (setq org-todo-keywords
        '((sequence "TODO(t)" "IN-PROGRESS(p)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))

  (setq org-tag-alist
        '(("research" . ?r)
          ("hebrew" . ?h)
          ("english" . ?e)
          ("urgent" . ?u)
          ("writing" . ?w)
          ("reading" . ?R))))

(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (python . t)
     (latex . t))))

(use-package ob-rust
  :after org
  :config
  (with-eval-after-load 'org
    (add-to-list 'org-babel-load-languages '(rust . t))
    (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star '("◉" "○" "◈" "◇" "✦" "✧" "✶" "✷" "❋" "❊"
                          "✺" "✹" "✸" "✷" "✶" "✵" "✴" "✳" "✲" "✱")))

(with-eval-after-load 'org
  (setq org-preview-latex-default-process 'dvisvgm)
  (setq org-format-latex-options
        (plist-put org-format-latex-options :scale 1.5))
  (setq org-latex-create-formula-image-program 'dvisvgm))

(with-eval-after-load 'org
  ;; Ensure capture files exist
  (dolist (file '("~/Documents/org/inbox.org"
                  "~/Documents/org/journal.org"
                  "~/Documents/org/research.org"
                  "~/Documents/org/reading.org"))
    (unless (file-exists-p file)
      (with-temp-buffer
        (insert "#+TITLE: " (file-name-base file) "\n\n")
        (when (string-match-p "inbox" file)
          (insert "* Tasks\n\n* Notes\n"))
        (when (string-match-p "research" file)
          (insert "* Inbox\n"))
        (when (string-match-p "reading" file)
          (insert "* To Read\n* Currently Reading\n* Finished\n"))
        (write-file file))))

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
           "* %?\n  :PROPERTIES:\n  :SOURCE: \n  :END:\n  %i\n  %a")

          ("b" "Book" entry (file+headline "~/Documents/org/reading.org" "To Read")
           "* %^{Title}\n  :PROPERTIES:\n  :AUTHOR: %^{Author}\n  :ADDED: %U\n  :END:\n  %?"))))

;; Shared LaTeX preamble components
  (defvar my/latex-hebrew-setup
    "% Hebrew support
\\usepackage{fontspec}
\\usepackage[bidi=basic]{babel}
\\babelprovide[main, import]{hebrew}
\\babelprovide[import]{english}
\\babelfont{rm}{David CLM}
\\babelfont{sf}{Nachlieli CLM}
\\babelfont{tt}{Miriam Mono CLM}

% Nested footnotes
\\usepackage{bigfoot}
\\DeclareNewFootnote{default}
\\DeclareNewFootnote{B}
\\DeclareNewFootnote{C}
\\DeclareNewFootnote{D}
\\DeclareNewFootnote{E}
\\DeclareNewFootnote{F}
\\DeclareNewFootnote{G}
\\DeclareNewFootnote{H}
\\DeclareNewFootnote{I}
\\DeclareNewFootnote{J}"
    "Hebrew and nested footnotes setup.")

  (defvar my/latex-unlimited-structure
    "% Unlimited sectioning
\\usepackage{titlesec}
\\setcounter{secnumdepth}{10}
\\setcounter{tocdepth}{10}

\\titleclass{\\subsubparagraph}{straight}[\\subparagraph]
\\newcounter{subsubparagraph}[subparagraph]
\\renewcommand{\\thesubsubparagraph}{\\thesubparagraph.\\arabic{subsubparagraph}}
\\titleformat{\\subsubparagraph}[runin]{\\normalfont\\normalsize\\bfseries}{\\thesubsubparagraph}{1em}{}
\\titlespacing*{\\subsubparagraph}{0pt}{3.25ex plus 1ex minus .2ex}{1em}

\\titleclass{\\subsubsubparagraph}{straight}[\\subsubparagraph]
\\newcounter{subsubsubparagraph}[subsubparagraph]
\\renewcommand{\\thesubsubsubparagraph}{\\thesubsubparagraph.\\arabic{subsubsubparagraph}}
\\titleformat{\\subsubsubparagraph}[runin]{\\normalfont\\normalsize\\bfseries}{\\thesubsubsubparagraph}{1em}{}
\\titlespacing*{\\subsubsubparagraph}{0pt}{3.25ex plus 1ex minus .2ex}{1em}

\\titleclass{\\subsubsubsubparagraph}{straight}[\\subsubsubparagraph]
\\newcounter{subsubsubsubparagraph}[subsubsubparagraph]
\\renewcommand{\\thesubsubsubsubparagraph}{\\thesubsubsubparagraph.\\arabic{subsubsubsubparagraph}}
\\titleformat{\\subsubsubsubparagraph}[runin]{\\normalfont\\normalsize\\bfseries}{\\thesubsubsubsubparagraph}{1em}{}
\\titlespacing*{\\subsubsubsubparagraph}{0pt}{3.25ex plus 1ex minus .2ex}{1em}

\\titleclass{\\subsubsubsubsubparagraph}{straight}[\\subsubsubsubparagraph]
\\newcounter{subsubsubsubsubparagraph}[subsubsubsubparagraph]
\\renewcommand{\\thesubsubsubsubsubparagraph}{\\thesubsubsubsubparagraph.\\arabic{subsubsubsubsubparagraph}}
\\titleformat{\\subsubsubsubsubparagraph}[runin]{\\normalfont\\normalsize\\bfseries}{\\thesubsubsubsubsubparagraph}{1em}{}
\\titlespacing*{\\subsubsubsubsubparagraph}{0pt}{3.25ex plus 1ex minus .2ex}{1em}

% Unlimited list nesting
\\usepackage{enumitem}
\\setlistdepth{20}
\\renewlist{itemize}{itemize}{20}
\\renewlist{enumerate}{enumerate}{20}
\\setlist[itemize,1]{label=\\textbullet}
\\setlist[itemize,2]{label=\\textendash}
\\setlist[itemize,3]{label=\\textasteriskcentered}
\\setlist[itemize,4]{label=\\textperiodcentered}
\\setlist[itemize,5]{label=\\textbullet}
\\setlist[itemize,6]{label=\\textendash}
\\setlist[itemize,7]{label=\\textasteriskcentered}
\\setlist[itemize,8]{label=\\textperiodcentered}
\\setlist[itemize,9]{label=\\textbullet}
\\setlist[itemize,10]{label=\\textendash}
\\setlist[enumerate,1]{label=\\arabic*.}
\\setlist[enumerate,2]{label=\\alph*.}
\\setlist[enumerate,3]{label=\\roman*.}
\\setlist[enumerate,4]{label=\\Alph*.}
\\setlist[enumerate,5]{label=\\arabic*.}
\\setlist[enumerate,6]{label=\\alph*.}
\\setlist[enumerate,7]{label=\\roman*.}
\\setlist[enumerate,8]{label=\\Alph*.}
\\setlist[enumerate,9]{label=\\arabic*.}
\\setlist[enumerate,10]{label=\\alph*.}"
    "Unlimited sectioning and list nesting setup.")

  (defun my/latex-class-preamble (docclass)
    "Generate LaTeX class preamble for DOCCLASS."
    (format "\\documentclass[11pt]{%s}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
[EXTRA]
%s

%s
" docclass my/latex-hebrew-setup my/latex-unlimited-structure))

  (with-eval-after-load 'ox-latex
    ;; Use LuaLaTeX
    (setq org-latex-compiler "lualatex")

    ;; PDF process
    (setq org-latex-pdf-process
          '("latexmk -pdflatex='lualatex -shell-escape -interaction nonstopmode' -pdf -bibtex -f %f"))

    ;; Packages for all exports
    (setq org-latex-packages-alist
          '(("" "fontspec" t)
            ("bidi=basic" "babel" t)
            ("" "bigfoot" t)
            ("" "titlesec" t)
            ("" "enumitem" t)))

    ;; Article class with unlimited depth
    (add-to-list 'org-latex-classes
                 `("article-unlimited"
                   ,(my/latex-class-preamble "article")
                   ("\\section{%s}" . "\\section*{%s}")
                   ("\\subsection{%s}" . "\\subsection*{%s}")
                   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                   ("\\paragraph{%s}" . "\\paragraph*{%s}")
                   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")
                   ("\\subsubparagraph{%s}" . "\\subsubparagraph*{%s}")
                   ("\\subsubsubparagraph{%s}" . "\\subsubsubparagraph*{%s}")
                   ("\\subsubsubsubparagraph{%s}" . "\\subsubsubsubparagraph*{%s}")
                   ("\\subsubsubsubsubparagraph{%s}" . "\\subsubsubsubsubparagraph*{%s}")))

    ;; Report class with unlimited depth
    (add-to-list 'org-latex-classes
                 `("report-unlimited"
                   ,(my/latex-class-preamble "report")
                   ("\\chapter{%s}" . "\\chapter*{%s}")
                   ("\\section{%s}" . "\\section*{%s}")
                   ("\\subsection{%s}" . "\\subsection*{%s}")
                   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                   ("\\paragraph{%s}" . "\\paragraph*{%s}")
                   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")
                   ("\\subsubparagraph{%s}" . "\\subsubparagraph*{%s}")
                   ("\\subsubsubparagraph{%s}" . "\\subsubsubparagraph*{%s}")
                   ("\\subsubsubsubparagraph{%s}" . "\\subsubsubsubparagraph*{%s}")))

    ;; Book class with unlimited depth
    (add-to-list 'org-latex-classes
                 `("book-unlimited"
                   ,(my/latex-class-preamble "book")
                   ("\\part{%s}" . "\\part*{%s}")
                   ("\\chapter{%s}" . "\\chapter*{%s}")
                   ("\\section{%s}" . "\\section*{%s}")
                   ("\\subsection{%s}" . "\\subsection*{%s}")
                   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                   ("\\paragraph{%s}" . "\\paragraph*{%s}")
                   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")
                   ("\\subsubparagraph{%s}" . "\\subsubparagraph*{%s}")
                   ("\\subsubsubparagraph{%s}" . "\\subsubsubparagraph*{%s}")))

    ;; Make article-unlimited the default
    (setq org-latex-default-class "article-unlimited"))

(use-package org-roam
  :custom
  (org-roam-directory "~/Documents/roam/")
  (org-roam-completion-everywhere t)
  (org-roam-dailies-directory "daily/")
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n g" . org-roam-graph)
         ("C-c n t" . org-roam-tag-add)
         ("C-c n r" . org-roam-ref-add)
         ("C-c n a" . org-roam-alias-add)
         ("C-c n d" . org-roam-dailies-goto-today)
         ("C-c n D" . org-roam-dailies-goto-date)
         :map org-mode-map
         ("C-M-i" . completion-at-point))
  :config
  (make-directory org-roam-directory t)
  (make-directory (expand-file-name "daily" org-roam-directory) t)
  (org-roam-db-autosync-mode))

(with-eval-after-load 'org-roam
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: \n\n")
           :unnarrowed t)

          ("h" "hebrew" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: hebrew\n#+LATEX_CLASS: article-unlimited\n#+LATEX_HEADER: \\babelprovide[main, import]{hebrew}\n\n")
           :unnarrowed t)

          ("r" "research" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: research\n#+LATEX_CLASS: article-unlimited\n\n* מקור / Source\n\n* הערות / Notes\n\n* שאלות / Questions\n\n")
           :unnarrowed t)

          ("c" "concept" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: concept hebrew\n\n* הגדרה / Definition\n\n* דוגמאות / Examples\n\n* קשרים / Related\n\n")
           :unnarrowed t)

          ("l" "literature" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: literature\n#+LATEX_CLASS: article-unlimited\n\n* ביבליוגרפיה / Bibliographic Info\n- Author: \n- Year: \n- Title: \n\n* תקציר / Summary\n\n* ציטוטים / Key Quotes\n\n* הערות / Notes\n\n")
           :unnarrowed t)

          ("p" "project" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: project\n\n* מטרות / Goals\n\n* משימות / Tasks\n** TODO \n\n* הערות / Notes\n\n* משאבים / Resources\n\n")
           :unnarrowed t)))

  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d>\n#+filetags: daily\n\n"))
          ("h" "hebrew" entry "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d>\n#+filetags: daily hebrew\n\n* משימות / Tasks\n\n* הערות / Notes\n\n")))))

(use-package org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t)
  (setq org-roam-ui-follow t)
  (setq org-roam-ui-update-on-save t)
  (setq org-roam-ui-open-on-start nil))

(use-package org-noter
  :after (org pdf-tools)
  :config
  (setq org-noter-notes-search-path '("~/Documents/roam/"))
  (setq org-noter-auto-save-last-location t)
  (setq org-noter-default-notes-file-names '("notes.org"))
  (setq org-noter-always-create-frame nil)
  :bind (:map pdf-view-mode-map
              ("C-c n" . org-noter)))

(use-package tex
  :ensure auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)

  ;; Use LuaLaTeX
  (setq-default TeX-engine 'luatex)

  ;; Enable PDF mode
  (setq TeX-PDF-mode t)

  ;; Use pdf-tools for viewing
  (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
  (setq TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view)))

  ;; Source correlate mode
  (add-hook 'LaTeX-mode-hook 'TeX-source-correlate-mode)
  (setq TeX-source-correlate-start-server t)

  ;; Enable RefTeX
  (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
  (setq reftex-plug-into-AUCTeX t)

  ;; Auto-completion
  (add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)

  ;; Visual line mode
  (add-hook 'LaTeX-mode-hook 'visual-line-mode)

  ;; Add LuaLaTeX command
  (add-to-list 'TeX-command-list
               '("LuaLaTeX" "lualatex -shell-escape -interaction=nonstopmode %s"
                 TeX-run-TeX nil (latex-mode) :help "Run LuaLaTeX")))

(with-eval-after-load 'latex
  (setq preview-auto-cache-preamble t)
  (setq preview-scale-function 1.5))

(defun my/insert-hebrew-preamble ()
    "Insert complete Hebrew LaTeX preamble (Babel)."
    (interactive)
    (insert my/latex-hebrew-setup "\n\n" my/latex-unlimited-structure))

  (defun my/insert-polyglossia-preamble ()
    "Insert complete Hebrew LaTeX preamble (Polyglossia)."
    (interactive)
    (insert "% Hebrew support (Polyglossia)
\\usepackage{fontspec}
\\usepackage{polyglossia}
\\setmainlanguage{hebrew}
\\setotherlanguage{english}
\\setmainfont{David CLM}
\\setsansfont{Nachlieli CLM}
\\setmonofont{Miriam Mono CLM}

" my/latex-unlimited-structure))

  (defun my/insert-unlimited-structure ()
    "Insert only unlimited sectioning and list preamble."
    (interactive)
    (insert my/latex-unlimited-structure))

;; Simple footnotes (non-nested)
(defun my/insert-footnote-level-1 ()
  "Insert level 1 footnote."
  (interactive)
  (insert "\\footnote{}")
  (backward-char 1))

(defun my/insert-footnote-level-2 ()
  "Insert level 2 footnote."
  (interactive)
  (insert "\\footnoteB{}")
  (backward-char 1))

(defun my/insert-footnote-level-3 ()
  "Insert level 3 footnote."
  (interactive)
  (insert "\\footnoteC{}")
  (backward-char 1))

(defun my/insert-footnote-level-4 ()
  "Insert level 4 footnote."
  (interactive)
  (insert "\\footnoteD{}")
  (backward-char 1))

(defun my/insert-footnote-level-5 ()
  "Insert level 5 footnote."
  (interactive)
  (insert "\\footnoteE{}")
  (backward-char 1))

(defun my/insert-footnote-level-6 ()
  "Insert level 6 footnote."
  (interactive)
  (insert "\\footnoteF{}")
  (backward-char 1))

(defun my/insert-footnote-level-7 ()
  "Insert level 7 footnote."
  (interactive)
  (insert "\\footnoteG{}")
  (backward-char 1))

(defun my/insert-footnote-level-8 ()
  "Insert level 8 footnote."
  (interactive)
  (insert "\\footnoteH{}")
  (backward-char 1))

(defun my/insert-footnote-level-9 ()
  "Insert level 9 footnote."
  (interactive)
  (insert "\\footnoteI{}")
  (backward-char 1))

(defun my/insert-footnote-level-10 ()
  "Insert level 10 footnote."
  (interactive)
  (insert "\\footnoteJ{}")
  (backward-char 1))

;; Nested footnote marks
(defun my/insert-footnotemark-level-2 ()
  "Insert level 2 footnote mark (for nesting)."
  (interactive)
  (insert "\\footnotemarkB"))

(defun my/insert-footnotemark-level-3 ()
  "Insert level 3 footnote mark."
  (interactive)
  (insert "\\footnotemarkC"))

(defun my/insert-footnotemark-level-4 ()
  "Insert level 4 footnote mark."
  (interactive)
  (insert "\\footnotemarkD"))

(defun my/insert-footnotemark-level-5 ()
  "Insert level 5 footnote mark."
  (interactive)
  (insert "\\footnotemarkE"))

;; Nested footnote texts
(defun my/insert-footnotetext-level-2 ()
  "Insert level 2 footnote text (for nesting)."
  (interactive)
  (insert "\\footnotetextB{}")
  (backward-char 1))

(defun my/insert-footnotetext-level-3 ()
  "Insert level 3 footnote text."
  (interactive)
  (insert "\\footnotetextC{}")
  (backward-char 1))

(defun my/insert-footnotetext-level-4 ()
  "Insert level 4 footnote text."
  (interactive)
  (insert "\\footnotetextD{}")
  (backward-char 1))

(defun my/insert-footnotetext-level-5 ()
  "Insert level 5 footnote text."
  (interactive)
  (insert "\\footnotetextE{}")
  (backward-char 1))

(defun my/insert-nested-footnote-template ()
  "Insert a template for nested footnotes."
  (interactive)
  (insert "\\footnote{%\n  First level text\\footnotemarkB.\n  \\footnotetextB{Second level text.}%\n}")
  (search-backward "First level text"))

;; Keybindings
(with-eval-after-load 'latex
  (define-key LaTeX-mode-map (kbd "C-c f 1") 'my/insert-footnote-level-1)
  (define-key LaTeX-mode-map (kbd "C-c f 2") 'my/insert-footnote-level-2)
  (define-key LaTeX-mode-map (kbd "C-c f 3") 'my/insert-footnote-level-3)
  (define-key LaTeX-mode-map (kbd "C-c f 4") 'my/insert-footnote-level-4)
  (define-key LaTeX-mode-map (kbd "C-c f 5") 'my/insert-footnote-level-5)
  (define-key LaTeX-mode-map (kbd "C-c f 6") 'my/insert-footnote-level-6)
  (define-key LaTeX-mode-map (kbd "C-c f 7") 'my/insert-footnote-level-7)
  (define-key LaTeX-mode-map (kbd "C-c f 8") 'my/insert-footnote-level-8)
  (define-key LaTeX-mode-map (kbd "C-c f 9") 'my/insert-footnote-level-9)
  (define-key LaTeX-mode-map (kbd "C-c f 0") 'my/insert-footnote-level-10)
  (define-key LaTeX-mode-map (kbd "C-c f m 2") 'my/insert-footnotemark-level-2)
  (define-key LaTeX-mode-map (kbd "C-c f m 3") 'my/insert-footnotemark-level-3)
  (define-key LaTeX-mode-map (kbd "C-c f m 4") 'my/insert-footnotemark-level-4)
  (define-key LaTeX-mode-map (kbd "C-c f m 5") 'my/insert-footnotemark-level-5)
  (define-key LaTeX-mode-map (kbd "C-c f t 2") 'my/insert-footnotetext-level-2)
  (define-key LaTeX-mode-map (kbd "C-c f t 3") 'my/insert-footnotetext-level-3)
  (define-key LaTeX-mode-map (kbd "C-c f t 4") 'my/insert-footnotetext-level-4)
  (define-key LaTeX-mode-map (kbd "C-c f t 5") 'my/insert-footnotetext-level-5)
  (define-key LaTeX-mode-map (kbd "C-c f n") 'my/insert-nested-footnote-template))

(with-eval-after-load 'tex
  ;; Add ConTeXt command
  (add-to-list 'TeX-command-list
               '("ConTeXt" "context --batchmode %s"
                 TeX-run-command nil (context-mode) :help "Run ConTeXt"))

  ;; Helper function to insert ConTeXt Hebrew preamble
  (defun my/insert-context-hebrew-preamble ()
    "Insert ConTeXt Hebrew preamble."
    (interactive)
    (insert "\\mainlanguage[he]\n")
    (insert "\\setupalign[r2l]\n")
    (insert "\\definefontfamily[hebrew][rm][David CLM]\n")
    (insert "\\definefontfamily[hebrew][ss][Nachlieli CLM]\n")
    (insert "\\definefontfamily[hebrew][tt][Miriam Mono CLM]\n")
    (insert "\\setupbodyfont[hebrew]\n\n")
    (insert "\\starttext\n\n")
    (insert "\\stoptext")
    (forward-line -1))

  ;; ConTeXt local footnotes helper
  (defun my/insert-context-local-footnote ()
    "Insert ConTeXt local footnote structure."
    (interactive)
    (insert "\\startlocalfootnotes\n")
    (insert "\\localfootnote{}\n")
    (insert "\\placelocalfootnotes\n")
    (insert "\\stoplocalfootnotes")
    (search-backward "\\localfootnote{}")
    (forward-char 15)))

;; Install typst-ts-mode via package-vc if not available
(unless (package-installed-p 'typst-ts-mode)
  (when (fboundp 'package-vc-install)
    (package-vc-install
     '(typst-ts-mode
       :url "https://git.sr.ht/~meow_king/typst-ts-mode"
       :branch "master"))))

(use-package typst-ts-mode
  :ensure nil
  :mode "\\.typ\\'"
  :config
  ;; Use tinymist LSP (provided by NixOS)
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(typst-ts-mode . ("tinymist"))))

  (add-hook 'typst-ts-mode-hook #'eglot-ensure)
  (add-hook 'typst-ts-mode-hook #'my/set-rtl-mode)
  (add-hook 'typst-ts-mode-hook #'electric-pair-local-mode))

;; Fallback mode if tree-sitter not available
(unless (fboundp 'typst-ts-mode)
  (define-derived-mode typst-mode text-mode "Typst"
    "Major mode for editing Typst files."
    (setq-local comment-start "// ")
    (setq-local comment-end ""))
  (add-to-list 'auto-mode-alist '("\\.typ\\'" . typst-mode))
  (add-hook 'typst-mode-hook #'my/set-rtl-mode)
  (add-hook 'typst-mode-hook #'electric-pair-local-mode))

;; Compilation functions
(defun my/typst-compile ()
  "Compile current Typst file."
  (interactive)
  (compile (format "typst compile %s" (shell-quote-argument buffer-file-name))))

(defun my/typst-watch ()
  "Start Typst watch mode for live preview."
  (interactive)
  (async-shell-command
   (format "typst watch %s" (shell-quote-argument buffer-file-name))))

(defun my/typst-view ()
  "View compiled PDF."
  (interactive)
  (let ((pdf (concat (file-name-sans-extension buffer-file-name) ".pdf")))
    (if (file-exists-p pdf)
        (find-file-other-window pdf)
      (message "PDF not found. Compile first."))))

;; Hebrew setup helper
(defun my/insert-typst-hebrew-preamble ()
  "Insert Typst Hebrew preamble."
  (interactive)
  (insert "#set text(lang: \"he\", font: \"David CLM\")\n")
  (insert "#set page(flipped: true)\n")
  (insert "#set heading(numbering: \"1.1.1\")\n\n"))

;; Visual nested footnote helper
(defun my/typst-insert-nested-footnote-helper ()
  "Insert Typst visual nested footnote helper function."
  (interactive)
  (insert "#let subnote(body, notes) = footnote[\n")
  (insert "  #body\n")
  (insert "  #if notes != none [\n")
  (insert "    #v(0.5em)\n")
  (insert "    #line(length: 50%, stroke: 0.5pt)\n")
  (insert "    #v(0.3em)\n")
  (insert "    #set text(size: 0.85em)\n")
  (insert "    #notes\n")
  (insert "  ]\n")
  (insert "]\n\n"))

;; Keybindings
(defun my/typst-keybindings ()
  "Set Typst keybindings."
  (local-set-key (kbd "C-c C-c") 'my/typst-compile)
  (local-set-key (kbd "C-c C-w") 'my/typst-watch)
  (local-set-key (kbd "C-c C-v") 'my/typst-view)
  (local-set-key (kbd "C-c t h") 'my/insert-typst-hebrew-preamble)
  (local-set-key (kbd "C-c t f") 'my/typst-insert-nested-footnote-helper))

(add-hook 'typst-ts-mode-hook 'my/typst-keybindings)
(when (fboundp 'typst-mode)
  (add-hook 'typst-mode-hook 'my/typst-keybindings))

(use-package pdf-tools
  :ensure nil
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq pdf-view-display-size 'fit-page)
  (setq pdf-view-continuous t)
  (add-hook 'pdf-view-mode-hook (lambda () (pdf-view-midnight-minor-mode 1))))

(use-package citar
  :custom
  (citar-bibliography '("~/Documents/bibliography.bib"))
  (org-cite-global-bibliography '("~/Documents/bibliography.bib"))
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar)
  :bind
  (("C-c b o" . citar-open)
   ("C-c b i" . citar-insert-citation)
   ("C-c b n" . citar-open-notes)
   ("C-c b r" . citar-refresh)))

(use-package citar-org-roam
  :after (citar org-roam)
  :config
  (citar-org-roam-mode)
  (setq citar-org-roam-note-title-template "${author} - ${title}")
  (setq citar-org-roam-capture-template-key "l"))

(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c g" . magit-file-dispatch)))

(use-package git-gutter
  :hook (prog-mode . git-gutter-mode)
  :config
  (setq git-gutter:update-interval 0.5))

(use-package git-timemachine
  :bind ("C-c G" . git-timemachine))

(use-package eglot
  :ensure nil
  :hook ((python-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (java-mode . eglot-ensure))
  :config
  (setq eglot-autoshutdown t))

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-mode)
  :config
  (setq python-indent-offset 4))

(use-package rust-mode
  :config
  (setq rust-format-on-save t))

(use-package cargo
  :hook (rust-mode . cargo-minor-mode))

(use-package eglot-java
  :hook (java-mode . eglot-java-mode))

(use-package sh-mode
  :ensure nil
  :mode (("\\.sh\\'" . sh-mode)
         ("\\.bash\\'" . sh-mode)
         ("\\.zsh\\'" . sh-mode)))

(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :config
  (setq markdown-command "pandoc"))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.5)
  (setq which-key-prefix-prefix "◉ "))

(use-package helpful
  :bind
  ([remap describe-function] . helpful-callable)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-key] . helpful-key)
  ("C-h F" . helpful-function)
  ("C-h C" . helpful-command))

(use-package hydra
    :config
    ;; Direction and language hydra
    (defhydra hydra-direction (:color blue :hint nil)
      "
Direction Controls

_r_: RTL (Hebrew)    _l_: LTR (English)    _t_: Toggle direction
_h_: Hebrew spell    _e_: English spell    _b_: Both languages
_B_: Toggle bidi     _w_: Focus writing    _W_: Set width
_q_: quit
"
      ("r" my/set-rtl)
      ("l" my/set-ltr)
      ("t" my/toggle-direction)
      ("h" my/spell-hebrew)
      ("e" my/spell-english)
      ("b" my/spell-both)
      ("B" my/toggle-bidi-reordering)
      ("w" my/toggle-focused-writing)
      ("W" my/set-focused-writing-width)
      ("q" nil))

    (global-set-key (kbd "C-c D") 'hydra-direction/body)

    ;; Org-roam hydra
    (defhydra hydra-org-roam (:color blue :hint nil)
      "
Org-Roam

_f_: Find node       _i_: Insert node      _c_: Capture
_l_: Toggle buffer   _g_: Graph            _t_: Add tag
_d_: Daily today     _D_: Daily date       _u_: Roam UI
_q_: quit
"
      ("f" org-roam-node-find)
      ("i" org-roam-node-insert)
      ("c" org-roam-capture)
      ("l" org-roam-buffer-toggle)
      ("g" org-roam-graph)
      ("t" org-roam-tag-add)
      ("d" org-roam-dailies-goto-today)
      ("D" org-roam-dailies-goto-date)
      ("u" (when (fboundp 'org-roam-ui-open) (org-roam-ui-open)))
      ("q" nil))

    (global-set-key (kbd "C-c R") 'hydra-org-roam/body)

    ;; Document system hydra
    (defhydra hydra-document (:color blue :hint nil)
      "
Document Systems

LaTeX:   _p_: Babel preamble  _g_: Polyglossia  _u_: Unlimited struct
         _n_: Nested footnote template
ConTeXt: _c_: Hebrew preamble _f_: Local footnote
Typst:   _h_: Hebrew preamble _s_: Nested footnote helper
_q_: quit
"
      ("p" my/insert-hebrew-preamble)
      ("g" my/insert-polyglossia-preamble)
      ("u" my/insert-unlimited-structure)
      ("n" my/insert-nested-footnote-template)
      ("c" my/insert-context-hebrew-preamble)
      ("f" my/insert-context-local-footnote)
      ("h" my/insert-typst-hebrew-preamble)
      ("s" my/typst-insert-nested-footnote-helper)
      ("q" nil))

    (global-set-key (kbd "C-c P") 'hydra-document/body)

    ;; LaTeX footnotes hydra
    (defhydra hydra-latex-footnotes (:color blue :hint nil)
      "
LaTeX Footnotes (Simple)

_1_: \\footnote    _2_: \\footnoteB   _3_: \\footnoteC   _4_: \\footnoteD   _5_: \\footnoteE
_6_: \\footnoteF   _7_: \\footnoteG   _8_: \\footnoteH   _9_: \\footnoteI   _0_: \\footnoteJ

_n_: Nested template   _m_: → Marks menu   _t_: → Texts menu
_q_: quit
"
      ("1" my/insert-footnote-level-1)
      ("2" my/insert-footnote-level-2)
      ("3" my/insert-footnote-level-3)
      ("4" my/insert-footnote-level-4)
      ("5" my/insert-footnote-level-5)
      ("6" my/insert-footnote-level-6)
      ("7" my/insert-footnote-level-7)
      ("8" my/insert-footnote-level-8)
      ("9" my/insert-footnote-level-9)
      ("0" my/insert-footnote-level-10)
      ("n" my/insert-nested-footnote-template)
      ("m" hydra-latex-footnote-marks/body)
      ("t" hydra-latex-footnote-texts/body)
      ("q" nil))

    ;; Sub-hydra for footnote marks
    (defhydra hydra-latex-footnote-marks (:color blue :hint nil)
      "
Footnote Marks (for nesting)

_2_: \\footnotemarkB   _3_: \\footnotemarkC   _4_: \\footnotemarkD   _5_: \\footnotemarkE
_b_: ← Back   _q_: quit
"
      ("2" my/insert-footnotemark-level-2)
      ("3" my/insert-footnotemark-level-3)
      ("4" my/insert-footnotemark-level-4)
      ("5" my/insert-footnotemark-level-5)
      ("b" hydra-latex-footnotes/body)
      ("q" nil))

    ;; Sub-hydra for footnote texts
    (defhydra hydra-latex-footnote-texts (:color blue :hint nil)
      "
Footnote Texts (for nesting)

_2_: \\footnotetextB   _3_: \\footnotetextC   _4_: \\footnotetextD   _5_: \\footnotetextE
_b_: ← Back   _q_: quit
"
      ("2" my/insert-footnotetext-level-2)
      ("3" my/insert-footnotetext-level-3)
      ("4" my/insert-footnotetext-level-4)
      ("5" my/insert-footnotetext-level-5)
      ("b" hydra-latex-footnotes/body)
      ("q" nil))

    (with-eval-after-load 'latex
      (define-key LaTeX-mode-map (kbd "C-c F") 'hydra-latex-footnotes/body)))

(defun my/open-init-file ()
  "Open the Emacs init file."
  (interactive)
  (find-file (expand-file-name "config.org" user-emacs-directory)))

(defun my/reload-init-file ()
  "Reload the Emacs init file."
  (interactive)
  (load-file (expand-file-name "init.el" user-emacs-directory))
  (message "Init file reloaded."))

(global-set-key (kbd "C-c e i") 'my/open-init-file)
(global-set-key (kbd "C-c e r") 'my/reload-init-file)

(defun my/kill-other-buffers ()
  "Kill all buffers except the current one."
  (interactive)
  (mapc 'kill-buffer
        (delq (current-buffer)
              (cl-remove-if
               (lambda (buf)
                 (string-match-p "^\\*" (buffer-name buf)))
               (buffer-list))))
  (message "Other file buffers killed."))

(defun my/split-and-follow-horizontally ()
  "Split window horizontally and follow."
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1))

(defun my/split-and-follow-vertically ()
  "Split window vertically and follow."
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1))

(global-set-key (kbd "C-x 2") 'my/split-and-follow-horizontally)
(global-set-key (kbd "C-x 3") 'my/split-and-follow-vertically)

(defun my/insert-hebrew-quotes ()
  "Insert Hebrew quotation marks."
  (interactive)
  (insert "״״")
  (backward-char 1))

(defun my/insert-hebrew-parentheses ()
  "Insert parentheses in correct order for Hebrew."
  (interactive)
  (insert ")(")
  (backward-char 1))

(defun my/count-hebrew-words ()
  "Count Hebrew words in region or buffer."
  (interactive)
  (let* ((start (if (use-region-p) (region-beginning) (point-min)))
         (end (if (use-region-p) (region-end) (point-max)))
         (text (buffer-substring-no-properties start end))
         (hebrew-word-count 0))
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (re-search-forward "[א-ת]+" nil t)
        (setq hebrew-word-count (1+ hebrew-word-count))))
    (message "Hebrew words: %d" hebrew-word-count)))

(global-set-key (kbd "C-c h q") 'my/insert-hebrew-quotes)
(global-set-key (kbd "C-c h p") 'my/insert-hebrew-parentheses)
(global-set-key (kbd "C-c h c") 'my/count-hebrew-words)

(defun my/org-roam-find-hebrew ()
  "Find org-roam nodes tagged with hebrew."
  (interactive)
  (org-roam-node-find nil nil
                      (lambda (node)
                        (member "hebrew" (org-roam-node-tags node)))))

(defun my/org-roam-find-research ()
  "Find org-roam nodes tagged with research."
  (interactive)
  (org-roam-node-find nil nil
                      (lambda (node)
                        (member "research" (org-roam-node-tags node)))))

(defun my/org-roam-open-random ()
  "Open a random org-roam node."
  (interactive)
  (org-roam-node-random))

(global-set-key (kbd "C-c n h") 'my/org-roam-find-hebrew)
(global-set-key (kbd "C-c n R") 'my/org-roam-find-research)
(global-set-key (kbd "C-c n x") 'my/org-roam-open-random)

(when (display-graphic-p)
  ;; Default monospace font
  (set-face-attribute 'default nil
                      :family "JetBrains Mono"
                      :height 100
                      :weight 'regular)

  ;; Hebrew font (Culmus + Noto fallback)
  (set-fontset-font t 'hebrew
                    (font-spec :family "David CLM"))
  (set-fontset-font t 'hebrew
                    (font-spec :family "Noto Sans Hebrew") nil 'append)

  ;; Fallbacks
  (set-fontset-font t 'unicode
                    (font-spec :family "DejaVu Sans") nil 'append)

  ;; Modeline smaller
  (set-face-attribute 'mode-line nil :height 90)
  (set-face-attribute 'mode-line-inactive nil :height 90))

;; Ensure necessary directories exist
(dolist (dir '("~/Documents/org/"
               "~/Documents/roam/"
               "~/Documents/roam/daily/"
               "~/Documents/seforim/"
               "~/projects/"))
  (unless (file-exists-p dir)
    (make-directory dir t)))

;; Create bibliography file if it doesn't exist
(let ((bib-file "~/Documents/bibliography.bib"))
  (unless (file-exists-p bib-file)
    (with-temp-file bib-file
      (insert "% Bibliography file\n% Add your BibTeX entries here\n\n"))))

;; Hide minor modes from modeline using diminish
(with-eval-after-load 'diminish
  (diminish 'visual-line-mode)
  (diminish 'auto-revert-mode)
  (diminish 'eldoc-mode)
  (diminish 'abbrev-mode))

;; Automatically tangle this config file when saved
(defun my/org-babel-tangle-config ()
  "Tangle config file if it's config.org in .emacs.d."
  (when (and (buffer-file-name)
             (string-match-p "config\\.org$" (buffer-file-name))
             (string-match-p "\\.emacs\\.d" (buffer-file-name)))
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'after-save-hook #'my/org-babel-tangle-config nil t)))

(defgroup seforim nil
  "Seforim library configuration."
  :group 'applications
  :prefix "seforim-")

(defcustom seforim-directory (expand-file-name "~/Documents/seforim/")
  "Root directory of the seforim library."
  :type 'directory
  :group 'seforim)

(defcustom seforim-file-extensions '("org" "pdf" "epub" "docx" "doc" "odt")
  "File extensions to include in searches."
  :type '(repeat string)
  :group 'seforim)

(defcustom seforim-plocate-db "/var/cache/locatedb"
  "Path to the plocate database."
  :type 'file
  :group 'seforim)

(defcustom seforim-plocate-min-query-length 2
  "Minimum query length before running plocate."
  :type 'integer
  :group 'seforim)

;; Ensure directory exists
(unless (file-exists-p seforim-directory)
  (make-directory seforim-directory t))

(require 'cl-lib)
(require 'subr-x)
(require 'seq)

(defun seforim--executable-p (name)
  "Return non-nil if NAME is an executable in PATH."
  (executable-find name))

(defun seforim--plocate-db-readable-p ()
  "Return non-nil if `seforim-plocate-db' exists and is readable."
  (and (stringp seforim-plocate-db)
       (file-exists-p seforim-plocate-db)
       (file-readable-p seforim-plocate-db)))

(defun seforim--check-tools ()
  "Return alist of available tools."
  `((plocate . ,(seforim--executable-p "plocate"))
    (fd . ,(seforim--executable-p "fd"))
    (recoll . ,(seforim--executable-p "recoll"))
    (ripgrep-all . ,(seforim--executable-p "rga"))
    (ripgrep . ,(seforim--executable-p "rg"))))

(defun seforim--plocate-lines (&rest args)
  "Run plocate with ARGS and return output as a list of lines."
  (unless (seforim--executable-p "plocate")
    (user-error "plocate not found in PATH"))
  (unless (seforim--plocate-db-readable-p)
    (user-error "plocate DB not readable: %s\nAdd user to 'plocate' group and re-login"
                seforim-plocate-db))
  (let ((buf (generate-new-buffer " *seforim-plocate*")))
    (unwind-protect
        (let* ((coding-system-for-read 'utf-8-unix)
               (exit (apply #'process-file "plocate" nil buf nil
                            "--database" seforim-plocate-db
                            args)))
          (with-current-buffer buf
            (let ((out (string-trim (buffer-string))))
              (cond
               ((= exit 0)
                (if (string-empty-p out) nil (split-string out "\n" t)))
               (t
                (user-error "plocate failed (exit %s):\n%s" exit out))))))
      (kill-buffer buf))))

(defun seforim-find ()
  "Find a sefer by filename. Uses plocate (indexed) with fd fallback."
  (interactive)
  (if (and (seforim--executable-p "plocate")
           (seforim--plocate-db-readable-p))
      (seforim--find-plocate)
    (seforim--find-fd)))

(defun seforim--find-plocate ()
  "Find sefer using plocate, scoped to `seforim-directory'."
  (let* ((query (string-trim (read-string "Find sefer (plocate): ")))
         (root (file-name-as-directory (expand-file-name seforim-directory))))
    (when (< (length query) seforim-plocate-min-query-length)
      (user-error "Query too short (min %d characters)" seforim-plocate-min-query-length))
    (let* ((lines (seforim--plocate-lines "-i" query))
           (files (seq-filter
                   (lambda (f)
                     (and (string-prefix-p root f)
                          (let ((ext (downcase (or (file-name-extension f) ""))))
                            (member ext seforim-file-extensions))
                          (file-exists-p f)))
                   lines))
           (cands (mapcar (lambda (f)
                            (propertize (file-relative-name f root) 'file f))
                          files)))
      (unless cands
        (user-error "No matches for %S under %s" query root))
      (let* ((choice (completing-read "Select: " cands nil t))
             (file (get-text-property 0 'file choice)))
        (find-file file)))))

(defun seforim--find-fd ()
  "Find sefer using fd (fallback, non-indexed)."
  (unless (seforim--executable-p "fd")
    (user-error "Neither plocate (usable) nor fd found"))
  (let* ((pattern (string-trim (read-string "Find sefer (fd): ")))
         (ext-args (cl-loop for ext in seforim-file-extensions
                            append (list "-e" ext)))
         (cmd (append '("fd" "--color=never" "-i" "-t" "f")
                      ext-args
                      (list pattern seforim-directory)))
         (buf (generate-new-buffer " *seforim-fd*")))
    (unwind-protect
        (let ((coding-system-for-read 'utf-8-unix)
              (exit (apply #'process-file (car cmd) nil buf nil (cdr cmd))))
          (with-current-buffer buf
            (let* ((out (string-trim (buffer-string)))
                   (files (if (or (/= exit 0) (string-empty-p out))
                              nil
                            (split-string out "\n" t))))
              (if files
                  (find-file (completing-read "Select: " files nil t))
                (user-error "No seforim found matching %S" pattern)))))
      (kill-buffer buf))))

(defun seforim-find-fuzzy ()
  "Fuzzy find inside the seforim directory using consult-fd."
  (interactive)
  (unless (fboundp 'consult-fd)
    (user-error "consult-fd not available"))
  (let* ((default-directory seforim-directory)
         (ext-args (cl-loop for ext in seforim-file-extensions
                            append (list "-e" ext)))
         (consult-fd-args (append (list "fd" "--color=never" "-i" "-t" "f")
                                  ext-args)))
    (call-interactively #'consult-fd)))

(defun seforim-search ()
  "Search contents of all seforim. Uses recoll (indexed) with ripgrep-all fallback."
  (interactive)
  (if (seforim--executable-p "recoll")
      (seforim--search-recoll seforim-directory)
    (progn
      (message "recoll not found — falling back to ripgrep-all")
      (seforim--search-ripgrep seforim-directory))))

(defun seforim--search-recoll (directory)
  "Search DIRECTORY using recoll."
  (let* ((query (read-string "Search (recoll): "))
         (dir-filter (format "dir:\"%s\"" (expand-file-name directory)))
         (cmd (format "recoll -t -q %s %s 2>/dev/null"
                      (shell-quote-argument query)
                      (shell-quote-argument dir-filter)))
         (output (shell-command-to-string cmd))
         (results (seforim--parse-recoll output)))
    (if results
        (let* ((selection (completing-read
                           (format "「%s」 " query) results nil t))
               (file (get-text-property 0 'file selection)))
          (find-file file)
          (goto-char (point-min))
          (when (search-forward query nil t)
            (when (derived-mode-p 'org-mode) (org-reveal))
            (recenter)))
      (user-error "No results for '%s'" query))))

(defun seforim--parse-recoll (output)
  "Parse recoll OUTPUT into candidates."
  (let ((lines (split-string output "\n" t))
        (results '())
        (seen (make-hash-table :test 'equal)))
    (dolist (line lines)
      (when (string-match "\\(/[^[:cntrl:]]+\\)" line)
        (let* ((file (match-string 1 line))
               (ext (downcase (or (file-name-extension file) ""))))
          (when (and (member ext seforim-file-extensions)
                     (file-exists-p file)
                     (string-prefix-p (expand-file-name seforim-directory)
                                      (expand-file-name file))
                     (not (gethash file seen)))
            (puthash file t seen)
            (let ((display (file-relative-name file seforim-directory)))
              (push (propertize display 'file file) results))))))
    (nreverse results)))

(defun seforim--search-ripgrep (directory)
  "Search DIRECTORY using ripgrep-all via consult-ripgrep."
  (unless (fboundp 'consult-ripgrep)
    (user-error "consult-ripgrep not available"))
  (let ((consult-ripgrep-args
         (concat "rga --null --line-buffered --color=never "
                 "--line-number --smart-case --no-heading "
                 "--max-columns=1000 --max-columns-preview -- ")))
    (consult-ripgrep directory)))

(defun seforim-search-ripgrep ()
  "Search using ripgrep-all directly."
  (interactive)
  (seforim--search-ripgrep seforim-directory))

(defun seforim-search-current-dir ()
  "Search in current file's directory."
  (interactive)
  (unless buffer-file-name
    (user-error "Not visiting a file"))
  (let ((dir (file-name-directory buffer-file-name)))
    (if (seforim--executable-p "recoll")
        (seforim--search-recoll dir)
      (seforim--search-ripgrep dir))))

(defun seforim-search-choose-dir ()
  "Choose a directory then search in it."
  (interactive)
  (let ((dir (read-directory-name "Search in: " seforim-directory)))
    (if (seforim--executable-p "recoll")
        (seforim--search-recoll dir)
      (seforim--search-ripgrep dir))))

(defun seforim-outline ()
  "Jump to heading in current file."
  (interactive)
  (if (fboundp 'consult-outline)
      (consult-outline)
    (user-error "consult-outline not available")))

(defun seforim-browse ()
  "Open Dirvish at the seforim root."
  (interactive)
  (if (fboundp 'dirvish)
      (dirvish seforim-directory)
    (dired seforim-directory)))

(defun seforim-browse-current ()
  "Open Dirvish in current file's directory."
  (interactive)
  (let ((dir (if buffer-file-name
                 (file-name-directory buffer-file-name)
               seforim-directory)))
    (if (fboundp 'dirvish)
        (dirvish dir)
      (dired dir))))

(defun seforim-toggle-sidebar ()
  "Toggle Dirvish sidebar scoped to the Seforim directory."
  (interactive)
  (unless (fboundp 'dirvish-side)
    (user-error "dirvish-side not available"))
  (dirvish-side seforim-directory))

(defun seforim-reindex ()
  "Rebuild indexes (recoll + system locate DB)."
  (interactive)
  (when (seforim--executable-p "recollindex")
    (message "Starting recoll indexing...")
    (start-process "recollindex" "*seforim-index*" "recollindex"))
  (message "Requesting locate DB update (may require sudo)...")
  (start-process-shell-command
   "update-locatedb" "*seforim-index*"
   "sudo systemctl start update-locatedb.service")
  (display-buffer "*seforim-index*"))

(defun seforim-reindex-recoll ()
  "Rebuild recoll index only."
  (interactive)
  (if (seforim--executable-p "recollindex")
      (progn
        (start-process "recollindex" "*seforim-index*" "recollindex")
        (display-buffer "*seforim-index*"))
    (user-error "recollindex not found")))

(defun seforim-status ()
  "Show status of tools and indexes."
  (interactive)
  (with-current-buffer (get-buffer-create "*Seforim Status*")
    (erase-buffer)
    (insert "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    (insert "           SEFORIM STATUS\n")
    (insert "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

    (insert "TOOLS:\n")
    (dolist (tool (seforim--check-tools))
      (insert (format "  %-14s %s\n"
                      (car tool)
                      (if (cdr tool) "✓" "✗"))))

    (insert "\nSEARCH CAPABILITIES:\n")
    (insert "  plocate      → all types (filename only)\n")
    (insert "  fd           → all types (filename only)\n")
    (insert "  recoll       → org,pdf,epub,docx,doc,odt (indexed)\n")
    (insert "  ripgrep-all  → org,pdf,epub,docx,doc,odt (live search)\n")

    (insert (format "\nFILE EXTENSIONS: %s\n"
                    (mapconcat #'identity seforim-file-extensions ", ")))

    (insert "\nINDEXES:\n")
    (let ((recoll-db (expand-file-name "~/.recoll/xapiandb")))
      (insert (format "  recoll db:   %s\n"
                      (if (file-directory-p recoll-db) "✓ exists" "✗ missing"))))
    (insert (format "  plocate db:  %s (%s)\n"
                    seforim-plocate-db
                    (if (seforim--plocate-db-readable-p)
                        "readable ✓"
                      "NOT readable ✗")))

    (insert "\n[q] close\n")
    (goto-char (point-min))
    (local-set-key (kbd "q") #'quit-window)
    (display-buffer (current-buffer))))

(defhydra seforim-hydra (:color blue :hint nil)
    "
┌─────────────────────────────────────────────────────┐
│                     SEFORIM                         │
├─────────────────────────────────────────────────────┤
│ FIND FILE          │ SEARCH CONTENT                 │
│  _f_ find (plocate) │  _s_ search (recoll)          │
│  _F_ find (fuzzy)   │  _r_ search (ripgrep-all)     │
│                    │  _c_ search current dir        │
│                    │  _S_ search choose dir         │
├─────────────────────────────────────────────────────┤
│ NAVIGATE           │ MANAGE                         │
│  _o_ outline        │  _I_ reindex all               │
│  _t_ toggle sidebar │  _?_ status                    │
│  _b_ browse root    │                               │
│  _B_ browse current │                               │
└─────────────────────────────────────────────────────┘
                     _q_ quit
"
    ("f" seforim-find)
    ("F" seforim-find-fuzzy)
    ("s" seforim-search)
    ("r" seforim-search-ripgrep)
    ("c" seforim-search-current-dir)
    ("S" seforim-search-choose-dir)
    ("o" seforim-outline)
    ("t" seforim-toggle-sidebar)
    ("b" seforim-browse)
    ("B" seforim-browse-current)
    ("I" seforim-reindex)
    ("?" seforim-status)
    ("q" nil))

  (global-set-key (kbd "C-c S") 'seforim-hydra/body)

(provide 'seforim)

;; Start server if not already running (only in GUI mode)
(when (display-graphic-p)
  (require 'server)
  (unless (server-running-p)
    (server-start)))

;; Reset GC threshold
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 2 1000 1000))))

;; Start with Hebrew input
(add-hook 'emacs-startup-hook
          (lambda ()
            (set-input-method "hebrew-full")))

;; Report startup time
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs loaded in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

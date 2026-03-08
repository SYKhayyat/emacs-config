;;; -*- lexical-binding: t; -*-

;; Increase garbage collection threshold for faster startup
(setq gc-cons-threshold (* 50 1000 1000))

;; Disable package.el in favor of use-package (built-in Emacs 29+)
(setq package-enable-at-startup t)

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

;; Enable visual-line-mode globally for word wrap at window edge
(global-visual-line-mode 1)

;; Make sure lines wrap at word boundaries
(setq-default word-wrap t)

;; Wrap at window edge (not at fill-column)
(setq-default truncate-lines nil)

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
  (add-to-list 'recentf-exclude ".*\\.emacs\\.d/.*")
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
  (setq doom-modeline-height 25)
  (setq doom-modeline-buffer-encoding t)
  (setq doom-modeline-input-method t))

(use-package all-the-icons
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

;; Set fonts with different sizes for different UI elements
(when (display-graphic-p)
  ;; Default font for editor text (10pt)
  (when (find-font (font-spec :family "JetBrains Mono"))
    (set-face-attribute 'default nil
                        :family "JetBrains Mono"
                        :height 100
                        :weight 'normal))

  ;; Fallback to DejaVu Sans Mono if JetBrains Mono not found
  (unless (find-font (font-spec :family "JetBrains Mono"))
    (when (find-font (font-spec :family "DejaVu Sans Mono"))
      (set-face-attribute 'default nil
                          :family "DejaVu Sans Mono"
                          :height 100
                          :weight 'normal)))

  ;; Mode-line (status bar) - smaller font (8pt)
  (set-face-attribute 'mode-line nil :height 80)
  (set-face-attribute 'mode-line-inactive nil :height 80)

  ;; Minibuffer - smaller font (8pt)
  (add-hook 'minibuffer-setup-hook
            (lambda ()
              (face-remap-add-relative 'default :height 80)))

  ;; Line numbers - smaller font (8pt)
  (set-face-attribute 'line-number nil :height 80)
  (set-face-attribute 'line-number-current-line nil :height 80)

  ;; Hebrew font
  (when (find-font (font-spec :family "David CLM"))
    (set-fontset-font t 'hebrew (font-spec :family "David CLM" :size 12)))

  ;; Fallback Hebrew fonts
  (unless (find-font (font-spec :family "David CLM"))
    (catch 'font-found
      (dolist (font '("Noto Sans Hebrew" "DejaVu Sans" "Arial Hebrew"))
        (when (find-font (font-spec :family font))
          (set-fontset-font t 'hebrew (font-spec :family font :size 12))
          (throw 'font-found t))))))

;; Also set header-line and other UI elements to smaller size
(with-eval-after-load 'doom-modeline
  (set-face-attribute 'doom-modeline-buffer-file nil :height 80)
  (set-face-attribute 'doom-modeline-buffer-modified nil :height 80)
  (set-face-attribute 'doom-modeline-buffer-major-mode nil :height 80)
  (set-face-attribute 'doom-modeline-info nil :height 80)
  (set-face-attribute 'doom-modeline-project-dir nil :height 80))

;; Enable automatic paragraph direction detection
;; nil means: detect direction per-paragraph based on first strong directional character
;; Hebrew text -> RTL, English text -> LTR (automatically)
(setq-default bidi-paragraph-direction nil)

;; Enable bidirectional reordering
(setq-default bidi-display-reordering t)

;; Inhibit bidi algorithm for performance when not needed
(setq bidi-inhibit-bpa nil)

;; Set default input method to Hebrew
(setq default-input-method "hebrew-full")

;; Bidi paragraph settings
(setq bidi-paragraph-start-re "^")
(setq bidi-paragraph-separate-re "^[ \t\f]*$")

(defun my/set-rtl ()
  "Set buffer direction to RTL (Hebrew)."
  (interactive)
  (setq bidi-paragraph-direction 'right-to-left)
  (message "Direction: RTL (Hebrew) - forced"))

(defun my/set-ltr ()
  "Set buffer direction to LTR (English)."
  (interactive)
  (setq bidi-paragraph-direction 'left-to-right)
  (message "Direction: LTR (English) - forced"))

(defun my/set-auto-direction ()
  "Set buffer direction to automatic (per-paragraph detection)."
  (interactive)
  (setq bidi-paragraph-direction nil)
  (message "Direction: Automatic (per-paragraph)"))

(defun my/toggle-direction ()
  "Toggle between RTL, LTR, and automatic direction."
  (interactive)
  (cond
   ((eq bidi-paragraph-direction 'right-to-left)
    (my/set-ltr))
   ((eq bidi-paragraph-direction 'left-to-right)
    (my/set-auto-direction))
   (t
    (my/set-rtl))))

;; Keybindings for direction toggle
(global-set-key (kbd "C-c d") 'my/toggle-direction)
(global-set-key (kbd "C-c r") 'my/set-rtl)
(global-set-key (kbd "C-c l") 'my/set-ltr)
(global-set-key (kbd "C-c A") 'my/set-auto-direction)

;; Quick input method toggle
(global-set-key (kbd "<f9>") 'toggle-input-method)

;; Add direction indicator to modeline
(defvar my/direction-indicator "")

(defun my/update-direction-indicator ()
  "Update the direction indicator string."
  (setq my/direction-indicator
        (cond
         ((eq bidi-paragraph-direction 'right-to-left) " [RTL]")
         ((eq bidi-paragraph-direction 'left-to-right) " [LTR]")
         (t " [AUTO]"))))

(add-hook 'post-command-hook 'my/update-direction-indicator)

;; Add to mode-line
(setq-default mode-line-format
              (append mode-line-format
                      '((:eval my/direction-indicator))))

(defun my/toggle-bidi-reordering ()
  "Toggle bidirectional text reordering for performance."
  (interactive)
  (setq bidi-display-reordering (not bidi-display-reordering))
  (force-window-update)
  (message "Bidi reordering: %s"
           (if bidi-display-reordering "enabled" "disabled")))

(global-set-key (kbd "C-c B") 'my/toggle-bidi-reordering)

(use-package ispell
  :ensure nil
  :config
  (when (executable-find "hunspell")
    (setq ispell-program-name "hunspell")
    (setq ispell-dictionary "en_US")
    (setq ispell-personal-dictionary "~/.hunspell_personal")
    (setq ispell-really-hunspell t)
    (setq ispell-local-dictionary-alist
          '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']"
             nil ("-d" "en_US") nil utf-8)
            ("he_IL" "[[:alpha:]]" "[^[:alpha:]]" ""
             nil ("-d" "he_IL") nil utf-8)
            ("he" "[[:alpha:]]" "[^[:alpha:]]" ""
             nil ("-d" "he") nil utf-8)))))

(use-package flyspell
  :ensure nil
  :hook ((text-mode . flyspell-mode)
         (prog-mode . flyspell-prog-mode))
  :config
  (setq flyspell-issue-message-flag nil))

(defun my/spell-english ()
  "Switch to English dictionary."
  (interactive)
  (ispell-change-dictionary "en_US")
  (message "Spell checking: English"))

(defun my/spell-hebrew ()
  "Switch to Hebrew dictionary."
  (interactive)
  (ispell-change-dictionary "he_IL")
  (message "Spell checking: Hebrew"))

(global-set-key (kbd "C-c s e") 'my/spell-english)
(global-set-key (kbd "C-c s h") 'my/spell-hebrew)

(use-package vertico
  :init
  (vertico-mode)
  :config
  (setq vertico-cycle t))

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
         ("M-y" . consult-yank-pop)))

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :init
  (global-corfu-mode))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

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
           ("Typst" (mode . typst-mode))
           ("Roam" (directory . "~/Documents/roam/"))
           ("Dired" (mode . dired-mode))
           ("PDF" (mode . pdf-view-mode))
           ("Magit" (name . "^magit"))
           ("Help" (or (mode . help-mode)
                       (mode . helpful-mode)))
           ("Emacs" (or (name . "^\\*scratch\\*")
                        (name . "^\\*Messages\\*"))))))
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

;; Note: Using separate keybindings to avoid conflict with projectile-command-map
(use-package consult-projectile
  :after (consult projectile)
  :bind (("C-c P f" . consult-projectile-find-file)
         ("C-c P s" . consult-projectile-switch-project)))

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

(electric-pair-mode 1)

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
      (insert "# -*- mode: snippet -*-\n")
      (insert "name: Hebrew environment\n")
      (insert "key: heb\n")
      (insert "--\n")
      (insert "\\begin{hebrew}\n$0\n\\end{hebrew}"))

    ;; English environment for LaTeX
    (with-temp-file (expand-file-name "english-env" latex-snippet-dir)
      (insert "# -*- mode: snippet -*-\n")
      (insert "name: English environment\n")
      (insert "key: eng\n")
      (insert "--\n")
      (insert "\\begin{english}\n$0\n\\end{english}"))

    ;; Hebrew org template
    (with-temp-file (expand-file-name "hebrew-doc" org-snippet-dir)
      (insert "# -*- mode: snippet -*-\n")
      (insert "name: Hebrew document\n")
      (insert "key: hebdoc\n")
      (insert "--\n")
      (insert "#+TITLE: ${1:כותרת}\n")
      (insert "#+AUTHOR: ${2:Author}\n")
      (insert "#+DATE: `(format-time-string \"%Y-%m-%d\")`\n")
      (insert "#+LATEX_CLASS: article-unlimited\n")
      (insert "#+LATEX_HEADER: \\babelprovide[main, import]{hebrew}\n")
      (insert "#+OPTIONS: toc:nil\n\n$0"))))

(my/create-hebrew-snippets)

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :config
  (setq dired-listing-switches "-agho --group-directories-first")
  (setq dired-dwim-target t)
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq delete-by-moving-to-trash t))

;; dired-single is unavailable, using dired-subtree instead
(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("<backtab>" . dired-subtree-cycle)))

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :bind (:map dired-mode-map
              ("." . dired-hide-dotfiles-mode)))

(use-package org
  :ensure nil
  :hook ((org-mode . visual-line-mode))
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
  (setq org-agenda-start-on-weekday 0) ; Start on Sunday

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
  :hook ((org-mode . org-modern-mode)
         (org-agenda-mode . org-modern-agenda))
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
      (make-directory (file-name-directory file) t)
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
               '("article-unlimited"
                 "\\documentclass[11pt]{article}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
[EXTRA]

% Hebrew support
\\babelprovide[main, import]{hebrew}
\\babelprovide[import]{english}
\\babelfont{rm}{David CLM}
\\babelfont{sf}{Nachlieli CLM}
\\babelfont{tt}{Miriam Mono CLM}

% Nested footnotes
\\DeclareNewFootnote{default}
\\DeclareNewFootnote{B}
\\DeclareNewFootnote{C}
\\DeclareNewFootnote{D}
\\DeclareNewFootnote{E}
\\DeclareNewFootnote{F}
\\DeclareNewFootnote{G}
\\DeclareNewFootnote{H}
\\DeclareNewFootnote{I}
\\DeclareNewFootnote{J}

% Unlimited sectioning
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
\\setlist[itemize,11]{label=\\textasteriskcentered}
\\setlist[itemize,12]{label=\\textperiodcentered}
\\setlist[itemize,13]{label=\\textbullet}
\\setlist[itemize,14]{label=\\textendash}
\\setlist[itemize,15]{label=\\textasteriskcentered}
\\setlist[itemize,16]{label=\\textperiodcentered}
\\setlist[itemize,17]{label=\\textbullet}
\\setlist[itemize,18]{label=\\textendash}
\\setlist[itemize,19]{label=\\textasteriskcentered}
\\setlist[itemize,20]{label=\\textperiodcentered}
\\setlist[enumerate,1]{label=\\arabic*.}
\\setlist[enumerate,2]{label=\\alph*.}
\\setlist[enumerate,3]{label=\\roman*.}
\\setlist[enumerate,4]{label=\\Alph*.}
\\setlist[enumerate,5]{label=\\arabic*.}
\\setlist[enumerate,6]{label=\\alph*.}
\\setlist[enumerate,7]{label=\\roman*.}
\\setlist[enumerate,8]{label=\\Alph*.}
\\setlist[enumerate,9]{label=\\arabic*.}
\\setlist[enumerate,10]{label=\\alph*.}
\\setlist[enumerate,11]{label=\\roman*.}
\\setlist[enumerate,12]{label=\\Alph*.}
\\setlist[enumerate,13]{label=\\arabic*.}
\\setlist[enumerate,14]{label=\\alph*.}
\\setlist[enumerate,15]{label=\\roman*.}
\\setlist[enumerate,16]{label=\\Alph*.}
\\setlist[enumerate,17]{label=\\arabic*.}
\\setlist[enumerate,18]{label=\\alph*.}
\\setlist[enumerate,19]{label=\\roman*.}
\\setlist[enumerate,20]{label=\\Alph*.}
"
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
               '("report-unlimited"
                 "\\documentclass[11pt]{report}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
[EXTRA]

% Hebrew support
\\babelprovide[main, import]{hebrew}
\\babelprovide[import]{english}
\\babelfont{rm}{David CLM}
\\babelfont{sf}{Nachlieli CLM}
\\babelfont{tt}{Miriam Mono CLM}

% Nested footnotes
\\DeclareNewFootnote{default}
\\DeclareNewFootnote{B}
\\DeclareNewFootnote{C}
\\DeclareNewFootnote{D}
\\DeclareNewFootnote{E}
\\DeclareNewFootnote{F}
\\DeclareNewFootnote{G}
\\DeclareNewFootnote{H}
\\DeclareNewFootnote{I}
\\DeclareNewFootnote{J}

% Unlimited sectioning
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
\\setlist[itemize,11]{label=\\textasteriskcentered}
\\setlist[itemize,12]{label=\\textperiodcentered}
\\setlist[itemize,13]{label=\\textbullet}
\\setlist[itemize,14]{label=\\textendash}
\\setlist[itemize,15]{label=\\textasteriskcentered}
\\setlist[itemize,16]{label=\\textperiodcentered}
\\setlist[itemize,17]{label=\\textbullet}
\\setlist[itemize,18]{label=\\textendash}
\\setlist[itemize,19]{label=\\textasteriskcentered}
\\setlist[itemize,20]{label=\\textperiodcentered}
\\setlist[enumerate,1]{label=\\arabic*.}
\\setlist[enumerate,2]{label=\\alph*.}
\\setlist[enumerate,3]{label=\\roman*.}
\\setlist[enumerate,4]{label=\\Alph*.}
\\setlist[enumerate,5]{label=\\arabic*.}
\\setlist[enumerate,6]{label=\\alph*.}
\\setlist[enumerate,7]{label=\\roman*.}
\\setlist[enumerate,8]{label=\\Alph*.}
\\setlist[enumerate,9]{label=\\arabic*.}
\\setlist[enumerate,10]{label=\\alph*.}
\\setlist[enumerate,11]{label=\\roman*.}
\\setlist[enumerate,12]{label=\\Alph*.}
\\setlist[enumerate,13]{label=\\arabic*.}
\\setlist[enumerate,14]{label=\\alph*.}
\\setlist[enumerate,15]{label=\\roman*.}
\\setlist[enumerate,16]{label=\\Alph*.}
\\setlist[enumerate,17]{label=\\arabic*.}
\\setlist[enumerate,18]{label=\\alph*.}
\\setlist[enumerate,19]{label=\\roman*.}
\\setlist[enumerate,20]{label=\\Alph*.}
"
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
               '("book-unlimited"
                 "\\documentclass[11pt]{book}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
[EXTRA]

% Hebrew support
\\babelprovide[main, import]{hebrew}
\\babelprovide[import]{english}
\\babelfont{rm}{David CLM}
\\babelfont{sf}{Nachlieli CLM}
\\babelfont{tt}{Miriam Mono CLM}

% Nested footnotes
\\DeclareNewFootnote{default}
\\DeclareNewFootnote{B}
\\DeclareNewFootnote{C}
\\DeclareNewFootnote{D}
\\DeclareNewFootnote{E}
\\DeclareNewFootnote{F}
\\DeclareNewFootnote{G}
\\DeclareNewFootnote{H}
\\DeclareNewFootnote{I}
\\DeclareNewFootnote{J}

% Unlimited sectioning
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
\\setlist[itemize,11]{label=\\textasteriskcentered}
\\setlist[itemize,12]{label=\\textperiodcentered}
\\setlist[itemize,13]{label=\\textbullet}
\\setlist[itemize,14]{label=\\textendash}
\\setlist[itemize,15]{label=\\textasteriskcentered}
\\setlist[itemize,16]{label=\\textperiodcentered}
\\setlist[itemize,17]{label=\\textbullet}
\\setlist[itemize,18]{label=\\textendash}
\\setlist[itemize,19]{label=\\textasteriskcentered}
\\setlist[itemize,20]{label=\\textperiodcentered}
\\setlist[enumerate,1]{label=\\arabic*.}
\\setlist[enumerate,2]{label=\\alph*.}
\\setlist[enumerate,3]{label=\\roman*.}
\\setlist[enumerate,4]{label=\\Alph*.}
\\setlist[enumerate,5]{label=\\arabic*.}
\\setlist[enumerate,6]{label=\\alph*.}
\\setlist[enumerate,7]{label=\\roman*.}
\\setlist[enumerate,8]{label=\\Alph*.}
\\setlist[enumerate,9]{label=\\arabic*.}
\\setlist[enumerate,10]{label=\\alph*.}
\\setlist[enumerate,11]{label=\\roman*.}
\\setlist[enumerate,12]{label=\\Alph*.}
\\setlist[enumerate,13]{label=\\arabic*.}
\\setlist[enumerate,14]{label=\\alph*.}
\\setlist[enumerate,15]{label=\\roman*.}
\\setlist[enumerate,16]{label=\\Alph*.}
\\setlist[enumerate,17]{label=\\arabic*.}
\\setlist[enumerate,18]{label=\\alph*.}
\\setlist[enumerate,19]{label=\\roman*.}
\\setlist[enumerate,20]{label=\\Alph*.}
"
                 ("\\part{%s}" . "\\part*{%s}")
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")
                 ("\\subsubparagraph{%s}" . "\\subsubparagraph*{%s}")
                 ("\\subsubsubparagraph{%s}" . "\\subsubsubparagraph*{%s}")
                 ("\\subsubsubsubparagraph{%s}" . "\\subsubsubsubparagraph*{%s}")))

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
        '(;; Default template
          ("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                             "#+title: ${title}\n#+date: %U\n#+filetags: \n\n")
           :unnarrowed t)

          ;; Hebrew template
          ("h" "hebrew" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                             "#+title: ${title}\n#+date: %U\n#+filetags: hebrew\n#+LATEX_CLASS: article-unlimited\n#+LATEX_HEADER: \\babelprovide[main, import]{hebrew}\n\n")
           :unnarrowed t)

          ;; Research note template
          ("r" "research" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                             "#+title: ${title}\n#+date: %U\n#+filetags: research\n#+LATEX_CLASS: article-unlimited\n\n* מקור / Source\n\n* הערות / Notes\n\n* שאלות / Questions\n\n")
           :unnarrowed t)

          ;; Concept/term template (Hebrew)
          ("c" "concept" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                             "#+title: ${title}\n#+date: %U\n#+filetags: concept hebrew\n\n* הגדרה / Definition\n\n* דוגמאות / Examples\n\n* קשרים / Related\n\n")
           :unnarrowed t)

          ;; Literature note template
          ("l" "literature" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                             "#+title: ${title}\n#+date: %U\n#+filetags: literature\n#+LATEX_CLASS: article-unlimited\n\n* ביבליוגרפיה / Bibliographic Info\n- Author: \n- Year: \n- Title: \n\n* תקציר / Summary\n\n* ציטוטים / Key Quotes\n\n* הערות / Notes\n\n")
           :unnarrowed t)

          ;; Project template
          ("p" "project" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                             "#+title: ${title}\n#+date: %U\n#+filetags: project\n\n* מטרות / Goals\n\n* משימות / Tasks\n** TODO \n\n* הערות / Notes\n\n* משאבים / Resources\n\n")
           :unnarrowed t)))

  ;; Daily notes templates with Hebrew support
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

  ;; Flyspell
  (add-hook 'LaTeX-mode-hook 'flyspell-mode))

(with-eval-after-load 'latex
  (setq preview-auto-cache-preamble t)
  (setq preview-scale-function 1.5))

(defvar my/latex-unlimited-structure
  "% ============================================
% UNLIMITED SECTIONING DEPTH
% ============================================
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

% ============================================
% UNLIMITED LIST NESTING
% ============================================
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
\\setlist[itemize,11]{label=\\textasteriskcentered}
\\setlist[itemize,12]{label=\\textperiodcentered}
\\setlist[itemize,13]{label=\\textbullet}
\\setlist[itemize,14]{label=\\textendash}
\\setlist[itemize,15]{label=\\textasteriskcentered}
\\setlist[itemize,16]{label=\\textperiodcentered}
\\setlist[itemize,17]{label=\\textbullet}
\\setlist[itemize,18]{label=\\textendash}
\\setlist[itemize,19]{label=\\textasteriskcentered}
\\setlist[itemize,20]{label=\\textperiodcentered}

\\setlist[enumerate,1]{label=\\arabic*.}
\\setlist[enumerate,2]{label=\\alph*.}
\\setlist[enumerate,3]{label=\\roman*.}
\\setlist[enumerate,4]{label=\\Alph*.}
\\setlist[enumerate,5]{label=\\arabic*.}
\\setlist[enumerate,6]{label=\\alph*.}
\\setlist[enumerate,7]{label=\\roman*.}
\\setlist[enumerate,8]{label=\\Alph*.}
\\setlist[enumerate,9]{label=\\arabic*.}
\\setlist[enumerate,10]{label=\\alph*.}
\\setlist[enumerate,11]{label=\\roman*.}
\\setlist[enumerate,12]{label=\\Alph*.}
\\setlist[enumerate,13]{label=\\arabic*.}
\\setlist[enumerate,14]{label=\\alph*.}
\\setlist[enumerate,15]{label=\\roman*.}
\\setlist[enumerate,16]{label=\\Alph*.}
\\setlist[enumerate,17]{label=\\arabic*.}
\\setlist[enumerate,18]{label=\\alph*.}
\\setlist[enumerate,19]{label=\\roman*.}
\\setlist[enumerate,20]{label=\\Alph*.}
"
  "LaTeX preamble for unlimited sectioning and list nesting.")

(defvar my/latex-hebrew-preamble
  (concat "% ============================================
% HEBREW SUPPORT (BABEL)
% ============================================
\\usepackage{fontspec}
\\usepackage[bidi=basic]{babel}
\\babelprovide[main, import]{hebrew}
\\babelprovide[import]{english}
\\babelfont{rm}{David CLM}
\\babelfont{sf}{Nachlieli CLM}
\\babelfont{tt}{Miriam Mono CLM}

% ============================================
% NESTED FOOTNOTES (BIGFOOT)
% ============================================
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
\\DeclareNewFootnote{J}

" my/latex-unlimited-structure)
  "Complete Hebrew LaTeX preamble with unlimited structure.")

(defvar my/latex-polyglossia-preamble
  (concat "% ============================================
% HEBREW SUPPORT (POLYGLOSSIA)
% ============================================
\\usepackage{fontspec}
\\usepackage{polyglossia}
\\setmainlanguage{hebrew}
\\setotherlanguage{english}
\\setmainfont{David CLM}
\\setsansfont{Nachlieli CLM}
\\setmonofont{Miriam Mono CLM}

% ============================================
% NESTED FOOTNOTES (BIGFOOT)
% ============================================
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
\\DeclareNewFootnote{J}

" my/latex-unlimited-structure)
  "Complete Polyglossia Hebrew preamble with unlimited structure.")

(defun my/insert-hebrew-preamble ()
  "Insert complete Hebrew LaTeX preamble (Babel)."
  (interactive)
  (insert my/latex-hebrew-preamble))

(defun my/insert-polyglossia-preamble ()
  "Insert complete Hebrew LaTeX preamble (Polyglossia)."
  (interactive)
  (insert my/latex-polyglossia-preamble))

(defun my/insert-unlimited-structure ()
  "Insert only unlimited sectioning and list preamble."
  (interactive)
  (insert my/latex-unlimited-structure))

;; ============================================
;; SIMPLE FOOTNOTES (for non-nested use)
;; Each level appears in its own block at page bottom
;; ============================================

(defun my/insert-footnote-level-1 ()
  "Insert level 1 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnote{}")
  (backward-char 1))

(defun my/insert-footnote-level-2 ()
  "Insert level 2 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteB{}")
  (backward-char 1))

(defun my/insert-footnote-level-3 ()
  "Insert level 3 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteC{}")
  (backward-char 1))

(defun my/insert-footnote-level-4 ()
  "Insert level 4 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteD{}")
  (backward-char 1))

(defun my/insert-footnote-level-5 ()
  "Insert level 5 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteE{}")
  (backward-char 1))

(defun my/insert-footnote-level-6 ()
  "Insert level 6 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteF{}")
  (backward-char 1))

(defun my/insert-footnote-level-7 ()
  "Insert level 7 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteG{}")
  (backward-char 1))

(defun my/insert-footnote-level-8 ()
  "Insert level 8 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteH{}")
  (backward-char 1))

(defun my/insert-footnote-level-9 ()
  "Insert level 9 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteI{}")
  (backward-char 1))

(defun my/insert-footnote-level-10 ()
  "Insert level 10 footnote (simple, non-nested)."
  (interactive)
  (insert "\\footnoteJ{}")
  (backward-char 1))

;; ============================================
;; NESTED FOOTNOTES (for true nesting)
;; Use \footnotemarkX + \footnotetextX{} inside another footnote
;; ============================================

(defun my/insert-footnotemark-level-2 ()
  "Insert level 2 footnote mark (for nesting inside another footnote)."
  (interactive)
  (insert "\\footnotemarkB"))

(defun my/insert-footnotemark-level-3 ()
  "Insert level 3 footnote mark (for nesting)."
  (interactive)
  (insert "\\footnotemarkC"))

(defun my/insert-footnotemark-level-4 ()
  "Insert level 4 footnote mark (for nesting)."
  (interactive)
  (insert "\\footnotemarkD"))

(defun my/insert-footnotemark-level-5 ()
  "Insert level 5 footnote mark (for nesting)."
  (interactive)
  (insert "\\footnotemarkE"))

(defun my/insert-footnotetext-level-2 ()
  "Insert level 2 footnote text (for nesting inside another footnote)."
  (interactive)
  (insert "\\footnotetextB{}")
  (backward-char 1))

(defun my/insert-footnotetext-level-3 ()
  "Insert level 3 footnote text (for nesting)."
  (interactive)
  (insert "\\footnotetextC{}")
  (backward-char 1))

(defun my/insert-footnotetext-level-4 ()
  "Insert level 4 footnote text (for nesting)."
  (interactive)
  (insert "\\footnotetextD{}")
  (backward-char 1))

(defun my/insert-footnotetext-level-5 ()
  "Insert level 5 footnote text (for nesting)."
  (interactive)
  (insert "\\footnotetextE{}")
  (backward-char 1))

(defun my/insert-nested-footnote-template ()
  "Insert a template for nested footnotes."
  (interactive)
  (insert "\\footnote{%\n  First level text\\footnotemarkB.\n  \\footnotetextB{Second level text.}%\n}")
  (search-backward "First level text"))

;; ============================================
;; KEYBINDINGS
;; ============================================

(with-eval-after-load 'latex
  ;; Simple footnotes: C-c f <number>
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

  ;; Nested footnote marks: C-c f M <number>
  (define-key LaTeX-mode-map (kbd "C-c f M 2") 'my/insert-footnotemark-level-2)
  (define-key LaTeX-mode-map (kbd "C-c f M 3") 'my/insert-footnotemark-level-3)
  (define-key LaTeX-mode-map (kbd "C-c f M 4") 'my/insert-footnotemark-level-4)
  (define-key LaTeX-mode```org
-map (kbd "C-c f M 5") 'my/insert-footnotemark-level-5)

  ;; Nested footnote texts: C-c f T <number>
  (define-key LaTeX-mode-map (kbd "C-c f T 2") 'my/insert-footnotetext-level-2)
  (define-key LaTeX-mode-map (kbd "C-c f T 3") 'my/insert-footnotetext-level-3)
  (define-key LaTeX-mode-map (kbd "C-c f T 4") 'my/insert-footnotetext-level-4)
  (define-key LaTeX-mode-map (kbd "C-c f T 5") 'my/insert-footnotetext-level-5)

  ;; Nested footnote template: C-c f n
  (define-key LaTeX-mode-map (kbd "C-c f n") 'my/insert-nested-footnote-template))

;; ConTeXt is handled by AUCTeX automatically via scheme-full
;; Add ConTeXt-specific configuration

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

;; Define Typst major mode
(define-derived-mode typst-mode text-mode "Typst"
  "Major mode for editing Typst files."
  (setq-local comment-start "// ")
  (setq-local comment-end ""))

(add-to-list 'auto-mode-alist '("\\.typ\\'" . typst-mode))

;; Typst compilation functions
(defun my/typst-compile ()
  "Compile current Typst file."
  (interactive)
  (let ((file (buffer-file-name)))
    (compile (format "typst compile %s" (shell-quote-argument file)))))

(defun my/typst-watch ()
  "Start Typst watch mode for live preview."
  (interactive)
  (let ((file (buffer-file-name)))
    (async-shell-command
     (format "typst watch %s" (shell-quote-argument file)))))

(defun my/typst-view ()
  "View compiled PDF."
  (interactive)
  (let* ((file (buffer-file-name))
         (pdf (concat (file-name-sans-extension file) ".pdf")))
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

;; Visual nested footnote helper (Typst does not support true nested blocks)
(defun my/typst-insert-nested-footnote-helper ()
  "Insert Typst visual nested footnote helper function.
Note: Typst does not support true hierarchical footnote blocks.
This creates visual separation within a single footnote."
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

;; Define keymap for typst-mode
(defvar typst-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map text-mode-map)
    (define-key map (kbd "C-c C-c") 'my/typst-compile)
    (define-key map (kbd "C-c C-w") 'my/typst-watch)
    (define-key map (kbd "C-c C-v") 'my/typst-view)
    (define-key map (kbd "C-c C-p h") 'my/insert-typst-hebrew-preamble)
    (define-key map (kbd "C-c C-p f") 'my/typst-insert-nested-footnote-helper)
    map)
  "Keymap for `typst-mode'.")

;; Typst LSP via Eglot
(with-eval-after-load 'eglot
  (when (executable-find "tinymist")
    (add-to-list 'eglot-server-programs
                 '(typst-mode . ("tinymist")))))

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq pdf-view-display-size 'fit-page)
  (setq pdf-view-continuous t)
  (add-hook 'pdf-view-mode-hook
            (lambda ()
              (pdf-view-midnight-minor-mode 1))))

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
         (python-ts-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (java-mode . eglot-ensure)
         (typst-mode . eglot-ensure))
  :config
  (setq eglot-autoshutdown t))

;; Use built-in python.el instead of python-mode package
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

(use-package sh-script
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

r: RTL (Hebrew)    l: LTR (English)   t: Toggle direction
a: Auto (per-paragraph)               i: Toggle input method
h: Hebrew spell    e: English spell   B: Toggle bidi
q: quit
"
    ("r" my/set-rtl)
    ("l" my/set-ltr)
    ("a" my/set-auto-direction)
    ("t" my/toggle-direction)
    ("h" my/spell-hebrew)
    ("e" my/spell-english)
    ("i" toggle-input-method)
    ("B" my/toggle-bidi-reordering)
    ("q" nil))

  (global-set-key (kbd "C-c D") 'hydra-direction/body)

  ;; Org-roam hydra
  (defhydra hydra-org-roam (:color blue :hint nil)
    "
Org-Roam

f: Find node       i: Insert node     c: Capture
l: Toggle buffer   g: Graph           t: Add tag
d: Daily today     D: Daily date      u: Roam UI
q: quit
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

LaTeX:
  p: Babel preamble      g: Polyglossia      u: Unlimited struct
  n: Nested footnote template
ConTeXt:
  c: Hebrew preamble     f: Local footnote
Typst:
  t: Hebrew preamble     F: Nested footnote helper
q: quit
"
    ("p" my/insert-hebrew-preamble)
    ("g" my/insert-polyglossia-preamble)
    ("u" my/insert-unlimited-structure)
    ("n" my/insert-nested-footnote-template)
    ("c" my/insert-context-hebrew-preamble)
    ("f" my/insert-context-local-footnote)
    ("t" my/insert-typst-hebrew-preamble)
    ("F" my/typst-insert-nested-footnote-helper)
    ("q" nil))

  (global-set-key (kbd "C-c T") 'hydra-document/body)

  ;; LaTeX footnotes hydra
  (defhydra hydra-latex-footnotes (:color blue :hint nil)
    "
LaTeX Footnotes

Simple (non-nested):
  1-9,0: Insert \\footnote, \\footnoteB, ... \\footnoteJ

Nested (mark + text, use inside another footnote):
  M: Insert mark     T: Insert text     n: Insert template
q: quit
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
    ("M" (message "Use C-c f M 2-5 for marks") :color red)
    ("T" (message "Use C-c f T 2-5 for texts") :color red)
    ("n" my/insert-nested-footnote-template)
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

;; Ensure necessary directories exist
(dolist (dir '("~/Documents/org/"
               "~/Documents/roam/"
               "~/Documents/roam/daily/"
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

;; Speed up rendering
(setq auto-window-vscroll nil)
(setq fast-but-imprecise-scrolling t)
(setq jit-lock-defer-time 0)

;; Handle long lines better
(setq-default so-long-threshold 400)
(global-so-long-mode 1)

;; Increase read process output
(setq read-process-output-max (* 1024 1024))

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

;;; 16-hydras.el --- Unified Hydra menus -*- lexical-binding: t; -*-

;; Forward declarations for variables/functions from other config files
(defvar seforim-directory)

(use-package hydra
  :demand t
  :config
  (defhydra hydra-seforim (:color blue :hint nil)
    "
+------------------------------------------------------------------------+
| S E F O R I M  3.0 --- S I X  S E A R C H  M E T H O D S             |
+------------------------------------------------------------------------+
| FILE NAME SEARCH                   TEXT SEARCH (inside documents)      |
|  f: plocate (instant, exact)        s: rg (notes: .org/.tex)          |
|  F: fd (filesystem)                 S: rga (PDFs/EPUBs)               |
|  z: fuzzy fd (typo-tolerant)        r: recoll (boolean, advanced)     |
|  L: fd live (as-you-type)           R: rg live (consult-ripgrep)      |
+------------------------------------------------------------------------+
| READING & NAVIGATION               LIBRARY MANAGEMENT                 |
|  w: reading room toggle             l: study log (recent files)       |
|  e: open EPUB file                  b: browse seforim directory       |
|  d: jump to daf (PDF/Org)           ?: library status                 |
|  o: consult outline                                                    |
+------------------------------------------------------------------------+
"
    ;; File name search
    ("f" seforim-find-plocate)
    ("F" seforim-find-fd)
    ("z" seforim-find-fuzzy)
    ("L" seforim-find-fd-live)

    ;; Text search inside documents
    ("s" seforim-search-rg)
    ("S" seforim-search-rga)
    ("r" seforim-search-recoll)
    ("R" seforim-search-rg-live)

    ;; Reading & navigation
    ("w" my/toggle-reading-room)
    ("e" (lambda () (interactive)
           (let ((dir (if (boundp 'seforim-directory)
                          seforim-directory
                        "~/Documents/seforim/")))
             (find-file (read-file-name "Open EPUB: " dir nil t nil
                                        (lambda (f)
                                          (or (file-directory-p f)
                                              (string-suffix-p ".epub" f t))))))))
    ("d" seforim-goto-daf)
    ("o" consult-outline)
    ("b" (lambda () (interactive)
           (if (boundp 'seforim-directory)
               (dired seforim-directory)
             (user-error "seforim-directory not defined; load 14-seforim first"))))

    ;; Library management
    ("l" seforim-show-log)
    ("?" seforim-status)

    ("q" nil))

  (global-set-key (kbd "C-c S") #'hydra-seforim/body)

  (defhydra hydra-direction (:color blue :hint nil)
    "
Direction: r: RTL  l: LTR  t: toggle  B: bidi reorder
Writing:   w: focused mode  W: set width
Spell:     h: Hebrew  e: English  a: both
"
    ("r" my/set-rtl)
    ("l" my/set-ltr)
    ("t" my/toggle-direction)
    ("B" my/toggle-bidi-reordering)
    ("h" my/spell-hebrew)
    ("e" my/spell-english)
    ("a" my/spell-both)
    ("w" my/toggle-focused-writing)
    ("W" my/set-focused-width)
    ("q" nil))

  (global-set-key (kbd "C-c D") #'hydra-direction/body)

  (defhydra hydra-roam (:color blue :hint nil)
    "
Roam: f: find node  i: insert link  c: capture
      d: daily  g: graph  u: UI toggle
"
    ("f" org-roam-node-find)
    ("i" org-roam-node-insert)
    ("c" org-roam-capture)
    ("d" org-roam-dailies-goto-today)
    ("g" org-roam-graph)
    ("u" org-roam-ui-mode)
    ("q" nil))

  (global-set-key (kbd "C-c N") #'hydra-roam/body)

  (defhydra hydra-academic (:color blue :hint nil)
    "
Academic: b: open bib  i: insert cite  r: insert ref
Web:      s: sefaria  o: otzar  S: scholar
"
    ("b" citar-open)
    ("i" citar-insert-citation)
    ("r" citar-insert-reference)
    ("s" (lambda () (interactive) (engine/search-sefaria)))
    ("o" (lambda () (interactive) (engine/search-otzar)))
    ("S" (lambda () (interactive) (engine/search-scholar)))
    ("q" nil))

  (global-set-key (kbd "C-c A") #'hydra-academic/body)

  (defhydra hydra-rich-footnotes (:color blue :hint nil)
    "
Rich Footnotes: l: LX  t: Typst  c: CT  p: LX Pre  T: Ty Pre  C: CT Pre
"
    ("l" my/insert-rich-footnote-latex)
    ("t" my/insert-rich-footnote-typst)
    ("c" my/insert-rich-footnote-context)
    ("p" my/insert-latex-rich-footnotes-preamble)
    ("T" my/insert-typst-rich-footnotes-preamble)
    ("C" my/insert-context-rich-footnotes-preamble)
    ("q" nil))

  (global-set-key (kbd "C-c F") #'hydra-rich-footnotes/body)

  (defhydra hydra-nix (:color blue :hint nil)
    "
Nix: r: rebuild  h: home switch  g: garbage  e: open config
"
    ("r" my/nixos-rebuild)
    ("h" my/home-manager-switch)
    ("g" my/nix-garbage-collect)
    ("e" my/open-config)
    ("q" nil))

  (global-set-key (kbd "C-c E") #'hydra-nix/body))

(provide '16-hydras)

;;; 16-hydras.el --- Unified Hydra menus -*- lexical-binding: t; -*-

;; Forward declarations for variables/functions from other config files
(defvar seforim-directory)

(use-package hydra
  :demand t
  :config
(defhydra hydra-seforim (:color blue :hint nil)
  "
+------------------------------------------------------------------------+
| S E F O R I M  ---  F O U R  S E A R C H  M E T H O D S               |
+------------------------------------------------------------------------+
| FILE NAME SEARCH                   TEXT SEARCH (inside documents)      |
|  f: plocate (system-wide)           s: rg (respects niqqud setting)    |
|  F: fd (exact, seforim only)                                           |
|  z: fd fuzzy (glob, seforim only)                                      |
+------------------------------------------------------------------------+
| READING & NAVIGATION               LIBRARY MANAGEMENT                 |
|  w: reading room toggle             l: study log (recent files)        |
|  e: open EPUB file                  b: browse seforim directory       |
|  d: jump to daf (PDF/Org)           ?: library status                 |
|  o: consult outline                                                    |
+------------------------------------------------------------------------+
"
  ;; File name search
  ("f" seforim-find-plocate)
  ("F" seforim-find-fd)
  ("z" seforim-find-fuzzy)

  ;; Text search
  ("s" seforim-search-rg)

  ;; Reading & navigation
  ("w" my/toggle-reading-room)
  ("e" (lambda () (interactive)
         (find-file (read-file-name "Open EPUB: " seforim-directory nil t nil
                                    (lambda (f) (or (file-directory-p f) (string-suffix-p ".epub" f t)))))))
  ("d" seforim-goto-daf)
  ("o" consult-outline)
  ("b" (lambda () (interactive) (dired seforim-directory)))

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

  ;; ... rest of hydras unchanged ...
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

  (global-set-key (kbd "C-c C-n") #'hydra-roam/body)   ;; <-- changed to C-c C-n (avoid conflict)

  ;; ... etc. (other hydras unchanged)
  )

(provide '16-hydras)

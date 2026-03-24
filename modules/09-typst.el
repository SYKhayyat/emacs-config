;;; 09-typst.el --- Typst mode configuration -*- lexical-binding: t; -*-

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
  "Compile current Typst file."
  (interactive)
  (compile (format "typst compile %s" (shell-quote-argument buffer-file-name))))

(defun my/typst-watch ()
  "Watch and compile Typst file."
  (interactive)
  (async-shell-command (format "typst watch %s" (shell-quote-argument buffer-file-name))))

(defun my/typst-view ()
  "View compiled PDF."
  (interactive)
  (let ((pdf (concat (file-name-sans-extension buffer-file-name) ".pdf")))
    (if (file-exists-p pdf)
        (find-file-other-window pdf)
      (message "PDF not found"))))

(defun my/insert-typst-hebrew-preamble ()
  "Insert Hebrew preamble for Typst."
  (interactive)
  (insert "#set text(lang: \"he\", font: \"David CLM\")
#set page(flipped: true)
#set heading(numbering: \"1.1.1\")

"))

(with-eval-after-load 'typst-ts-mode
  (when (boundp 'typst-ts-mode-map)
    (define-key typst-ts-mode-map (kbd "C-c C-c") #'my/typst-compile)
    (define-key typst-ts-mode-map (kbd "C-c C-w") #'my/typst-watch)
    (define-key typst-ts-mode-map (kbd "C-c C-v") #'my/typst-view)
    (define-key typst-ts-mode-map (kbd "C-c t h") #'my/insert-typst-hebrew-preamble)))

(provide '09-typst)
;;; 09-typst.el ends here

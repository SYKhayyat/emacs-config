;;; init.el --- Load configuration from config.org -*- lexical-binding: t; -*-

(require 'org)

(let ((config-org (expand-file-name "config.org" user-emacs-directory))
      (config-el (expand-file-name "config.el" user-emacs-directory)))
  (when (or (not (file-exists-p config-el))
            (file-newer-than-file-p config-org config-el))
    (org-babel-tangle-file config-org config-el "emacs-lisp"))
  (load-file config-el))

;;; init.el ends here

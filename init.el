;;; init.el --- Load configuration from config.org -*- lexical-binding: t; -*-

(require 'org)

(let ((config-org (expand-file-name "config.org" user-emacs-directory))
      (config-el (expand-file-name "config.el" user-emacs-directory)))
  (when (or (not (file-exists-p config-el))
            (file-newer-than-file-p config-org config-el))
    (org-babel-tangle-file config-org config-el "emacs-lisp"))
  (load-file config-el))

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-vc-selected-packages
   '((typst-ts-mode :vc-backend Git :url
		    "https://git.sr.ht/~meow_king/typst-ts-mode"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

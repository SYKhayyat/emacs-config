;;; 20-projectile.el --- Project management -*- lexical-binding: t; -*-

(use-package projectile
  :demand t
  :config
  (projectile-mode 1)
  (setq projectile-project-search-path '("~/Documents/"))
  (add-to-list 'projectile-project-root-files "Bavli")
  
  ;; Define C-c p as a prefix map explicitly to avoid "non-prefix" errors
  (define-key global-map (kbd "C-c p") 'projectile-command-map))

(use-package consult-projectile
  :after (consult projectile)
  :config
  ;; Bind p inside the already established C-c p map
  (define-key projectile-command-map (kbd "p") #'consult-projectile))

(provide '20-projectile)
;;; 20-projectile.el ends here

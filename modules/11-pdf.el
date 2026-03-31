;; --- 1. PROOF OF LOAD ---
(message "DEBUG: 11-pdf.org is loading...")

;; --- 2. THE NIXOS "VACCINES" ---
;; We define these as empty interactive functions to stop Nix's
;; buggy internal setup scripts from crashing the load.
(defun pdf-loader-install (&optional arg) (interactive))
(defun pdf-tools-install (&optional arg) (interactive))
(defun pdf-occur-global-minor-mode (&optional arg) (interactive))

;; --- 3. PHYSICAL STORE RESOLUTION ---
;; We follow the symlinks to the real Nix Store folder.
(require 'pdf-tools)
(let* ((wrapped-path (locate-library "pdf-tools"))
       (real-path (when wrapped-path (file-truename wrapped-path)))
       (real-dir (when real-path (file-name-directory real-path))))

  (if (and real-dir (file-directory-p real-dir))
      (progn
        ;; Force Emacs to look in the REAL physical store directory
        (add-to-list 'load-path real-dir)

        ;; Set the binary path (it's in the same folder)
        (setq pdf-info-epdfinfo-program (expand-file-name "epdfinfo" real-dir))
        (setenv "PDF_TOOLS_EPDFINFO" pdf-info-epdfinfo-program)

        ;; Force-load the core modules by name without extensions
        ;; This ensures we get the functions defined regardless of native-comp
        (require 'pdf-util nil t)
        (require 'pdf-info nil t)
        (require 'pdf-view nil t)
        (require 'pdf-cache nil t)

        (message "DEBUG: Real Nix Dir: %s" real-dir)
        (message "DEBUG: Binary Path: %s" pdf-info-epdfinfo-program))
    (warn "CRITICAL: Could not find the physical Nix Store path!")))

;; --- 4. THE GIBBERISH PREVENTER ---
;; Enforce PDF mode association globally at the top level
(setq auto-mode-alist (append '(("\\.pdf\\'" . pdf-view-mode)) auto-mode-alist))

;; --- 5. SAFE INITIALIZATION ---
(use-package pdf-tools
  :ensure nil
  :demand t
  :config
  ;; We check if the function was finally defined by our 'require' calls
  (if (fboundp 'pdf-info-initialize)
      (progn
        (pdf-info-initialize)
        (pdf-cache-install)
        (pdf-history-install)
        (message "DEBUG: PDF Engine successfully initialized."))
    ;; EMERGENCY FALLBACK: If Nix is still being difficult, we force-load the specific file
    (let ((info-file (expand-file-name "pdf-info.el" (file-name-directory (file-truename (locate-library "pdf-tools"))))))
      (load info-file)
      (when (fboundp 'pdf-info-initialize) (pdf-info-initialize))))

  ;; Settings
  (setq-default pdf-view-display-size 'fit-page)
  (setq pdf-view-use-scaling t)

  ;; Midnight Mode (Wheat on Dark Charcoal)
  (setq pdf-view-midnight-colors '("#dcdccc" . "#1a1a1a"))
  (add-hook 'pdf-view-mode-hook #'pdf-view-midnight-minor-mode)

  ;; --- 6. SEFORIM NAVIGATION (PAGE & DAF) ---
  (defun seforim-pdf-goto-page (page)
    (interactive "nGo to page: ")
    (pdf-view-goto-page page))

  (defun seforim-pdf-goto-daf (daf-num amud)
    "Jump to Daf in Gemara PDF. 2 'a' -> Page 3."
    (interactive "nDaf Number: \nsAmud (a or b): ")
    (let* ((base-page (* (- daf-num 2) 2))
           (offset (if (string= amud "a") 3 4))
           (target-page (+ base-page offset)))
      (pdf-view-goto-page target-page)))

  ;; Bind keys inside pdf-view-mode
  (with-eval-after-load 'pdf-view
    (define-key pdf-view-mode-map (kbd "g") 'seforim-pdf-goto-page)
    (define-key pdf-view-mode-map (kbd "G") 'seforim-pdf-goto-daf)
    (define-key pdf-view-mode-map (kbd "o") 'pdf-outline)
    (define-key pdf-view-mode-map (kbd "s s") 'pdf-occur)))

;; --- 7. FEATURE PROVIDER ---
(provide '11-pdf)

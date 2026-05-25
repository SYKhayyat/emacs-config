;; [[file:14d-seforim-extras.org::+BEGIN_SRC emacs-lisp][No heading:1]]
;;; 14d-seforim-extras.el --- Seforim: daf, study-log, niqqud isearch, status, embark  -*- lexical-binding: t; -*-

(require '14a-seforim-core)
(require '14b-seforim-candidates)
(require 'embark)

;; ---------------------------------------------------------------------------
;; Daf Navigation
;; ---------------------------------------------------------------------------

(defun seforim-goto-daf ()
  "Navigate to a Talmudic daf/amud in the current buffer or PDF."
  (interactive)
  (let* ((daf  (read-number "Daf: " 2))
         (alef (seforim--h-c 0))
         (bet  (seforim--h-c 1))
         (amud (completing-read "Amud: " (list alef bet) nil t)))
    (cond
     ((derived-mode-p 'pdf-view-mode)
      (if (fboundp 'my/pdf-jump-to-daf)
          (funcall 'my/pdf-jump-to-daf daf amud)
        (pdf-view-goto-page
         (+ (* (1- daf) 2) (if (string= amud alef) 0 1)))))
     (t
      (let* ((h-daf  (seforim--num-to-heb daf))
             (s-daf  (seforim--h-s 3 16))
             (s-amud (seforim--h-s 16 13 5 3))
             (re     (concat s-daf "\\s-+"
                             (regexp-quote h-daf)
                             "\\s-+" s-amud
                             "[^0-9]+" (regexp-quote amud))))
        (goto-char (point-min))
        (if (re-search-forward re nil t)
            (progn
              (when (derived-mode-p 'org-mode) (org-reveal))
              (recenter))
          (message "Daf not found")))))))

;; ---------------------------------------------------------------------------
;; Study Log
;; ---------------------------------------------------------------------------

(defvar seforim--log-list nil)

(defun seforim--load-log ()
  "Load the study log from its file."
  (setq seforim--log-list nil)
  (when (file-exists-p seforim-study-log-path)
    (condition-case nil
        (with-temp-buffer
          (insert-file-contents seforim-study-log-path)
          (setq seforim--log-list (read (current-buffer))))
      (error nil))))

(defun seforim--list-subdirs ()
  "List immediate subdirectories of seforim-directory."
  (when (file-directory-p seforim-directory)
    (seq-filter (lambda (f)
                  (and (file-directory-p f)
                       (not (member (file-name-nondirectory f) '("." "..")))))
                (directory-files seforim-directory t))))

(defun seforim-show-log ()
  "Browse the study log and reopen a previously visited sefer."
  (interactive)
  (seforim--load-log)
  (if (null seforim--log-list)
      (message "Study log is empty.")
    (let* ((fmt  (mapcar
                  (lambda (x)
                    (format "%s  (%s)"
                            (car x)
                            (format-time-string "%Y-%m-%d %H:%M" (cdr x))))
                  seforim--log-list))
           (sel  (completing-read "Log: " fmt nil t)))
      (when sel
        (let* ((name    (car (split-string sel "  (")))
               (file    (if (executable-find "plocate")
                            (let ((candidates (split-string
                                               (shell-command-to-string
                                                (concat "plocate --literal " (shell-quote-argument name) " "
                                                        (shell-quote-argument (expand-file-name seforim-directory))))
                                               "\n" t)))
                              (car candidates))
                          (car (directory-files-recursively
                                seforim-directory
                                (concat "\\`" (regexp-quote name) "\\'")))))
               (file (or file (car (directory-files-recursively
                                    seforim-directory
                                    (concat "\\`" (regexp-quote name) "\\'"))))))
          (if file
              (seforim--open-file file nil)
            (message "File not found in library: %s" name)))))))

;; ---------------------------------------------------------------------------
;; In-Buffer Niqqud‑Ignoring Isearch
;; ---------------------------------------------------------------------------

(defun seforim--niqqud-isearch-search-fun (string &optional bound noerror count)
  "Search for STRING with optional niqqud, respecting isearch-forward."
  (let ((regex (seforim--build-niqqud-regex string)))
    (if isearch-forward
        (re-search-forward regex bound noerror count)
      (re-search-backward regex bound noerror count))))

(defun seforim-isearch-forward ()
  "Start isearch forward that ignores Hebrew niqqud."
  (interactive)
  (let ((isearch-search-fun-function
         (lambda () #'seforim--niqqud-isearch-search-fun)))
    (isearch-forward)))

(defun seforim-isearch-backward ()
  "Start isearch backward that ignores Hebrew niqqud."
  (interactive)
  (let ((isearch-search-fun-function
         (lambda () #'seforim--niqqud-isearch-search-fun)))
    (isearch-backward)))

(define-minor-mode seforim-mode
  "Minor mode for Jewish library files. Provides niqqud‑ignoring isearch."
  :lighter " Seforim"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map seforim-inbuffer-niqqud-key #'seforim-isearch-forward)
            map))

(defun seforim--auto-enable-mode ()
  "Enable `seforim-mode' when visiting a file under `seforim-directory'."
  (when (and buffer-file-name
             (string-prefix-p (seforim--base-dir) (expand-file-name buffer-file-name)))
    (seforim-mode 1)))
(add-hook 'find-file-hook #'seforim--auto-enable-mode)

;; ---------------------------------------------------------------------------
;; Library Status
;; ---------------------------------------------------------------------------

(defun seforim-status ()
  "Display seforim library status information."
  (interactive)
  (seforim--load-log)
  (let* ((dir (expand-file-name seforim-directory))
         (exists (file-directory-p dir))
         (subdirs (when exists (seforim--list-subdirs)))
         (subdir-count (length subdirs))
         (log-count (length seforim--log-list))
         (tools '(("plocate" . "filename search")
                  ("fd" . "filename search")
                  ("rg" . "text search")
                  ("rga" . "deep text search")
                  ("recoll" . "advanced text search")))
         (tool-status (mapconcat
                       (lambda (pair)
                         (format "  %-10s %-25s %s"
                                 (car pair)
                                 (cdr pair)
                                 (if (executable-find (car pair)) "[OK]" "[MISSING]")))
                       tools "\n")))
    (with-help-window "*Seforim Status*"
      (princ (format "Seforim Library Status\n"))
      (princ (format "======================\n\n"))
      (princ (format "Directory:    %s\n" dir))
      (princ (format "Exists:       %s\n" (if exists "yes" "NO")))
      (princ (format "Subdirs:      %d\n" subdir-count))
      (when subdirs
        (dolist (d subdirs)
          (princ (format "  - %s\n" (file-name-nondirectory
                                      (directory-file-name d))))))
      (princ (format "\nStudy log:    %d entries\n" log-count))
      (princ (format "Log path:     %s\n" seforim-study-log-path))
      (princ (format "\nTool availability:\n%s\n" tool-status))
      (princ (format "\nNiqqud ignore: %s\n" (if seforim-niqqud-ignore "ON" "off")))
      (princ (format "Max results:   %d\n" seforim-max-results)))))

;; ---------------------------------------------------------------------------
;; Embark Actions
;; ---------------------------------------------------------------------------

(defun seforim-embark-open-tab (file)
  "Open FILE in a new tab (for Embark)."
  (interactive "f")
  (let ((seforim--new-tab-flag t))
    (seforim--open-file file nil nil)))

(defun seforim-embark-open-external (file)
  "Open FILE with external default application."
  (interactive "f")
  (seforim--open-file file nil t))

(defun seforim-embark-copy-name (file)
  "Copy file name to kill ring."
  (interactive "f")
  (kill-new (file-name-nondirectory file))
  (message "Copied: %s" (file-name-nondirectory file)))

(defun seforim-embark-consult-line (file)
  "Run consult-line inside FILE."
  (interactive "f")
  (find-file file)
  (consult-line))

(defvar seforim-embark-file-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "t") #'seforim-embark-open-tab)
    (define-key map (kbd "C-o") #'seforim-embark-open-external)
    (define-key map (kbd "c") #'seforim-embark-copy-name)
    (define-key map (kbd "s") #'seforim-embark-consult-line)
    map)
  "Embark keymap for seforim file candidates.")

(with-eval-after-load 'embark
  (add-to-list 'embark-keymap-alist '(file . seforim-embark-file-map)))

;; ---------------------------------------------------------------------------
;; Provide
;; ---------------------------------------------------------------------------

(provide '14d-seforim-extras)
;;; 14d-seforim-extras.el ends here
;; No heading:1 ends here

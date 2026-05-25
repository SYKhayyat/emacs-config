;; [[file:14a-seforim-core.org::+BEGIN_SRC emacs-lisp][No heading:1]]
;;; 14a-seforim-core.el --- Seforim: config, Hebrew utilities, paths  -*- lexical-binding: t; -*-

(require 'consult)
(require 'embark)
(require 'cl-lib)
(require 'subr-x)
(require 'crm)

;; ---------------------------------------------------------------------------
;; User Configuration
;; ---------------------------------------------------------------------------

(defgroup seforim nil "Jewish library management." :group 'applications)

(defcustom seforim-directory (expand-file-name "~/Documents/seforim/")
  "Base path for the seforim library."
  :type 'directory)

(defcustom seforim-study-log-path
  (expand-file-name "~/.cache/emacs/seforim/study-log.el")
  "File where the study log is stored."
  :type 'file)

(defcustom seforim-niqqud-ignore t
  "If non-nil, full-text search (rg/rga) will ignore Hebrew niqqud."
  :type 'boolean)

(defcustom seforim-inbuffer-niqqud-key (kbd "C-c s")
  "Key binding for niqqud‑ignoring isearch in `seforim-mode'."
  :type 'key-sequence)

(defcustom seforim-consult-idle-delay 0.15
  "Idle delay in seconds before running async search process."
  :type 'float)

(defcustom seforim-max-results 200
  "Maximum number of results to show in search commands."
  :type 'integer
  :group 'seforim)

;; ---------------------------------------------------------------------------
;; Hebrew Utilities
;; ---------------------------------------------------------------------------

(defun seforim--h-c (id)
  "Hebrew char from Aleph offset (1488)."
  (char-to-string (+ 1488 id)))

(defun seforim--h-s (&rest ids)
  "Hebrew string from IDs."
  (apply #'concat (mapcar #'seforim--h-c ids)))

(defun seforim--num-to-heb (n)
  "Convert integer N to Hebrew numeral string."
  (let* ((thousands (/ n 1000))
         (rem       (% n 1000))
         (h-list    '(nil (23) (24) (25) (26) (26 23)
                      (26 24) (26 25) (26 26) (26 26 23)))
         (t-list    '(nil 9 10 11 12 13 14 18 21 22))
         (o-list    '(nil 0 1 2 3 4 5 6 7 8))
         (h-idx     (/ rem 100))
         (t-rem     (% rem 100))
         (t-idx     (/ t-rem 10))
         (o-idx     (% t-rem 10))
         (suffix
          (cond
           ((= t-rem 15) (seforim--h-s 8 5))
           ((= t-rem 16) (seforim--h-s 8 6))
           (t (concat
               (if (> t-idx 0) (seforim--h-c (nth t-idx t-list)) "")
               (if (> o-idx 0) (seforim--h-c (nth o-idx o-list)) ""))))))
    (concat
     (when (> thousands 0)
       (concat (seforim--h-c (nth thousands o-list)) "'"))
     (let ((codes (nth h-idx h-list)))
       (if (consp codes) (apply #'seforim--h-s codes) ""))
     suffix)))

;; ---------------------------------------------------------------------------
;; Niqqud Handling
;; ---------------------------------------------------------------------------

(defconst seforim--niqqud-re
  (concat "[" (char-to-string #x0591) "-" (char-to-string #x05C7) "]")
  "Regex matching a single Hebrew niqqud/cantillation character.")

(defun seforim--strip-niqqud (str)
  "Remove Hebrew niqqud (U+0591-U+05C7) from STR."
  (replace-regexp-in-string seforim--niqqud-re "" str))

(defun seforim--build-niqqud-regex (query)
  "Build a PCRE regex from QUERY matching regardless of niqqud.
First strips niqqud from QUERY itself."
  (let* ((stripped-query (seforim--strip-niqqud query))
         (niqqud-opt (concat seforim--niqqud-re "*")))
    (mapconcat
     (lambda (c)
       (concat (regexp-quote (char-to-string c)) niqqud-opt))
     (string-to-list stripped-query)
     "")))
;; ---------------------------------------------------------------------------
;; Path Helpers
;; ---------------------------------------------------------------------------

(defun seforim--base-dir ()
  "Return normalized base directory."
  (file-name-as-directory (expand-file-name seforim-directory)))

(defun seforim--format-path (path)
  "Shorten PATH for display, showing last 3 components."
  (let* ((base (seforim--base-dir))
         (rel  (file-relative-name (expand-file-name path) base))
         (parts (split-string rel "/")))
    (if (>= (length parts) 3)
        (mapconcat #'identity (last parts 3) "/")
      rel)))

(defun seforim--normalize-dir (path)
  "Return a clean, existing directory path."
  (when (and path (not (string-empty-p (string-trim path))))
    (let* ((expanded (expand-file-name (string-trim path)))
           (real     (condition-case nil (file-truename expanded) (error expanded)))
           (clean    (replace-regexp-in-string "/+" "/" real))
           (result   (if (and (> (length clean) 1) (string-suffix-p "/" clean))
                         (substring clean 0 -1)
                       clean)))
      (when (and (file-exists-p result) (file-directory-p result))
        result))))

(defun seforim--validate-dirs (dirs)
  "Filter DIRS through `seforim--normalize-dir'; error if none remain."
  (let ((valid (delq nil (mapcar #'seforim--normalize-dir dirs))))
    (unless valid
      (user-error "No valid search directories found"))
    valid))

;; ---------------------------------------------------------------------------
;; Directory Selection
;; ---------------------------------------------------------------------------

(defun seforim--choose-dirs ()
  "Prompt user to pick one, several, or all subdirectories.
Returns validated absolute paths.  All search commands use these directories."
  (let* ((base   (seforim--normalize-dir (seforim--base-dir)))
         (choice (completing-read "Scope: 1 Single  2 Multi  3 All: "
                                  '("1" "2" "3") nil t)))
    (unless base
      (user-error "Base seforim directory does not exist: %s" seforim-directory))
    (cond
     ((equal choice "1")
      (let* ((raw (read-directory-name "Search in: "
                                       (file-name-as-directory base)
                                       nil t))
             (dir (seforim--normalize-dir raw)))
        (unless dir (user-error "Directory does not exist: %s" raw))
        (list dir)))
     ((equal choice "2")
      (let* ((entries  (directory-files base t nil t))
             (subdirs  (cl-remove-if-not
                        (lambda (f)
                          (and (file-directory-p f)
                               (not (member (file-name-nondirectory f) '("." "..")))))
                        entries))
             (rel->abs (mapcar (lambda (d) (cons (file-relative-name d base) d)) subdirs))
             (rel-names (mapcar #'car rel->abs))
             (sel       (completing-read-multiple "Dirs (comma-separated): " rel-names nil t)))
        (when (null sel) (user-error "No directories selected"))
        (seforim--validate-dirs
         (mapcar (lambda (s) (cdr (assoc s rel->abs))) sel))))
     ((equal choice "3") (list base))
     (t (user-error "Invalid choice")))))

;; ---------------------------------------------------------------------------
;; Provide
;; ---------------------------------------------------------------------------

(provide '14a-seforim-core)
;;; 14a-seforim-core.el ends here
;; No heading:1 ends here

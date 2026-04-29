;; [[file:14-seforim.org::+BEGIN_SRC emacs-lisp][No heading:1]]
;;; 14-seforim.el --- Seforim library search and study -*- lexical-binding: t; -*-

;; Copyright (C) 2024
;; Author: Seforim Library
;; Package-Requires: ((emacs "28.1") (consult "1.0"))

;;; Commentary:
;; A comprehensive seforim (Jewish texts) library management system.
;; Provides search across PDF and text files with niqqud-insensitive
;; matching, daf navigation, study logging, and multiple opening methods.
;;
;; Action dispatch in all search commands:
;;   RET           — open file (at line for grep results)
;;   C-u RET       — open file in new tab
;;   C-u C-u RET   — open file externally (xdg-open)
;;
;; Six search commands (synchronous, query then results):
;;   seforim-find-plocate  — filename via plocate
;;   seforim-find-fd       — filename via fd
;;   seforim-find-fuzzy    — filename fuzzy via fd --regex
;;   seforim-search-rg     — full-text via rg (ripgrep)
;;   seforim-search-rga    — full-text via rga (ripgrep-all)
;;   seforim-search-recoll — full-text via recoll
;;
;; Two live (as-you-type) variants:
;;   seforim-find-fd-live    — live filename via fd + consult--find
;;   seforim-search-rg-live  — live full-text via consult-ripgrep
;;
;; Requires external tools: fd, rg (and optionally rga, plocate, recoll).
;; Assumes NixOS with tools available in PATH.

;;; Code:

(require 'cl-lib)
(require 'consult)
(require 'seq)
(require 'subr-x)

;; Forward declarations for optional packages
(declare-function pdf-view-goto-page "pdf-view" (page))
(defvar embark-file-map)

;; ============================================================
;; Customization Variables
;; ============================================================

(defgroup seforim nil
  "Seforim library search and study tools."
  :group 'tools
  :prefix "seforim-")

(defcustom seforim-directory (expand-file-name "~/Documents/seforim/")
  "Root directory for seforim library."
  :type 'directory
  :group 'seforim)

(defcustom seforim-study-log-path
  (expand-file-name "~/.cache/emacs/seforim/study-log.el")
  "Path to persist study log."
  :type 'file
  :group 'seforim)

(defcustom seforim-niqqud-ignore t
  "When non-nil, full-text searches ignore Hebrew niqqud (vowel marks)."
  :type 'boolean
  :group 'seforim)

(defcustom seforim-inbuffer-niqqud-key "C-c s"
  "Key binding string for in-buffer niqqud-insensitive isearch in `seforim-mode'.
Takes effect when the mode map is built at load time; changes require restart."
  :type 'string
  :group 'seforim)

(defcustom seforim-max-results 500
  "Maximum number of grep results to collect per directory.
Passed as --max-count to rg/rga.  Set to 0 for no limit."
  :type 'integer
  :group 'seforim)

;; ============================================================
;; Niqqud Handling
;; ============================================================

(defconst seforim--niqqud-min #x0591
  "Lower bound of Hebrew niqqud/cantillation Unicode range.")

(defconst seforim--niqqud-max #x05C7
  "Upper bound of Hebrew niqqud/cantillation Unicode range.")

(defun seforim--niqqud-char-p (char)
  "Return non-nil if CHAR is a Hebrew niqqud or cantillation mark."
  (and (>= char seforim--niqqud-min)
       (<= char seforim--niqqud-max)))

(defun seforim--strip-niqqud (str)
  "Remove all niqqud characters from STR."
  (apply #'string
         (seq-remove #'seforim--niqqud-char-p (string-to-list str))))

(defun seforim--pcre-quote (str)
  "Escape PCRE metacharacters in STR."
  (replace-regexp-in-string "[][\\.^$*+?{}()|]" "\\\\\\&" str))

(defun seforim--build-niqqud-regex-pcre (query)
  "Build a PCRE regex from QUERY that matches with optional niqqud.
Each Hebrew letter can be followed by zero or more niqqud marks.
Non-Hebrew characters are PCRE-escaped.
Used for rg/rga with --pcre2."
  (let ((niqqud-class "[\\x{0591}-\\x{05C7}]*")
        (stripped (seforim--strip-niqqud query)))
    (mapconcat
     (lambda (c)
       (if (and (>= c #x05D0) (<= c #x05EA))
           (concat (seforim--pcre-quote (string c)) niqqud-class)
         (seforim--pcre-quote (string c))))
     (string-to-list stripped)
     "")))

(defun seforim--build-niqqud-regex-emacs (query)
  "Build an Emacs regex from QUERY for niqqud-insensitive matching.
Uses actual Unicode characters for the character class range."
  (let ((niqqud-class (format "[%c-%c]*" seforim--niqqud-min seforim--niqqud-max))
        (stripped (seforim--strip-niqqud query)))
    (mapconcat
     (lambda (c)
       (if (and (>= c #x05D0) (<= c #x05EA))
           (concat (regexp-quote (string c)) niqqud-class)
         (regexp-quote (string c))))
     (string-to-list stripped)
     "")))

;; ============================================================
;; Directory Scope Selection
;; ============================================================

(defvar seforim--last-selected-dirs nil
  "Cache of last selected directories.")

(defun seforim--list-subdirs ()
  "List immediate subdirectories of `seforim-directory'."
  (when (file-directory-p seforim-directory)
    (seq-filter #'file-directory-p
                (directory-files seforim-directory t "\\`[^.]"))))

(defun seforim--select-dirs ()
  "Prompt user to select one, multiple, or all subdirectories.
Returns a list of absolute directory paths."
  (unless (file-directory-p seforim-directory)
    (user-error "Seforim directory does not exist: %s" seforim-directory))
  (let* ((subdirs (seforim--list-subdirs))
         (dir-names (mapcar (lambda (d)
                              (file-name-nondirectory (directory-file-name d)))
                            subdirs))
         (all-label "[All directories]")
         (choices (cons all-label dir-names))
         (selected (completing-read-multiple
                    "Select seforim directories: "
                    choices nil t)))
    (let ((result
           (if (member all-label selected)
               (list (expand-file-name seforim-directory))
             (mapcar (lambda (name)
                       (file-name-as-directory
                        (expand-file-name name seforim-directory)))
                     selected))))
      (setq seforim--last-selected-dirs result)
      result)))

;; ============================================================
;; Short Path Utilities
;; ============================================================

(defun seforim--short-path (filepath)
  "Return last 3 path components of FILEPATH."
  (let* ((clean (directory-file-name filepath))
         (parts (split-string (abbreviate-file-name clean) "/" t))
         (n (length parts))
         (start (max 0 (- n 3))))
    (if (null parts)
        filepath
      (string-join (seq-drop parts start) "/"))))

(defun seforim--truncate-snippet (text &optional max-len)
  "Truncate TEXT to MAX-LEN (default 80) characters."
  (let ((limit (or max-len 80))
        (cleaned (string-trim (replace-regexp-in-string "[\n\r\t]+" " " text))))
    (if (> (length cleaned) limit)
        (concat (substring cleaned 0 (- limit 3)) "...")
      cleaned)))

;; ============================================================
;; Candidate Map (hash table for robust data passing)
;; ============================================================

(defvar seforim--candidate-map (make-hash-table :test 'equal)
  "Hash table mapping display strings to (file line snippet) for grep results.")

(defvar seforim--file-candidate-map (make-hash-table :test 'equal)
  "Hash table mapping display strings to absolute file paths.")

(defun seforim--candidate-map-clear ()
  "Clear candidate maps."
  (clrhash seforim--candidate-map)
  (clrhash seforim--file-candidate-map))

;; ============================================================
;; File Opening Utilities
;; ============================================================

(defvar seforim--log-list nil
  "In-memory study log: list of (filename . timestamp) pairs.")

(defun seforim--ensure-log-dir ()
  "Ensure the directory for the study log exists."
  (let ((dir (file-name-directory seforim-study-log-path)))
    (unless (file-directory-p dir)
      (make-directory dir t))))

(defun seforim--load-log ()
  "Load study log from disk."
  (seforim--ensure-log-dir)
  (when (file-exists-p seforim-study-log-path)
    (condition-case err
        (with-temp-buffer
          (insert-file-contents seforim-study-log-path)
          (setq seforim--log-list (read (current-buffer))))
      (error
       (message "Seforim: failed to load study log: %s" (error-message-string err))
       (setq seforim--log-list nil)))))

(defun seforim--save-log ()
  "Save study log to disk."
  (seforim--ensure-log-dir)
  (condition-case err
      (with-temp-file seforim-study-log-path
        (let ((print-length nil)
              (print-level nil))
          (prin1 seforim--log-list (current-buffer))))
    (error
     (message "Seforim: failed to save study log: %s" (error-message-string err)))))

(defun seforim--log-access (filepath)
  "Log access to FILEPATH with current timestamp."
  (push (cons (expand-file-name filepath)
              (format-time-string "%Y-%m-%d %H:%M:%S"))
        seforim--log-list)
  (seforim--save-log))

(defun seforim--open-file (filepath &optional line)
  "Open FILEPATH, optionally at LINE. Log access."
  (when (and filepath (file-exists-p filepath))
    (seforim--log-access filepath)
    (find-file filepath)
    (when (and line (> line 0))
      (goto-char (point-min))
      (forward-line (1- line)))))

(defun seforim--open-file-new-tab (filepath &optional line)
  "Open FILEPATH in a new tab, optionally at LINE. Log access."
  (when (and filepath (file-exists-p filepath))
    (seforim--log-access filepath)
    (tab-bar-new-tab)
    (find-file filepath)
    (when (and line (> line 0))
      (goto-char (point-min))
      (forward-line (1- line)))
    (tab-bar-rename-tab (file-name-nondirectory filepath))))

(defun seforim--open-file-external (filepath)
  "Open FILEPATH with the system's external application."
  (when (and filepath (file-exists-p filepath))
    (seforim--log-access filepath)
    (let ((cmd (cond
                ((eq system-type 'gnu/linux) "xdg-open")
                ((eq system-type 'darwin) "open")
                ((memq system-type '(windows-nt cygwin)) "start")
                (t "xdg-open"))))
      (call-process cmd nil 0 nil (expand-file-name filepath)))))

;; ============================================================
;; Action Dispatch
;; ============================================================

(defun seforim--dispatch-file-action (filepath &optional line)
  "Dispatch open action on FILEPATH at LINE based on `current-prefix-arg'.
No prefix: open normally.  C-u: new tab.  C-u C-u: external."
  (when filepath
    (cond
     ((equal current-prefix-arg '(16))
      (seforim--open-file-external filepath))
     ((equal current-prefix-arg '(4))
      (seforim--open-file-new-tab filepath line))
     (t
      (seforim--open-file filepath line)))))

;; ============================================================
;; Candidate Parsing
;; ============================================================

(defun seforim--parse-grep-line (line)
  "Parse a NUL-separated grep LINE (file\\0line:text) into (file linenum text).
Falls back to colon-separated parsing if no NUL found.
Returns nil if LINE cannot be parsed."
  (when line
    (cond
     ;; NUL-separated (from rg --null): file\0linenum:text
     ((string-match "\\`\\(.+?\\)\0\\([0-9]+\\)[:\0]\\(.*\\)\\'" line)
      (list (match-string 1 line)
            (string-to-number (match-string 2 line))
            (match-string 3 line)))
     ;; Colon-separated fallback: file:linenum:text
     ((string-match "\\`\\(.+?\\):\\([0-9]+\\):\\(.*\\)\\'" line)
      (list (match-string 1 line)
            (string-to-number (match-string 2 line))
            (match-string 3 line)))
     (t nil))))

;; ============================================================
;; Synchronous Process Runner
;; ============================================================

(defun seforim--run-command-lines (program args)
  "Run PROGRAM with ARGS synchronously, return output lines as a list.
Returns nil on error or non-zero/non-one exit code."
  (condition-case err
      (with-temp-buffer
        (let ((exit (apply #'call-process program nil t nil args)))
          (when (memq exit '(0 1))
            (goto-char (point-min))
            (let ((lines nil))
              (while (not (eobp))
                (let ((line (buffer-substring-no-properties
                             (line-beginning-position)
                             (line-end-position))))
                  (unless (string-empty-p (string-trim line))
                    (push line lines)))
                (forward-line 1))
              (nreverse lines)))))
    (error
     (message "Seforim: command %s failed: %s" program (error-message-string err))
     nil)))

;; ============================================================
;; Efficient List Accumulation Helper
;; ============================================================

(defun seforim--collect-from-dirs (dirs func)
  "Call FUNC for each directory in DIRS, collecting all results efficiently.
FUNC takes a single directory path argument and returns a list of results.
Returns a single flat list of all results."
  (let ((chunks nil))
    (dolist (dir dirs)
      (let ((results (funcall func dir)))
        (when results
          (push results chunks))))
    (apply #'append (nreverse chunks))))

;; ============================================================
;; Filename Search: Shared Completion
;; ============================================================

(defun seforim--filename-search-complete (results prompt)
  "Present filename RESULTS with PROMPT via `completing-read'.
Dispatches open action based on prefix arg."
  (seforim--candidate-map-clear)
  (if (null results)
      (message "No results found.")
    (setq results (delete-dups results))
    (let ((display-list nil)
          (seen (make-hash-table :test 'equal)))
      (dolist (filepath results)
        (when (file-exists-p filepath)
          (let* ((short (seforim--short-path filepath))
                 (display (if (gethash short seen)
                              (format "%s  [%s]" short
                                      (abbreviate-file-name
                                       (file-name-directory filepath)))
                            short)))
            (puthash short t seen)
            (puthash display filepath seforim--file-candidate-map)
            (push display display-list))))
      (setq display-list (nreverse display-list))
      (when display-list
        (let* ((selected (completing-read
                          (format "%s (%d): " prompt (length display-list))
                          display-list nil t))
               (filepath (gethash selected seforim--file-candidate-map)))
          (when filepath
            (seforim--dispatch-file-action filepath)))))))

;; ============================================================
;; Filename Search: plocate
;; ============================================================

(defun seforim-find-plocate ()
  "Filename search using plocate in selected seforim directories.
Results filtered to selected directory scope.
\\[universal-argument] RET opens in new tab.
\\[universal-argument] \\[universal-argument] RET opens externally."
  (interactive)
  (unless (executable-find "plocate")
    (user-error "plocate not found in PATH"))
  (let* ((dirs (seforim--select-dirs))
         (input (read-string "plocate search: ")))
    (when (string-empty-p (string-trim input))
      (user-error "Empty search query"))
    (let* ((raw (seforim--run-command-lines
                 "plocate" (list "-i" "--limit" "500" input)))
           (all-results
            (when raw
              (seq-filter
               (lambda (line)
                 (let ((trimmed (string-trim line)))
                   (and (not (string-empty-p trimmed))
                        (file-exists-p trimmed)
                        (cl-some (lambda (d)
                                   (string-prefix-p (expand-file-name d) trimmed))
                                 dirs))))
               raw))))
      (seforim--filename-search-complete all-results "plocate"))))

;; ============================================================
;; Filename Search: fd
;; ============================================================

(defun seforim-find-fd ()
  "Filename search using fd in selected seforim directories.
\\[universal-argument] RET opens in new tab.
\\[universal-argument] \\[universal-argument] RET opens externally."
  (interactive)
  (unless (executable-find "fd")
    (user-error "fd not found in PATH"))
  (let* ((dirs (seforim--select-dirs))
         (input (read-string "fd search: ")))
    (when (string-empty-p (string-trim input))
      (user-error "Empty search query"))
    (let ((all-results
           (seforim--collect-from-dirs
            dirs
            (lambda (dir)
              (let ((lines (seforim--run-command-lines
                            "fd"
                            (list "--type" "f" "--color" "never"
                                  "--ignore-case"
                                  "--search-path" (expand-file-name dir)
                                  input))))
                (mapcar #'string-trim (seq-remove #'string-empty-p
                                                   (or lines nil))))))))
      (seforim--filename-search-complete all-results "fd"))))

;; ============================================================
;; Filename Search: Fuzzy
;; ============================================================

(defun seforim--make-fuzzy-pattern (input)
  "Convert INPUT into a fuzzy regex for fd --regex.
Inserts .* between each character."
  (let ((trimmed (string-trim input)))
    (if (string-empty-p trimmed)
        ""
      (mapconcat (lambda (c) (regexp-quote (string c)))
                 (string-to-list trimmed)
                 ".*"))))

(defun seforim-find-fuzzy ()
  "Fuzzy filename search using fd in selected seforim directories.
\\[universal-argument] RET opens in new tab.
\\[universal-argument] \\[universal-argument] RET opens externally."
  (interactive)
  (unless (executable-find "fd")
    (user-error "fd not found in PATH"))
  (let* ((dirs (seforim--select-dirs))
         (input (read-string "fd fuzzy search: ")))
    (when (string-empty-p (string-trim input))
      (user-error "Empty search query"))
    (let* ((pattern (seforim--make-fuzzy-pattern input))
           (all-results
            (seforim--collect-from-dirs
             dirs
             (lambda (dir)
               (let ((lines (seforim--run-command-lines
                             "fd"
                             (list "--type" "f" "--color" "never"
                                   "--ignore-case" "--regex"
                                   "--search-path" (expand-file-name dir)
                                   pattern))))
                 (mapcar #'string-trim (seq-remove #'string-empty-p
                                                    (or lines nil))))))))
      (seforim--filename-search-complete all-results "fd fuzzy"))))

;; ============================================================
;; Full-Text Search: Shared Grep Completion
;; ============================================================

(defun seforim--grep-search-complete (results prompt)
  "Present grep RESULTS with PROMPT via `completing-read'.
Each result is a raw grep line (file:line:text or file\\0line:text).
Displays short-path:line with snippet annotation via hash table lookup.
Dispatches open action based on prefix arg."
  (seforim--candidate-map-clear)
  (if (null results)
      (message "No results found.")
    (let ((display-list nil)
          (counter 0))
      (dolist (raw results)
        (let ((parsed (seforim--parse-grep-line raw)))
          (when parsed
            (let* ((file (nth 0 parsed))
                   (linenum (nth 1 parsed))
                   (text (nth 2 parsed))
                   (short (seforim--short-path file))
                   (snippet (seforim--truncate-snippet text))
                   (display (format "%s:%d" short linenum)))
              ;; Guarantee unique display keys
              (when (gethash display seforim--candidate-map)
                (setq counter (1+ counter))
                (setq display (format "%s:%d <%d>" short linenum counter)))
              (puthash display (list file linenum snippet)
                       seforim--candidate-map)
              (push display display-list)))))
      (setq display-list (nreverse display-list))
      (if (null display-list)
          (message "No parseable results found.")
        (let* ((annotator
                (lambda (cand)
                  (when-let ((info (gethash cand seforim--candidate-map)))
                    (concat "  " (nth 2 info)))))
               (selected
                (let ((completion-extra-properties
                       (list :annotation-function annotator)))
                  (completing-read
                   (format "%s (%d): " prompt (length display-list))
                   display-list nil t)))
               (info (gethash selected seforim--candidate-map)))
          (when info
            (seforim--dispatch-file-action (nth 0 info) (nth 1 info))))))))

;; ============================================================
;; Full-Text Search: rg args builder
;; ============================================================

(defun seforim--rg-base-args ()
  "Return base argument list for rg/rga commands."
  (let ((args (list "--no-heading" "--line-number"
                    "--color" "never" "--max-columns" "200"
                    "--ignore-case" "--with-filename" "--null")))
    (when (and (integerp seforim-max-results) (> seforim-max-results 0))
      (setq args (append args (list "--max-count"
                                    (number-to-string seforim-max-results)))))
    args))

;; ============================================================
;; Full-Text Search: rg (ripgrep)
;; ============================================================

(defun seforim-search-rg (&optional arg)
  "Full-text search using rg in selected seforim directories.
With prefix ARG at invocation, toggle niqqud-ignore for this search.
At the results prompt, use prefix arg before RET for alternate actions:
  C-u RET       — open in new tab
  C-u C-u RET   — open externally"
  (interactive "P")
  (unless (executable-find "rg")
    (user-error "rg not found in PATH"))
  (let* ((ignore-niqqud (if arg (not seforim-niqqud-ignore) seforim-niqqud-ignore))
         (dirs (seforim--select-dirs))
         (input (read-string (format "rg search%s: "
                                     (if ignore-niqqud " [niqqud-ignore]" "")))))
    (when (string-empty-p (string-trim input))
      (user-error "Empty search query"))
    (let* ((query (if ignore-niqqud
                      (seforim--build-niqqud-regex-pcre input)
                    input))
           (base-args (seforim--rg-base-args))
           (pcre-args (when ignore-niqqud (list "--pcre2")))
           (all-results
            (seforim--collect-from-dirs
             dirs
             (lambda (dir)
               (seforim--run-command-lines
                "rg"
                (append base-args pcre-args
                        (list "-e" query "--" (expand-file-name dir))))))))
      (seforim--grep-search-complete all-results "rg"))))

;; ============================================================
;; Full-Text Search: rga (ripgrep-all)
;; ============================================================

(defun seforim-search-rga (&optional arg)
  "Full-text search using rga (ripgrep-all) in selected seforim directories.
With prefix ARG at invocation, toggle niqqud-ignore for this search."
  (interactive "P")
  (unless (executable-find "rga")
    (user-error "rga not found in PATH"))
  (let* ((ignore-niqqud (if arg (not seforim-niqqud-ignore) seforim-niqqud-ignore))
         (dirs (seforim--select-dirs))
         (input (read-string (format "rga search%s: "
                                     (if ignore-niqqud " [niqqud-ignore]" "")))))
    (when (string-empty-p (string-trim input))
      (user-error "Empty search query"))
    (let* ((query (if ignore-niqqud
                      (seforim--build-niqqud-regex-pcre input)
                    input))
           (base-args (seforim--rg-base-args))
           (pcre-args (when ignore-niqqud (list "--pcre2")))
           (all-results
            (seforim--collect-from-dirs
             dirs
             (lambda (dir)
               (seforim--run-command-lines
                "rga"
                (append base-args pcre-args
                        (list "-e" query "--" (expand-file-name dir))))))))
      (seforim--grep-search-complete all-results "rga"))))

;; ============================================================
;; Full-Text Search: recoll
;; ============================================================

(defun seforim-search-recoll ()
  "Full-text search using recoll in selected seforim directories."
  (interactive)
  (unless (executable-find "recoll")
    (user-error "recoll not found in PATH; please install recoll"))
  (let* ((dirs (seforim--select-dirs))
         (input (read-string "recoll query: ")))
    (when (string-empty-p (string-trim input))
      (user-error "Empty search query"))
    (let* ((dir-filter (mapconcat
                        (lambda (d)
                          (format "dir:%s" (expand-file-name d)))
                        dirs " OR "))
           (full-query (if (> (length dirs) 0)
                           (format "%s (%s)" input dir-filter)
                         input))
           (raw (seforim--run-command-lines "recoll"
                                            (list "-t" "-q" full-query)))
           (results nil))
      (dolist (line raw)
        (when-let ((file (seforim--parse-recoll-result line)))
          (push file results)))
      (seforim--filename-search-complete (nreverse (delete-dups results))
                                         "recoll"))))

(defun seforim--parse-recoll-result (line)
  "Extract file path from a recoll -t output LINE.
Handles `[file:///path]' URIs, bare `file://' URIs, and plain paths."
  (cond
   ;; [file:///path] format (common in recoll -t output)
   ((string-match "\\[file://\\([^]]+\\)\\]" line)
    (let ((path (match-string 1 line)))
      (when (file-exists-p path) path)))
   ;; file:///path without brackets
   ((string-match "file://\\(/[^ \t]+\\)" line)
    (let ((path (match-string 1 line)))
      (when (file-exists-p path) path)))
   ;; Plain absolute path (entire trimmed line)
   ((let ((trimmed (string-trim line)))
      (and (string-prefix-p "/" trimmed)
           (not (string-empty-p trimmed))
           (file-exists-p trimmed)
           trimmed)))
   (t nil)))

;; ============================================================
;; Live (Async) Search: fd via consult--find
;; ============================================================

(defun seforim-find-fd-live ()
  "Live (as-you-type) filename search using fd.
Uses `consult--find' for async completion.
Type after the # separator to start searching."
  (interactive)
  (unless (executable-find "fd")
    (user-error "fd not found in PATH"))
  (let* ((dirs (seforim--select-dirs))
         (dir-args (mapcan (lambda (d)
                             (list "--search-path" (expand-file-name d)))
                           dirs))
         (base-cmd (append (list "fd" "--type" "f" "--color" "never"
                                 "--ignore-case")
                           dir-args))
         (builder (lambda (input)
                    (let ((trimmed (string-trim input)))
                      (if (string-empty-p trimmed)
                          nil
                        (cons (append base-cmd (list trimmed)) 0)))))
         (selected (consult--find "fd live: " builder nil)))
    (when (and selected (not (string-empty-p (string-trim selected))))
      (let ((file (string-trim selected)))
        (when (file-exists-p file)
          (seforim--dispatch-file-action file))))))

;; ============================================================
;; Live (Async) Search: rg via consult-ripgrep
;; ============================================================

(defun seforim-search-rg-live ()
  "Live (as-you-type) full-text search using `consult-ripgrep'.
Uses the standard consult-ripgrep interface for reliable async behavior.
When multiple directories are selected, searches the common parent
directory (`seforim-directory') since consult-ripgrep accepts a single
directory.  For precise per-subdirectory scoping, use `seforim-search-rg'.
Niqqud-ignore is NOT applied in live mode; use `seforim-search-rg' for that.
Type after the # separator to start searching."
  (interactive)
  (unless (executable-find "rg")
    (user-error "rg not found in PATH"))
  (let* ((dirs (seforim--select-dirs))
         (search-dir (if (= (length dirs) 1)
                         (car dirs)
                       (expand-file-name seforim-directory))))
    (consult-ripgrep search-dir)))

;; ============================================================
;; In-Buffer Niqqud-Insensitive Isearch
;; ============================================================

(defvar-local seforim--isearch-active nil
  "Non-nil when seforim niqqud-insensitive isearch is active.")

(defun seforim--isearch-search-fun ()
  "Return a search function for niqqud-insensitive matching."
  (lambda (string &optional bound noerror count)
    (let ((regex (seforim--build-niqqud-regex-emacs string))
          (case-fold-search t))
      (if isearch-forward
          (re-search-forward regex bound noerror count)
        (re-search-backward regex bound noerror count)))))

(defun seforim--isearch-teardown ()
  "Clean up after niqqud-insensitive isearch."
  (when seforim--isearch-active
    (setq seforim--isearch-active nil)
    (kill-local-variable 'isearch-search-fun-function)
    (remove-hook 'isearch-mode-end-hook #'seforim--isearch-teardown t)))

(defun seforim-isearch-forward ()
  "Start a niqqud-insensitive isearch forward.
Temporarily sets `isearch-search-fun-function' buffer-locally
so that Hebrew niqqud marks are ignored during matching.
Use C-s/C-r within isearch to navigate matches as usual.
Does not replace ordinary isearch (only active when invoked explicitly)."
  (interactive)
  (setq seforim--isearch-active t)
  (setq-local isearch-search-fun-function #'seforim--isearch-search-fun)
  (add-hook 'isearch-mode-end-hook #'seforim--isearch-teardown nil t)
  (isearch-forward-regexp nil 1))

(defun seforim-isearch-backward ()
  "Start a niqqud-insensitive isearch backward."
  (interactive)
  (setq seforim--isearch-active t)
  (setq-local isearch-search-fun-function #'seforim--isearch-search-fun)
  (add-hook 'isearch-mode-end-hook #'seforim--isearch-teardown nil t)
  (isearch-backward-regexp nil 1))

;; ============================================================
;; Daf Navigation
;; ============================================================

(defconst seforim--heb-ones
  ["" "א" "ב" "ג" "ד" "ה" "ו" "ז" "ח" "ט"]
  "Hebrew letters for ones digits.")

(defconst seforim--heb-tens
  ["" "י" "כ" "ל" "מ" "נ" "ס" "ע" "פ" "צ"]
  "Hebrew letters for tens digits.")

(defconst seforim--heb-hundreds
  ["" "ק" "ר" "ש" "ת" "תק" "תר" "תש" "תת" "תתק"]
  "Hebrew letters for hundreds digits (1-9 hundreds).")

(defun seforim--num-to-heb (n)
  "Convert number N (1-999) to Hebrew numeral string."
  (cond
   ((or (not (integerp n)) (<= n 0) (> n 999))
    (user-error "Daf number %s out of range (1-999)" n))
   (t
    (let* ((hundreds (/ n 100))
           (remainder (% n 100))
           (tens (/ remainder 10))
           (ones (% remainder 10))
           (result ""))
      (when (> hundreds 0)
        (setq result (concat result (aref seforim--heb-hundreds hundreds))))
      (cond
       ((= remainder 15)
        (setq result (concat result "טו")))
       ((= remainder 16)
        (setq result (concat result "טז")))
       (t
        (when (> tens 0)
          (setq result (concat result (aref seforim--heb-tens tens))))
        (when (> ones 0)
          (setq result (concat result (aref seforim--heb-ones ones))))))
      result))))

(defun seforim-goto-daf ()
  "Prompt for daf number and amud, then navigate to it.
In `pdf-view-mode', go to the calculated page.
In text buffers, search for the Hebrew daf/amud pattern."
  (interactive)
  (let* ((daf (read-number "Daf number: "))
         (amud (completing-read "Amud (א/ב): " '("א" "ב") nil t))
         (amud-offset (if (string= amud "א") 0 1)))
    (cond
     ;; PDF mode
     ((and (derived-mode-p 'pdf-view-mode)
           (fboundp 'pdf-view-goto-page))
      (let ((page (+ (* (1- daf) 2) amud-offset 1)))
        (pdf-view-goto-page page)))
     ;; Text buffer
     (t
      (goto-char (point-min))
      (let* ((heb-num (seforim--num-to-heb daf))
             (amud-word (if (string= amud "א") "עמוד א" "עמוד ב"))
             (niqqud-opt (format "[%c-%c]*" seforim--niqqud-min seforim--niqqud-max))
             (daf-regex
              (concat
               ;; דף with optional niqqud
               "ד" niqqud-opt "ף" niqqud-opt
               ;; whitespace
               "[ \t]+"
               ;; Hebrew numeral with optional niqqud between letters
               (mapconcat (lambda (c)
                            (concat (regexp-quote (string c)) niqqud-opt))
                          (string-to-list heb-num)
                          "")
               ;; whitespace
               "[ \t]+"
               ;; amud word with optional niqqud between letters
               (mapconcat (lambda (c)
                            (if (= c ?\s) "[ \t]+"
                              (concat (regexp-quote (string c)) niqqud-opt)))
                          (string-to-list amud-word)
                          ""))))
        (if (re-search-forward daf-regex nil t)
            (progn
              (goto-char (match-beginning 0))
              (message "Found daf %d amud %s" daf amud))
          (message "Daf %d amud %s not found" daf amud)))))))

;; ============================================================
;; Study Log
;; ============================================================

(defun seforim-show-log ()
  "Show the study log and allow reopening a file from it.
Uses prefix arg dispatch for open action."
  (interactive)
  (seforim--load-log)
  (if (null seforim--log-list)
      (message "Study log is empty.")
    (let* ((candidates
            (mapcar (lambda (entry)
                      (let ((file (car entry))
                            (time (cdr entry)))
                        (cons (format "%s  [%s]"
                                      (seforim--short-path file)
                                      time)
                              file)))
                    seforim--log-list))
           (selected (completing-read "Study log: "
                                      (mapcar #'car candidates)
                                      nil t))
           (file (cdr (assoc selected candidates))))
      (when (and file (file-exists-p file))
        (seforim--dispatch-file-action file)))))

;; ============================================================
;; Embark Integration (optional, loaded only if embark is available)
;; ============================================================

(with-eval-after-load 'embark
  (defun seforim-embark-open-in-tab (file)
    "Open FILE in a new tab via embark."
    (interactive "fFile: ")
    (seforim--open-file-new-tab (expand-file-name file)))

  (defun seforim-embark-copy-name (file)
    "Copy the basename of FILE to the kill ring."
    (interactive "fFile: ")
    (let ((name (file-name-nondirectory file)))
      (kill-new name)
      (message "Copied: %s" name)))

  (defun seforim-embark-consult-line (file)
    "Open FILE and run `consult-line' inside it."
    (interactive "fFile: ")
    (find-file (expand-file-name file))
    (consult-line))

  ;; Extend the existing embark-file-map rather than replacing it
  (when (boundp 'embark-file-map)
    (define-key embark-file-map (kbd "T") #'seforim-embark-open-in-tab)
    (define-key embark-file-map (kbd "Y") #'seforim-embark-copy-name)
    (define-key embark-file-map (kbd "S") #'seforim-embark-consult-line)))

;; ============================================================
;; Seforim Minor Mode
;; ============================================================

(defvar seforim-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd seforim-inbuffer-niqqud-key) #'seforim-isearch-forward)
    (define-key map (kbd "C-c d") #'seforim-goto-daf)
    map)
  "Keymap for `seforim-mode'.
\\{seforim-mode-map}")

(define-minor-mode seforim-mode
  "Minor mode for files in the seforim library.
Provides niqqud-insensitive in-buffer search and daf navigation.
Activated automatically for files under `seforim-directory'.

Key bindings:
\\{seforim-mode-map}"
  :lighter " Sef"
  :keymap seforim-mode-map)

(defun seforim--maybe-enable-mode ()
  "Enable `seforim-mode' if the current file is under `seforim-directory'."
  (when (and buffer-file-name
             (file-directory-p seforim-directory)
             (string-prefix-p (expand-file-name seforim-directory)
                              (expand-file-name buffer-file-name)))
    (seforim-mode 1)))

(add-hook 'find-file-hook #'seforim--maybe-enable-mode)

;; ============================================================
;; Initialization (only when interactive Emacs, not batch)
;; ============================================================

(unless noninteractive
  (seforim--load-log))

  ;; ============================================================
;; Library Status
;; ============================================================

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

(provide '14-seforim)
;;; 14-seforim.el ends here
;; No heading:1 ends here

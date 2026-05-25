;; [[file:14b-seforim-candidates.org::+BEGIN_SRC emacs-lisp][No heading:1]]
;;; 14b-seforim-candidates.el --- Seforim: candidates, parsers, and stable async source  -*- lexical-binding: t; -*-

(require '14a-seforim-core)
(require 'consult)
(require 'cl-lib)
(require 'subr-x)

;; ---------------------------------------------------------------------------
;; Candidate Helpers
;; ---------------------------------------------------------------------------

(defun seforim--make-cand (path line snippet)
  "Create a propertized candidate string.
If LINE is nil or 0, treat as filename-only candidate (no line jump)."
  (let* ((short (seforim--format-path path))
         (cand  (if (and line (> line 0))
                    (format "%s : %d" short line)
                  short)))
    (add-text-properties
     0 (length cand)
     `(seforim-path ,path
       seforim-line ,(or line 0)
       seforim-snip ,snippet
       category file)
     cand)
    cand))

(defun seforim--annotate-file (_cand)
  "Annotation for filename-only candidates (no second line)."
  nil)

(defun seforim--annotate-text (cand)
  "Annotation for full-text candidates (second line with snippet)."
  (let ((snip (get-text-property 0 'seforim-snip cand)))
    (when snip
      (concat "\n  " snip))))

(defun seforim--jump-to-cand (cand _candidates)
  "Open file at line from candidate CAND (normal open)."
  (when cand
    (let ((p (get-text-property 0 'seforim-path cand))
          (l (get-text-property 0 'seforim-line cand)))
      (when p
        (seforim--open-file p l nil)))))

;; ---------------------------------------------------------------------------
;; File Opening
;; ---------------------------------------------------------------------------

(defvar seforim--new-tab-flag nil
  "Internal flag to signal open in new tab without using prefix arg.")

(defun seforim--open-file (file line &optional external)
  "Open FILE (optionally at LINE).
If EXTERNAL is non-nil, use system default application.
If `current-prefix-arg' is non-nil or called via new-tab action, open in new tab.
Otherwise open normally.  Logs the visit."
  (cond
   (external
    (let ((open-cmd (cond ((eq system-type 'gnu/linux) "xdg-open")
                          ((eq system-type 'darwin) "open")
                          ((eq system-type 'windows-nt) "start"))))
      (when open-cmd
        (start-process "" nil open-cmd file))))
   ((or current-prefix-arg (eq seforim--new-tab-flag t))
    (tab-bar-new-tab)
    (find-file file)
    (tab-bar-rename-tab (file-name-base file)))
   (t
    (find-file file)))
  (when (and (not external) (not (or current-prefix-arg (eq seforim--new-tab-flag t)))
             line (> line 0) (not (derived-mode-p 'pdf-view-mode)))
    (goto-char (point-min))
    (forward-line (1- line))
    (recenter))
  ;; Logging (only if file is under seforim-directory)
  (when (string-prefix-p (seforim--base-dir) (expand-file-name file))
    (let* ((name  (file-name-nondirectory file))
           (entry (cons name (current-time))))
      (setq seforim--log-list
            (cons entry
                  (cl-delete name seforim--log-list :test #'string= :key #'car)))
      (make-directory (file-name-directory seforim-study-log-path) t)
      ;; Prune log to 500 entries
      (setq seforim--log-list (cl-subseq seforim--log-list 0 (min 500 (length seforim--log-list))))
      (with-temp-file seforim-study-log-path
        (insert (prin1-to-string seforim--log-list))))))

(defun seforim--open-tab-action (cand)
  "Open candidate CAND in a new tab."
  (let ((p (get-text-property 0 'seforim-path cand))
        (l (get-text-property 0 'seforim-line cand)))
    (when p
      (let ((seforim--new-tab-flag t))
        (seforim--open-file p l nil)))))

(defun seforim--open-external-action (cand)
  "Open candidate CAND with external application."
  (let ((p (get-text-property 0 'seforim-path cand)))
    (when p
      (seforim--open-file p nil t))))

;; ---------------------------------------------------------------------------
;; Stable Async Source (uses public `consult--async` macro)
;; ---------------------------------------------------------------------------

(defun seforim--async-source (command-builder parser)
  "Return a consult async source using the stable `consult--async` macro.
COMMAND-BUILDER: input -> list of strings (command) or nil.
PARSER: stdout string -> list of candidates."
  (consult--async
   (lambda (input callback)
     (let ((cmd (funcall command-builder input)))
       (when cmd
         (consult--async-process cmd
           (lambda (proc-output)
             (funcall callback (funcall parser proc-output)))))))
   (lambda () (funcall command-builder ""))))

(defun seforim--consult-read (source prompt annotate-fn)
  "Run consult with SOURCE, PROMPT, ANNOTATE-FN and extra keymap."
  (let ((consult-async-refresh-delay seforim-consult-idle-delay))
    (consult--read source
                   :prompt prompt
                   :annotate annotate-fn
                   :lookup #'seforim--jump-to-cand
                   :require-match nil
                   :sort nil
                   :keymap seforim-consult-map)))

;; ---------------------------------------------------------------------------
;; Filters and Parsers
;; ---------------------------------------------------------------------------

(defun seforim--file-under-dir-p (file dir-truename)
  "Return non-nil if FILE is under directory DIR-TRUENAME (already resolved)."
  (let ((abs-file (ignore-errors (file-truename file))))
    (when abs-file
      (string-prefix-p dir-truename abs-file))))

(defun seforim--file-parser (out dirs)
  "Parse plain file list (one path per line) and filter to those under DIRS.
Assumes paths are relative to the first directory in DIRS."
  (let ((base-dir (car dirs))
        (base-truename (ignore-errors (file-truename (car dirs))))
        res)
    (dolist (raw (split-string out "\n" t))
      (let ((path (string-trim raw)))
        (when (and (not (string-empty-p path))
                   (file-readable-p (expand-file-name path base-dir)))
          (let ((abs-path (expand-file-name path base-dir)))
            (push (seforim--make-cand abs-path nil nil) res)))))
    (nreverse res)))

(defun seforim--grep-parser (out)
  "Parse rg/rga --column output lines: FILE:LINE:COL:TEXT."
  (let (res)
    (dolist (raw (split-string out "\n" t))
      (when (string-match "^\\(.+?\\):\\([0-9]+\\):[0-9]+:\\(.*\\)$" raw)
        (push (seforim--make-cand
               (match-string 1 raw)
               (string-to-number (match-string 2 raw))
               (string-trim (match-string 3 raw)))
              res)))
    (nreverse res)))

(defun seforim--recoll-parser (out)
  "Parse recoll -t output: FILE<TAB>LINE<TAB>SNIPPET."
  (let (res)
    (dolist (line (split-string out "\n" t))
      (let ((parts (split-string line "\t")))
        (when (>= (length parts) 3)
          (push (seforim--make-cand
                 (nth 0 parts)
                 (string-to-number (nth 1 parts))
                 (nth 2 parts))
                res))))
    (nreverse res)))

(defun seforim--fuzzy-pattern (input)
  "Convert INPUT into a fuzzy regex: .*?c1.*?c2.*? ..."
  (when (and input (not (string-empty-p (string-trim input))))
    (concat ".*?" (mapconcat #'regexp-quote (split-string (string-trim input) "" t) ".*?"))))

;; ---------------------------------------------------------------------------
;; Plocate database check
;; ---------------------------------------------------------------------------

(defvar seforim--plocate-warned nil
  "Whether we have already warned about plocate database in this session.")

(defun seforim--check-plocate-database ()
  "Check if plocate is usable. Warn once per session if database appears empty."
  (when (executable-find "plocate")
    (let ((buf (generate-new-buffer " *seforim-plocate-check*")))
      (make-process
       :name "seforim-plocate-check"
       :buffer buf
       :command (list "plocate" "--limit" "1" "/")
       :sentinel
       (lambda (_proc event)
         (when (string-match-p "finished" event)
           (with-current-buffer buf
             (let ((out (buffer-string)))
               (ignore-errors (kill-buffer buf))
               (if (string-empty-p (string-trim out))
                   (unless seforim--plocate-warned
                     (setq seforim--plocate-warned t)
                     (message "Warning: plocate database appears empty. Run 'sudo updatedb'."))
                 (setq seforim--plocate-warned nil))))))))))

;; ---------------------------------------------------------------------------
;; Consult Keymap
;; ---------------------------------------------------------------------------

(defun seforim--get-current-candidate ()
  "Return the currently selected candidate in the consult minibuffer."
  (when (boundp 'consult--candidates)
    (let ((candidates consult--candidates)
          (index consult--index))
      (when (and (listp candidates) (numberp index) (>= index 0) (< index (length candidates)))
        (nth index candidates)))))

(defvar seforim-consult-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-RET")
      (lambda () (interactive)
        (let ((cand (seforim--get-current-candidate)))
          (when cand (seforim--open-tab-action cand)))))
    (define-key map (kbd "C-o")
      (lambda () (interactive)
        (let ((cand (seforim--get-current-candidate)))
          (when cand (seforim--open-external-action cand)))))
    map)
  "Keymap for consult buffers to provide extra opening actions.")

;; ---------------------------------------------------------------------------
;; Provide
;; ---------------------------------------------------------------------------

(provide '14b-seforim-candidates)
;;; 14b-seforim-candidates.el ends here
;; No heading:1 ends here

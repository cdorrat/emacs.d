;;; claude-org.el --- Manage Claude instances from org-mode documents -*- lexical-binding: t; -*-

(require 'org)
(require 'cl-lib)
(require 'claude-code)

(defvar claude-org-worktree-dir "../worktrees"
  "Directory where git worktrees are created, relative to the project root.")

;;; Internal helpers

(defun claude-org--sanitize-filename (str)
  "Convert STR into a valid filename component.
Replace non-alphanumeric characters with hyphens and collapse runs.
Returns nil if STR is nil."
  (when str
    (downcase
     (replace-regexp-in-string
      "-+" "-"
      (replace-regexp-in-string
       "[^a-zA-Z0-9]+" "-"
       (string-trim str))))))

(defun claude-org--goto-top-level-heading ()
  "Move point to the top-level heading for the current position.
Return t if a heading was found, nil otherwise."
  (when (ignore-errors (org-back-to-heading t))
    (while (> (org-current-level) 1)
      (org-up-heading-safe))
    t))

(defun claude-org--get-working-dir-property ()
  "Return the :WORKING_DIRECTORY: property from the top-level heading.
Signals a `user-error' if the property is not set."
  (save-excursion
    (claude-org--goto-top-level-heading)
    (or (org-entry-get nil "WORKING_DIRECTORY")
        (user-error "No :WORKING_DIRECTORY: property set on heading \"%s\""
                    (org-get-heading t t t t)))))

(defun claude-org--has-level-2-heading-p ()
  "Return non-nil if there is a level-2 heading between point and the top-level heading."
  (save-excursion
    (org-back-to-heading t)
    (let ((found nil))
      (while (and (not found) (> (org-current-level) 1))
        (when (= (org-current-level) 2)
          (setq found t))
        (unless found
          (org-up-heading-safe)))
      found)))

(defun claude-org--should-use-worktree ()
  "Return non-nil when the top-level heading has :USE_WORKTREE: set to \"true\"
and point is at or under a level-2 heading."
  (save-excursion
    (and (claude-org--has-level-2-heading-p)
         (claude-org--goto-top-level-heading)
         (string= "true" (org-entry-get nil "USE_WORKTREE")))))

(defun claude-org--heading-has-sub-headings-p ()
  "Return t if the current heading has sub-headings."
  (save-excursion
    (org-back-to-heading t)
    (let ((level (org-current-level)))
      (org-end-of-subtree t t)
      (re-search-backward (format "^\\*\\{%d,\\} " (1+ level))
                          (save-excursion (org-back-to-heading t) (point))
                          t))))

(defun claude-org--heading-body ()
  "Return the body text of the current heading (excluding sub-headings and properties)."
  (save-excursion
    (org-back-to-heading t)
    (let ((start (save-excursion
                   (org-end-of-meta-data t)
                   (point)))
          (end (save-excursion
                 (outline-next-heading)
                 (point))))
      (string-trim (buffer-substring-no-properties start end)))))

(defun claude-org--claude-buffer (name dir)
  "Return the claude-code buffer for instance NAME in DIR, or nil.
Finds the buffer by matching against claude-code's directory comparison logic."
  (when (and dir name)
    (let ((target-dir (file-truename (abbreviate-file-name dir))))
      (cl-find-if
       (lambda (buf)
         (and (string-match "^\\*claude:\\([^:]+\\):\\([^*]+\\)\\*$" (buffer-name buf))
              (string= (match-string 2 (buffer-name buf)) name)
              (string= (file-truename (match-string 1 (buffer-name buf))) target-dir)))
       (buffer-list)))))

;;; Public API

(defun claude-org-get-session-name ()
  "Return the session name for the current position.
Signals a `user-error' if point is not under a top-level heading."
  (save-excursion
    (if (claude-org--should-use-worktree)
	(claude-org-worktree-name-at-point)
      (unless (claude-org--goto-top-level-heading)
	(user-error "Point must be under a top-level heading with a :WORKING_DIRECTORY: property"))
      (claude-org--sanitize-filename
       (substring-no-properties
	(org-get-heading t t t t))))))

(defun claude-org-get-working-dir ()
  "Return the working directory for the current org heading.
If `claude-org--should-use-worktree' is true, return the worktree directory.
Otherwise return the :WORKING_DIRECTORY: property from the top-level heading."
  (if (claude-org--should-use-worktree)
      (claude-org-worktree-dir-name)
    (claude-org--get-working-dir-property)))

(defun claude-org-worktree-name-at-point ()
  "Return a unique worktree name based on the level-1 and level-2 org headings at point.
The level-2 heading is the one containing point (not the first child).
The name is derived by sanitizing and joining the headings with \"--\"."
  (save-excursion
    (org-back-to-heading t)
    (let ((h2 (when (>= (org-current-level) 2)
                (while (> (org-current-level) 2)
                  (org-up-heading-safe))
                (org-get-heading t t t t))))
      (claude-org--goto-top-level-heading)
      (let ((h1 (org-get-heading t t t t)))
        (if h2
            (concat (claude-org--sanitize-filename h1)
                    "--"
                    (claude-org--sanitize-filename h2))
          (claude-org--sanitize-filename h1))))))

(defun claude-org-worktree-dir-name ()
  "Return the fully qualified worktree directory path.
If `claude-org-worktree-dir' is relative, resolve it against the working directory.
Otherwise use it directly.  The worktree name from `claude-org-worktree-name-at-point'
is appended as the final path component."
  (let ((wt-name (claude-org-worktree-name-at-point))
        (base (if (file-name-absolute-p claude-org-worktree-dir)
                  claude-org-worktree-dir
                (expand-file-name claude-org-worktree-dir
                                  (claude-org--get-working-dir-property)))))
    (expand-file-name wt-name base)))

(defun claude-org-maybe-create-worktree ()
  "Create a git worktree for the current org heading if one does not exist.
Uses the :WORKING_DIRECTORY: as the source repo and creates the worktree
at the path returned by `claude-org-worktree-dir-name' with a new branch
named after `claude-org-worktree-name-at-point'."
  (let ((wt-dir (claude-org-worktree-dir-name)))
    (unless (file-directory-p wt-dir)
      (let ((parent (file-name-directory (directory-file-name wt-dir)))
            (branch (claude-org-worktree-name-at-point))
            (repo (claude-org--get-working-dir-property)))
        (make-directory parent t)
        (let ((default-directory repo)
              (err-buf (generate-new-buffer " *claude-org-git-worktree*")))
          (unwind-protect
              (progn
                (message "claude-org: running `git -C %s worktree add -b %s %s'" repo branch wt-dir)
                (unless (zerop (call-process "git" nil err-buf nil
                                             "worktree" "add" "-b" branch wt-dir))
                  ;; Branch already exists from a previous session; reuse it
                  (with-current-buffer err-buf (erase-buffer))
                  (message "claude-org: branch exists, running `git -C %s worktree add %s %s'" repo wt-dir branch)
                  (unless (zerop (call-process "git" nil err-buf nil
                                               "worktree" "add" wt-dir branch))
                    (error "Failed to create git worktree at %s: %s"
                           wt-dir (string-trim (with-current-buffer err-buf (buffer-string)))))))
            (kill-buffer err-buf)))))))

(defun claude-org-get-current-prompt ()
  "Return contextual text from the current position in an org-mode buffer.
- At a list item: return the item text.
- At a heading with no sub-headings: return the heading body.
- Under a parent heading: return the parent heading body.
- At plain text: return the current paragraph.
- Otherwise: nil."
  (cond
   ;; List item
   ((org-at-item-p)
    (string-trim
     (save-excursion
       (beginning-of-line)
       (looking-at "[ \t]*[-+*]\\|[ \t]*[0-9]+[.)]: *")
       (buffer-substring-no-properties (match-end 0) (line-end-position)))))
   ;; At a heading with no sub-headings
   ((and (org-at-heading-p)
         (not (claude-org--heading-has-sub-headings-p)))
    (claude-org--heading-body))
   ;; Under a parent heading
   ((save-excursion (ignore-errors (org-back-to-heading t)))
    (save-excursion
      (org-back-to-heading t)
      (claude-org--heading-body)))
   ;; Plain text paragraph
   ((not (org-at-heading-p))
    (string-trim
     (save-excursion
       (let ((start (progn (backward-paragraph) (point)))
             (end (progn (forward-paragraph) (point))))
         (buffer-substring-no-properties start end)))))
   (t nil)))

(defun claude-org-get-or-create-claude-buffer (name dir)
  "Return the claude-code buffer for instance NAME in DIR, creating it if needed."
  (let ((dir (file-name-as-directory (expand-file-name dir))))
    (or (claude-org--claude-buffer name dir)
        (progn
          (when (claude-org--should-use-worktree)
            (claude-org-maybe-create-worktree))
          ;; Override claude-code--directory to return our working dir (instead of
          ;; the org file's project root) and the instance name prompt to return
          ;; our heading name automatically.
          (let ((default-directory dir))
            (cl-letf (((symbol-function 'claude-code--prompt-for-instance-name)
                       (lambda (_dir _existing &optional _force) name))
                      ((symbol-function 'claude-code--directory)
                       (lambda () dir)))
              (claude-code--start nil nil t)))
          (or (claude-org--claude-buffer name dir)
              (user-error "Failed to create claude-code instance"))))))

(defun claude-org-get-claude-buffer ()
  "Return the claude-code buffer for the current org heading, creating it if needed.
The working directory and session name are derived from the top-level heading properties."
  (let ((dir (claude-org-get-working-dir))
        (name (claude-org-get-session-name)))
    (claude-org-get-or-create-claude-buffer name dir)))

;;; Interactive commands

(defun claude-org-send-to-claude (&optional arg)
  "Send the current prompt to the associated claude-code instance.
The prompt text comes from `claude-org-get-current-prompt'.

With prefix ARG, switch to the Claude buffer after sending."
  (interactive "P")
  (let ((prompt (claude-org-get-current-prompt)))
    (unless prompt
      (user-error "No prompt text found at point"))
    (let ((buf (claude-org-get-claude-buffer)))
      ;; Override claude-code--get-or-prompt-for-buffer so that any code
      ;; triggered during the send (e.g. display hooks, terminal init)
      ;; finds our buffer directly instead of searching by the org file's
      ;; directory and prompting.
      (cl-letf (((symbol-function 'claude-code--get-or-prompt-for-buffer)
                 (lambda () buf)))
        (with-current-buffer buf
	  (claude-code--do-send-command prompt))
        (if arg
            (pop-to-buffer buf)
          (display-buffer buf))))))

(defun claude-org-magit-status ()
  "Open magit-status for the current org heading context.
When worktrees are enabled, use the worktree directory.
When a :WORKING_DIRECTORY: property exists, use that.
Otherwise call magit-status with no directory argument."
  (interactive)
  (cond
   ((claude-org--should-use-worktree)
    (claude-org-maybe-create-worktree)
    (magit-status (claude-org-worktree-dir-name)))
   ((ignore-errors (claude-org--get-working-dir-property))
    (magit-status (claude-org--get-working-dir-property)))
   (t
    (magit-status))))


;; ---------------------------------------------------------------------------------------------------
;; support for showing claude actions in a buffer

;; use this one for debugging
(defun my-claude-session-listener (message)
  "Log all Claude hook events to a file.
MESSAGE is a plist with :type, :buffer-name, :json-data, and :args keys."
  (let ((hook-type (plist-get message :type))
        (buffer-name (plist-get message :buffer-name))
        (json-data (plist-get message :json-data))
        (timestamp (format-time-string "%Y-%m-%d %H:%M:%S")))
    (with-temp-buffer
      (insert (format "[%s] %s: %s (JSON: %s)\n" timestamp hook-type buffer-name json-data))
      (append-to-file (point-min) (point-max) "~/claude-hooks.log"))))

(defun claude-org--setup-claude-hooks ()
  "Set up advanced Claude hook handling with multiple listeners."
  (interactive)
  ;; Add multiple listeners
  (add-hook 'claude-code-event-hook 'my-claude-session-listener)
  (message "Advanced Claude hooks configured"))

(claude-org--setup-claude-hooks)

(provide 'claude-org)
;;; claude-org.el ends here

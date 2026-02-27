
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))

;; install required inheritenv dependency:
(use-package inheritenv
  :vc (:url "https://github.com/purcell/inheritenv" :rev :newest))

(use-package monet
  :vc (:url "https://github.com/stevemolitor/monet" :rev :newest))

;; for eat terminal backend:
(use-package eat :ensure t)

;; for vterm terminal backend:
(use-package vterm :ensure t)

;; install claude-code.el
(use-package claude-code :ensure t
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :config
  ;; optional IDE integration with Monet
;;  (add-hook 'claude-code-process-environment-functions #'monet-start-server-function)
;;  (monet-mode 1)

  (claude-code-mode)
  :bind-keymap ("C-c c" . claude-code-command-map)

  ;; Optionally define a repeat map so that "M" will cycle thru Claude auto-accept/plan/confirm modes after invoking claude-code-cycle-mode / C-c M.
  :bind
  (:repeat-map my-claude-code-map ("M" . claude-code-cycle-mode)))

(defun my-claude-notify (title message)
  "Display a macOS notification with sound."
  (let ((escaped-title (replace-regexp-in-string "[\"\\\\]" "\\\\\\&" title))
        (escaped-message (replace-regexp-in-string "[\"\\\\]" "\\\\\\&" message)))
    (call-process "osascript" nil nil nil
                  "-e" (format "display notification \"%s\" with title \"%s\" sound name \"Glass\""
                               escaped-message escaped-title))))

(setq claude-code-notification-function #'my-claude-notify)


(load-file "/Users/cdorrat/.emacs.d/elpa/claude-code/examples/hooks/claude-code-auto-revert-hook.el")

(setup-claude-auto-revert)

(add-hook 'claude-code-process-environment-functions #'monet-start-server-function)
(monet-mode 1)

(defvar my/clorg-worktree-dir "../worktrees"
  "Directory where git worktrees are created, relative to the project root.")

;; some tooling for working with multiple claude instances from an org document


(defun my/clorg--sanitize-filename (str)
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

(defun my/clorg--goto-top-level-heading ()
  "Move point to the top-level heading for the current position.
Return t if a heading was found, nil otherwise."
  (when (ignore-errors (org-back-to-heading t))
    (while (> (org-current-level) 1)
      (org-up-heading-safe))
    t))

(defun my/clorg-get-session-name ()
  "Return the session name for the current position.
Signals a `user-error' if point is not under a top-level heading."
  (save-excursion
    (if (my/clorg--should-use-worktree)
	(my/clorg-worktree-name-at-point)
      (unless (my/clorg--goto-top-level-heading)
	(user-error "Point must be under a top-level heading with a :WORKING_DIRECTORY: property"))
      (my/clorg--sanitize-filename
       (substring-no-properties
	(org-get-heading t t t t))))))

(defun my/clorg--get-working-dir-property ()
  "Return the :WORKING_DIRECTORY: property from the top-level heading.
Signals a `user-error' if the property is not set."
  (save-excursion
    (my/clorg--goto-top-level-heading)
    (or (org-entry-get nil "WORKING_DIRECTORY")
        (user-error "No :WORKING_DIRECTORY: property set on heading \"%s\""
                    (org-get-heading t t t t)))))

(defun my/clorg-get-working-dir ()
  "Return the working directory for the current org heading.
If `my/clorg--should-use-worktree' is true, return the worktree directory.
Otherwise return the :WORKING_DIRECTORY: property from the top-level heading."
  (if (my/clorg--should-use-worktree)
      (my/clorg-worktree-dir-name)
    (my/clorg--get-working-dir-property)))

(defun my/clorg-open-magit ()
  "Open magit-status in the directory returned by `my/clorg-get-working-dir'."
  (interactive)
  (magit-status (my/clorg-get-working-dir)))

(defun my/clorg--has-level-2-heading-p ()
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

(defun my/clorg--should-use-worktree ()
  "Return non-nil when the top-level heading has :USE_WORKTREE: set to \"true\"
and point is at or under a level-2 heading."
  (save-excursion
    (and (my/clorg--has-level-2-heading-p)
         (my/clorg--goto-top-level-heading)
         (string= "true" (org-entry-get nil "USE_WORKTREE")))))


(defun my/clorg-worktree-name-at-point ()
  "Return a unique worktree name based on the level-1 and level-2 org headings at point.
The level-2 heading is the one containing point (not the first child).
The name is derived by sanitizing and joining the headings with \"--\"."
  (save-excursion
    (org-back-to-heading t)
    (let ((h2 (when (>= (org-current-level) 2)
                (while (> (org-current-level) 2)
                  (org-up-heading-safe))
                (org-get-heading t t t t))))
      (my/clorg--goto-top-level-heading)
      (let ((h1 (org-get-heading t t t t)))
        (if h2
            (concat (my/clorg--sanitize-filename h1)
                    "--"
                    (my/clorg--sanitize-filename h2))
          (my/clorg--sanitize-filename h1))))))

(defun my/clorg-worktree-dir-name ()
  "Return the fully qualified worktree directory path.
If `my/clorg-worktree-dir' is relative, resolve it against the working directory.
Otherwise use it directly.  The worktree name from `my/clorg-worktree-name-at-point'
is appended as the final path component."
  (let ((wt-name (my/clorg-worktree-name-at-point))
        (base (if (file-name-absolute-p my/clorg-worktree-dir)
                  my/clorg-worktree-dir
                (expand-file-name my/clorg-worktree-dir
                                  (my/clorg--get-working-dir-property)))))
    (expand-file-name wt-name base)))

(defun my/clorg-maybe-create-worktree ()
  "Create a git worktree for the current org heading if one does not exist.
Uses the :WORKING_DIRECTORY: as the source repo and creates the worktree
at the path returned by `my/clorg-worktree-dir-name' with a new branch
named after `my/clorg-worktree-name-at-point'."
  (let ((wt-dir (my/clorg-worktree-dir-name)))
    (unless (file-directory-p wt-dir)
      (let ((parent (file-name-directory (directory-file-name wt-dir)))
            (branch (my/clorg-worktree-name-at-point))
            (repo (my/clorg--get-working-dir-property)))
        (make-directory parent t)
        (let ((default-directory repo)
              (err-buf (generate-new-buffer " *clorg-git-worktree*")))
          (message "clorg: running `git -C %s worktree add -b %s %s'" repo branch wt-dir)
          (unwind-protect
              (unless (zerop (call-process "git" nil err-buf nil
                                           "worktree" "add" "-b" branch wt-dir))
                (error "Failed to create git worktree at %s: %s"
                       wt-dir (string-trim (with-current-buffer err-buf (buffer-string)))))
            (kill-buffer err-buf)))))))

(defun my/clorg--heading-has-sub-headings-p ()
  "Return t if the current heading has sub-headings."
  (save-excursion
    (org-back-to-heading t)
    (let ((level (org-current-level)))
      (org-end-of-subtree t t)
      (re-search-backward (format "^\\*\\{%d,\\} " (1+ level))
                          (save-excursion (org-back-to-heading t) (point))
                          t))))

(defun my/clorg--heading-body ()
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

(defun my/clorg-get-current-prompt ()
  "Return contextual text from the current position in an org-mode buffer.
- At a list item: return the item text.
- At a heading with no sub-headings: return the heading body.
- Under a parent heading: return the parent heading body.
- At plain text: return the current paragraph.
- Otherwise: nil."
  (cond
   ;; List item
   ((org-in-item-p)
    (string-trim
     (save-excursion
       (beginning-of-line)
       (looking-at "[ \t]*[-+*]\\|[ \t]*[0-9]+[.)]: *")
       (buffer-substring-no-properties (match-end 0) (line-end-position)))))
   ;; At a heading with no sub-headings
   ((and (org-at-heading-p)
         (not (my/clorg--heading-has-sub-headings-p)))
    (my/clorg--heading-body))
   ;; Under a parent heading
   ((save-excursion (ignore-errors (org-back-to-heading t)))
    (save-excursion
      (org-back-to-heading t)
      (my/clorg--heading-body)))
   ;; Plain text paragraph
   ((not (org-at-heading-p))
    (string-trim
     (save-excursion
       (let ((start (progn (backward-paragraph) (point)))
             (end (progn (forward-paragraph) (point))))
         (buffer-substring-no-properties start end)))))
   (t nil)))

(defun my/clorg--claude-buffer (name dir)
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

(defun my/clorg-get-or-create-claude-buffer (name dir)
  "Return the claude-code buffer for instance NAME in DIR, creating it if needed."
  (let ((dir (file-name-as-directory (expand-file-name dir))))
    (or (my/clorg--claude-buffer name dir)
        (progn
          (when (my/clorg--should-use-worktree)
            (my/clorg-maybe-create-worktree))
          ;; Override claude-code--directory to return our working dir (instead of
          ;; the org file's project root) and the instance name prompt to return
          ;; our heading name automatically.
          (let ((default-directory dir))
            (cl-letf (((symbol-function 'claude-code--prompt-for-instance-name)
                       (lambda (_dir _existing &optional _force) name))
                      ((symbol-function 'claude-code--directory)
                       (lambda () dir)))
              (claude-code--start nil nil t)))
          (or (my/clorg--claude-buffer name dir)
              (user-error "Failed to create claude-code instance"))))))

(defun my/clorg-get-claude-buffer ()
  "Return the claude-code buffer for the current org heading, creating it if needed.
The working directory and session name are derived from the top-level heading properties."
  (let ((dir (my/clorg-get-working-dir))
        (name (my/clorg-get-session-name)))
    (my/clorg-get-or-create-claude-buffer name dir)))

(defun my/clorg-doc-send-to-claude (&optional arg)
  "Send the current prompt to the associated claude-code instance.
The prompt text comes from `my/clorg-get-current-prompt'.

With prefix ARG, switch to the Claude buffer after sending."
  (interactive "P")
  (let ((prompt (my/clorg-get-current-prompt)))
    (unless prompt
      (user-error "No prompt text found at point"))
    (let ((buf (my/clorg-get-claude-buffer)))
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

(use-package pretty-hydra :ensure t)

(pretty-hydra-define my/claude-hydra
  (:title "Claude" :quit-key "q" :color blue)
  ("Instance"
   (("c" claude-code "start/open")
    ("n" claude-code-new-instance "new instance")
    ("d" claude-code-start-in-directory "start in dir")
    ("r" claude-code-resume "resume")
    ("C" claude-code-continue "continue")
    ("s" claude-code-select-buffer "select buffer")
    ("t" claude-code-toggle "toggle"))
   "Send"
   (("p" my/clorg-doc-send-to-claude "send prompt")
    ("e" claude-code-send-command "send command")
    ("w" claude-code-send-command-with-context "send with context")
    ("R" claude-code-send-region "send region")
    ("f" claude-code-send-buffer-file "send file"))
   "Control"
   (("m" claude-code-cycle-mode "cycle mode")
    ("F" claude-code-fork "fork")
    ("o" claude-code-toggle-read-only-mode "read-only")
    ("x" claude-code-send-escape "escape")
    ("/" claude-code-slash-commands "slash commands"))
   "Manage"
   (("k" claude-code-kill "kill instance")
    ("K" claude-code-kill-all "kill all"))
   "Org"
   (("/" my/clorg-doc-send-to-claude "send at point")
    ("." my/clorg-open-magit "magit at point")
    )
   ))

(define-key org-mode-map (kbd "C-/") #'my/clorg-doc-send-to-claude)
(define-key org-mode-map (kbd "C-.") #'my/clorg-open-magit)

(provide 'my-claude)

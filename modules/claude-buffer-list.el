;;; claude-buffer-list.el --- List and manage Claude sessions -*- lexical-binding: t; -*-

;;; Commentary:
;; Provides a dedicated buffer listing all Claude sessions with live status
;; updates, helm-based filtering, and one-keypress navigation.

;;; Code:

(require 'claude-code)

;;; --- Data layer ---

(defvar claude-buffer-list--sessions (make-hash-table :test 'equal)
  "Hash table keyed by buffer-name. Value is a plist:
(:buffer-name :status :directory :instance :last-update)")

(defun claude-buffer-list--parse-buffer-name (buf-name)
  "Extract directory and instance from BUF-NAME.
Returns (DIR . INSTANCE) or nil."
  (when (string-match "^\\*claude:\\([^:]+\\)\\(?::\\([^*]+\\)\\)?\\*$" buf-name)
    (cons (match-string 1 buf-name)
          (match-string 2 buf-name))))

(defun claude-buffer-list--register (buf-name)
  "Register buffer BUF-NAME in the session table as idle."
  (when (and buf-name (claude-code--buffer-p buf-name))
    (let ((parsed (claude-buffer-list--parse-buffer-name buf-name)))
      (when parsed
        (puthash buf-name
                 (list :buffer-name buf-name
                       :status 'idle
                       :directory (car parsed)
                       :instance (or (cdr parsed) "default")
                       :last-update (current-time))
                 claude-buffer-list--sessions)
        (claude-buffer-list--maybe-refresh)))))

(defun claude-buffer-list--update-status (buf-name status)
  "Update STATUS for BUF-NAME in the session table."
  (let ((entry (gethash buf-name claude-buffer-list--sessions)))
    (when entry
      (plist-put entry :status status)
      (plist-put entry :last-update (current-time))
      (claude-buffer-list--maybe-refresh))))

(defun claude-buffer-list--remove (buf-name)
  "Remove BUF-NAME from the session table."
  (remhash buf-name claude-buffer-list--sessions)
  (claude-buffer-list--maybe-refresh))

(defun claude-buffer-list--event-listener (event)
  "Handle claude-code EVENT and update session status.
Added to `claude-code-event-hook'."
  (let ((type (plist-get event :type))
        (buf-name (plist-get event :buffer-name))
        (json-data (plist-get event :json-data)))
    (message "==> buf-list event %s : %s" type buf-name)
    ;; Ensure the buffer is registered
    (unless (gethash buf-name claude-buffer-list--sessions)
      (claude-buffer-list--register buf-name))
    (pcase type
      ((or 'promptsubmit 'posttooluse 'posttoolfail)
       (claude-buffer-list--update-status buf-name 'running))
      ('notification
       (let* ((parsed (and json-data
                           (condition-case nil
                               (json-read-from-string json-data)
                             (error nil))))
              (notif-type (and parsed (alist-get 'notification_type parsed))))
         (if (equal notif-type "permission_prompt")
             (claude-buffer-list--update-status buf-name 'waiting-for-permission)
           ;; Generic notification — treat as idle (Claude is waiting for input)
           (claude-buffer-list--update-status buf-name 'idle))))
      ('permission
       (claude-buffer-list--update-status buf-name 'waiting-for-permission))
      ('stop
       (claude-buffer-list--update-status buf-name 'idle))))
  nil)

(defun claude-buffer-list--on-start ()
  "Hook for `claude-code-start-hook'. Register the new session."
  (claude-buffer-list--register (buffer-name)))

(defun claude-buffer-list--on-kill ()
  "Hook for `kill-buffer-hook'. Remove killed claude buffers from session table."
  (when (claude-code--buffer-p (current-buffer))
    (claude-buffer-list--remove (buffer-name))))

(defun claude-buffer-list--bootstrap ()
  "Scan for existing claude buffers and register them."
  (dolist (buf (buffer-list))
    (when (claude-code--buffer-p buf)
      (claude-buffer-list--register (buffer-name buf)))))

;;; --- UI layer ---

(defvar claude-buffer-list--refresh-timer nil
  "Timer for auto-refreshing the session list buffer.")

(defface claude-buffer-list-idle
  '((t :foreground "green"))
  "Face for idle status.")

(defface claude-buffer-list-running
  '((t :foreground "yellow"))
  "Face for running status.")

(defface claude-buffer-list-waiting
  '((t :foreground "red"))
  "Face for waiting-for-permission status.")

(defface claude-buffer-list-header
  '((t :inherit font-lock-keyword-face :bold t))
  "Face for the header line.")

(defun claude-buffer-list--status-string (status)
  "Return a formatted string for STATUS with appropriate face."
  (let ((str (pcase status
               ('idle "idle")
               ('running "running")
               ('waiting-for-permission "waiting")
               (_ "unknown"))))
    (propertize (format "%-10s" str)
                'face (pcase status
                        ('idle 'claude-buffer-list-idle)
                        ('running 'claude-buffer-list-running)
                        ('waiting-for-permission 'claude-buffer-list-waiting)
                        (_ 'default)))))

(defun claude-buffer-list--time-ago (time)
  "Return a human-readable string for how long ago TIME was."
  (if time
      (let ((seconds (float-time (time-subtract (current-time) time))))
        (cond
         ((< seconds 60) (format "%ds ago" (truncate seconds)))
         ((< seconds 3600) (format "%dm ago" (truncate (/ seconds 60))))
         (t (format "%dh ago" (truncate (/ seconds 3600))))))
    ""))

(defun claude-buffer-list-refresh ()
  "Redraw the *Claude Sessions* buffer from the session hash table."
  (interactive)
  (let ((buf (get-buffer "*Claude Sessions*")))
    (when buf
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (line (line-number-at-pos))
              (entries '()))
          ;; Collect and sort entries
          (maphash (lambda (_key val) (push val entries))
                   claude-buffer-list--sessions)
          (setq entries (sort entries
                              (lambda (a b)
                                (string< (plist-get a :buffer-name)
                                         (plist-get b :buffer-name)))))
          (erase-buffer)
          ;; Header
          (insert (propertize (format "%-10s  %-15s  %-40s  %s\n"
                                      "STATUS" "INSTANCE" "DIRECTORY" "UPDATED")
                              'face 'claude-buffer-list-header))
          (insert (make-string 80 ?-) "\n")
          ;; Rows
          (if (null entries)
              (insert "\n  No active Claude sessions.\n")
            (dolist (entry entries)
              (let ((start (point)))
                (insert (claude-buffer-list--status-string (plist-get entry :status))
                        "  "
                        (format "%-15s" (plist-get entry :instance))
                        "  "
                        (format "%-40s" (truncate-string-to-width
                                         (plist-get entry :directory) 40 nil nil t))
                        "  "
                        (claude-buffer-list--time-ago (plist-get entry :last-update))
                        "\n")
                (put-text-property start (point) 'claude-buffer-name
                                   (plist-get entry :buffer-name)))))
          ;; Restore cursor position
          (goto-char (point-min))
          (forward-line (1- (min line (count-lines (point-min) (point-max))))))))))

(defun claude-buffer-list--maybe-refresh ()
  "Refresh the session list buffer if it exists and is visible."
  (when (get-buffer "*Claude Sessions*")
    (claude-buffer-list-refresh)))

(defun claude-buffer-list--buffer-name-at-point ()
  "Return the claude buffer name on the current line, or nil."
  (get-text-property (line-beginning-position) 'claude-buffer-name))

(defun claude-buffer-list-goto-session ()
  "Switch to the claude session on the current line.
If the session buffer is already visible, select its window.
Otherwise, open it in another window so the sessions list stays visible."
  (interactive)
  (let ((buf-name (claude-buffer-list--buffer-name-at-point)))
    (if (and buf-name (get-buffer buf-name))
        (let ((win (get-buffer-window buf-name)))
          (if win
              (select-window win)
            (switch-to-buffer-other-window buf-name)))
      (message "No session on this line"))))

(defun claude-buffer-list-kill-session ()
  "Kill the claude session on the current line."
  (interactive)
  (let ((buf-name (claude-buffer-list--buffer-name-at-point)))
    (if (and buf-name (get-buffer buf-name))
        (when (yes-or-no-p (format "Kill session %s? " buf-name))
          (kill-buffer buf-name)
          (claude-buffer-list-refresh))
      (message "No session on this line"))))

(defun claude-buffer-list-helm ()
  "Open helm to filter and select a Claude session."
  (interactive)
  (if (not (fboundp 'helm))
      (message "Helm is not available")
    (let ((candidates '()))
      (maphash (lambda (_key val)
                 (push (cons (format "%s %s (%s)"
                                     (symbol-name (plist-get val :status))
                                     (plist-get val :instance)
                                     (plist-get val :directory))
                             (plist-get val :buffer-name))
                       candidates))
               claude-buffer-list--sessions)
      (helm :sources (helm-build-sync-source "Claude Sessions"
                       :candidates (nreverse candidates)
                       :action (lambda (buf-name)
                                 (when (get-buffer buf-name)
                                   (switch-to-buffer buf-name))))
            :buffer "*helm claude sessions*"))))

(defvar claude-buffer-list-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'claude-buffer-list-goto-session)
    (define-key map (kbd "g") #'claude-buffer-list-refresh)
    (define-key map (kbd "s") #'claude-buffer-list-helm)
    (define-key map (kbd "/") #'claude-buffer-list-helm)
    (define-key map (kbd "k") #'claude-buffer-list-kill-session)
    map)
  "Keymap for `claude-buffer-list-mode'.")

(define-derived-mode claude-buffer-list-mode special-mode "Claude-Sessions"
  "Major mode for listing Claude sessions.

\\{claude-buffer-list-mode-map}")

;;;###autoload
(defun claude-buffer-list ()
  "Display a buffer listing all Claude sessions.
If the *Claude Sessions* buffer is already visible, switch to its window."
  (interactive)
  (claude-buffer-list--bootstrap)
  (let* ((buf (get-buffer-create "*Claude Sessions*"))
         (win (get-buffer-window buf)))
    (if win
        (select-window win)
      (with-current-buffer buf
        (claude-buffer-list-mode))
      (switch-to-buffer buf))
    (claude-buffer-list-refresh)
    (goto-char (point-min))
    (forward-line 2)))

;; Setup hooks
(add-hook 'kill-buffer-hook #'claude-buffer-list--on-kill)
(add-hook 'claude-code-event-hook #'claude-buffer-list--event-listener)
(add-hook 'claude-code-start-hook #'claude-buffer-list--on-start)


(provide 'claude-buffer-list)
;;; claude-buffer-list.el ends here

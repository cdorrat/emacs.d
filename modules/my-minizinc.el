
(setq minizinc--dir "/Applications/dev/MiniZincIDE.app/Contents/Resources")

(defun minizinc--binary (fname)
  (expand-file-name fname minizinc--dir))

(load-file "/Users/cnd/.emacs.d/elpa/minizinc-mode-20180201.1450/minizinc-mode.el")
(flycheck-set-checker-executable (quote mzn2fzn) (minizinc--binary "mzn2fzn"))
(require 'minizinc-mode)
(add-to-list 'auto-mode-alist '("\\.mzn\\'" . minizinc-mode))
(add-to-list 'auto-mode-alist '("\\.dzn\\'" . minizinc-mode))


(defun minizinc-switch-to-output ()
  "Switch to the minizinc output buffer"
  (interactive)  
  (pop-to-buffer "*minizinc-output*"))

(defun minizinc-switch-to-last-minizinc-buffer ()
  "Switch to the most recently active minizinc-mode buffer "
  (interactive)
  (if (and (boundp 'minizinc-output-mode) minizinc-output-mode)
      (if-let* ((buf (seq-find (lambda (b)
				  (with-current-buffer b (derived-mode-p 'minizinc-mode)))
				(buffer-list))))
	  (pop-to-buffer buf)
	(user-error "No Minizinc buffer found"))
    (user-error "Not in a Minizinc output buffer")))

(define-minor-mode minizinc-output-mode
  "minizinc output buffer"
  :lighter " mz"
  :keymap (let ((km (make-sparse-keymap)))
	    (define-key km (kbd "C-c C-z") 'minizinc-switch-to-last-minizinc-buffer)
	    km))

(defun minizinc--get-buffer-opt (opt-name)
  (save-excursion
    (goto-char 0)
    (when (re-search-forward
	   (concat
	    "^%%[[:blank:]]*" opt-name ":[[:blank:]]*\\(.*\\)$") nil t)
      (match-string-no-properties 1))))

;; (defun minizinc--buffer-data-file ()
;;   "get the name of a data file specified with: %% data-file: some-name.dzn"
;;   (minizinc--get-buffer-opt "data-file"))
  
;; (defun minizinc--buffer-data-file ()
;;   "get the name of a data file specified with: %% data-file: some-name.dzn"
;;   (save-excursion
;;     (goto-char 0)
;;     (when (re-search-forward "^%%[[:blank:]]*data-file:[[:blank:]]*\\([[:graph:]]+\\)$" nil t )
;;       (match-string-no-properties 1))))

(defun minizinc--is-data-file? ()
  (s-ends-with? ".dzn"  (buffer-file-name) t))

(defun minizinc--run-buffer (&optional flags)
  (save-buffer)
  (let ((cmd (concat (minizinc--binary "minizinc")
		     flags ;; " -Ggecode "
		     ;; TODO - need to read options from model file for data file runs
		     " " (minizinc--get-buffer-opt "options")
		     (if (minizinc--is-data-file?)
			 (concat 
			  " " (minizinc--get-buffer-opt "model-file")
			  " " (buffer-file-name))
		       (concat
			" " (buffer-file-name)
			" " (minizinc--get-buffer-opt "data-file"))))))
    (message "Running minizinc with: %s" cmd)
    (shell-command  cmd "*minizinc-output*")
    (with-current-buffer "*minizinc-output*"
      (minizinc-output-mode t))
    (message "minizinc finished")))

(defun minizinc-run ()
  (interactive)
  (minizinc--run-buffer))

(defun minizinc-run-verbose ()
  (interactive)
  (minizinc--run-buffer "--all-solutions"))
;; ^[:blank:]*data-file:[:blank:]*[^[:blank"]]

(defun enable-my-minizinc-keys ()
  (interactive)
  (local-set-key (kbd "C-c C-k") 'minizinc-run) 
  (local-set-key (kbd "C-c C-M-k") 'minizinc-run-verbose)
  (local-set-key (kbd "C-c C-z") 'minizinc-switch-to-output))

(add-hook 'minizinc-mode-hook 'enable-my-min)

(provide 'my-minizinc)
(cider-switch-to-repl-buffer)

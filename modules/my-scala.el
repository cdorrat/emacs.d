;; ensime
(require 'ensime)

(setq ensime-startup-notification nil)


(defun my-scala-switch-to-repl ()
  "Switch to the scala repl"
  (interactive)  
  (pop-to-buffer ensime-inf-buffer-name))

(defun my-scala-switch-to-last-scala-buffer ()
  "Switch to the most recently active scala-mode buffer "
  (interactive)
  (if (derived-mode-p 'ensime-inf-mode)
      (if-let* ((buf (seq-find (lambda (b)
				  (with-current-buffer b (derived-mode-p 'scala-mode)))
				(buffer-list))))
	  (pop-to-buffer buf)
	(user-error "No Scala buffer found"))
    (user-error "Not in a Scala REPL buffer")))

(defun my-scala-send-buffer-to-repl ()
  (interactive)
  (ensime-inf-send-string (concat ":paste -raw " buffer-file-name "\n"
				  (buffer-substring-no-properties 1 (point-max)))))

(defun enable-my-scala-keys ()
  (interactive)
  (local-set-key (kbd "C-c M-j") 'ensime)
  (local-set-key (kbd "C-c C-z") 'my-scala-switch-to-repl)
  (local-set-key (kbd "C-c C-k") 'my-scala-send-buffer-to-repl))

(defun enable-my-scala-repl-keys ()
  (interactive)
  (local-set-key (kbd "C-c C-z") 'my-scala-switch-to-last-scala-buffer))


(defun setup-dash-for-scala ()
  (interactive)
  (setq dash-at-point-docset "scala"))

(add-hook 'scala-mode-hook 'enable-my-scala-keys)
(add-hook 'scala-mode-hook 'setup-dash-for-scala)


(add-hook 'ensime-inf-mode-hook 'enable-my-scala-repl-keys)
(add-hook 'ensime-inf-mode-hook 'setup-dash-for-scala)

(provide 'my-scala)

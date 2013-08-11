(require 'ess-site)

(setq ess-history-directory "~/.emacs_files/R")

(unless (file-directory-p ess-history-directory)
  (mkdir ess-history-directory))

(defun enable-my-ess-keys ()
  (interactive)
  (local-set-key (kbd "<f12> r") 'ess-switch-to-inferior-or-script-buffer)
  (local-set-key (kbd "C-c C-k") 'ess-eval-buffer)
  (local-set-key (kbd "C-c M-j") 'R))

(add-hook 'ess-mode-hook 'enable-my-ess-keys)
(add-hook 'inferior-ess-mode-hook 'enable-my-ess-keys)

;; debug mode doesn't have a hook, stick them straight in the appropriat emap  
(define-key ess-debug-minor-mode-map (kbd "<f5>")  'ess-debug-command-next)
(define-key ess-debug-minor-mode-map (kbd "<f6>")  'ess-debug-command-next-multi)
(define-key ess-debug-minor-mode-map (kbd "<f7>")  'ess-debug-command-up)
(define-key ess-debug-minor-mode-map (kbd "<f8>")  'ess-debug-command-continue)

(provide 'my-ess)

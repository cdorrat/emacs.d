(require 'ess-site)

(setq ess-history-directory "~/.emacs_files/R")

(unless (file-directory-p ess-history-directory)
  (mkdir ess-history-directory))

(defun enable-my-ess-keys ()
  (interactive)
  (local-set-key (kbd "<f12> r") 'ess-switch-to-inferior-or-script-buffer)
  (local-set-key (kbd "C-c C-k") 'ess-eval-buffer)
  (local-set-key (kbd "C-c M-j") 'R)
)

(add-hook 'ess-mode-hook 'enable-my-ess-keys)
(add-hook 'inferior-ess-mode-hook 'enable-my-ess-keys)

(provide 'my-ess)

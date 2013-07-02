(require 'ess-site)

(setq ess-history-directory "~/.emacs_files/R")

(unless (file-directory-p ess-history-directory)
  (mkdir ess-history-directory))


(provide 'my-ess)


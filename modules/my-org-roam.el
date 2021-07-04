;; Org and Org-roam

;;; Tell Emacs to start org-roam-mode when Emacs starts
(add-hook 'after-init-hook 'org-roam-mode)

;;; Define key bindings for Org-roam
(global-set-key (kbd "C-c n r") #'org-roam-buffer-toggle-display)
(global-set-key (kbd "C-c n i") #'org-roam-insert)
(global-set-key (kbd "C-c n /") #'org-roam-find-file)
(global-set-key (kbd "C-c n b") #'org-roam-switch-to-buffer)
(global-set-key (kbd "C-c n d") #'org-roam-find-directory)

;; org-store-link / org-insert-link
(setq org-roam-directory "~/Documents/docs/roam")

(setq org-roam-capture-templates
      '(("d" "default" plain (function org-roam--capture-get-point)
	 "%?"
	 :file-name "%<%Y%m%d%H%M%S>-${slug}"
	 :head "#+title: ${title}\n"
	 :unnarrowed t)

	("c" "coding" plain (function org-roam--capture-get-point)
	 "%?"
	 :file-name "coding/%<%Y%m%d%H%M%S>-${slug}"
	 :head "#+title: ${title}\n#+roam_tags: \n"
	 :unnarrowed t)
	)
      )

(provide 'my-org-roam)

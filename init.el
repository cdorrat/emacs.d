(set-face-attribute 'default nil :height 120)
;; "Essential PragmataPro" -> default face?
;; "Droid Sans Mono"

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "white" :foreground "black" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 120 :width normal :foundry "unknown" :family "Essential PragmataPro")))))

(mouse-wheel-mode t)
(global-set-key [mouse-4 'scroll-down])
(global-set-key [mouse-5] 'scroll-up)
(global-set-key (quote [201326632]) 'scroll-down)
(global-set-key (quote [201326633]) 'scroll-up)

(global-set-key "" (quote call-last-kbd-macro))
(global-set-key (quote [f9]) 'magit-status)


(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(tool-bar-mode 0)
(show-paren-mode t)

(defalias 'yes-or-no-p 'y-or-n-p)

(setq inhibit-startup-message t) ;; No splash screen
(setq initial-scratch-message nil) ;; No scratch message

(recentf-mode 1)
(global-set-key (kbd "C-x C-r") 'recentf-open-files)

;; Create backup files in .emacs-backup instead of everywhere
(defvar user-temporary-file-directory "~/.emacs-backup")
(make-directory user-temporary-file-directory t)
(setq backup-by-copying t)
(setq backup-directory-alist
      `(("." . ,user-temporary-file-directory)
	(,tramp-file-name-regexp nil)))
(setq auto-save-list-file-prefix
      (concat user-temporary-file-directory ".auto-saves-"))
(setq auto-save-file-name-transforms
      `((".*" ,user-temporary-file-directory t)))


; make emacs play nicely withthe X11 clipboard
(setq x-select-enable-clipboard t)
;;(setq interprogram-paste-function 'x-cut-buffer-or-selection-value)

; make todo.txt open in org mode automatically
(setq auto-mode-alist
  (append 
   ;; File name (within directory) starts with a dot.
   '(
     ;; File name end with todo.txt
     ("todo\\.txt\\'" . org-mode))
   auto-mode-alist))

(require 'tramp)

(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)
(package-initialize)

(defconst user-init-dir
  (cond ((boundp 'dotfiles-dir) dotfiles-dir) 
	((boundp 'user-emacs-directory) user-emacs-directory)
        ((boundp 'user-init-directory) user-init-directory)
        (t "~/.emacs.d/")))

(setq modules-path (file-name-as-directory (concat user-init-dir  "modules")))
(add-to-list 'load-path modules-path)

(require 'iedit) ;; C-; search/replace

(require 'fiplr) ;; find files in project
(setq fiplr-root-markers '(".git" ".svn" "project.clj"))
(global-set-key [33554450] 'fiplr-find-file) ;; C-S-r

;; support for loading & saving window/buffer config
 (require 'workgroups)
 (setq wg-prefix-key (kbd "C-x w")
       wg-restore-associated-buffers t ; restore all buffers opened in this WG?
       wg-use-default-session-file t   ; turn off for "emacs --daemon"
       wg-default-session-file "~/.emacs_files/workgroups"
       wg-use-faces nil
       wg-morph-on nil)

;; ;; Keyboard shortcuts - load, save, switch
(global-set-key (kbd "<pause>")     'wg-revert-workgroup)
(global-set-key (kbd "C-<pause>") 'wg-update-workgroup)
;; ;(global-set-key (kbd "s-z")         'wg-switch-to-workgroup)
;; ;(global-set-key (kbd "s-/")         'wg-switch-to-previous-workgroup)

(workgroups-mode 1)     ; Activate workgroups
(unless (file-directory-p "~/.emacs_files")
  (mkdir "~/.emacs_files"))

(when (file-exists-p wg-default-session-file)
  (wg-load wg-default-session-file))

;; =================================================================================================== 
;; auto completion
(setq tab-always-indent 'complete)
(add-to-list 'completion-styles 'initials t)

(setq ido-enable-flex-matching t)
(ido-mode 1)
(ido-everywhere 1)

(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/dict")
(ac-config-default)
(ac-flyspell-workaround)

;; =================================================================================================== 
;; Configure clojure
(require 'my-clojure)
(require 'setup-paredit)
(require 'paredit-menu)


;;===================================================================================================
;; yasnippet setup
;; (require 'yasnippet)
;; (yas/global-mode 1)

;; (setq dotfiles-dir (file-name-directory (or load-file-name (buffer-file-name))))

;; (yas/load-directory (expand-file-name "snippets" dotfiles-dir))

;; yasnippet and org-mode don't play well together when using TAB for completion. This should fix it:

;; (defun yas/org-very-safe-expand ()
;;                  (let ((yas/fallback-behavior 'return-nil)) (yas/expand)))
;; (add-hook 'org-mode-hook
;;           (lambda ()
;;             (make-variable-buffer-local 'yas/trigger-key)
;;             (setq yas/trigger-key [tab])
;;             (add-to-list 'org-tab-first-hook 'yas/org-very-safe-expand)
;;             (define-key yas/keymap [tab] 'yas/next-field)))


;;===================================================================================================

  
(defun frame-on-laptop ()
  (interactive)
  (make-frame-on-display "10.1.1.9:0"))

(require 'my-ess)

;; ===================================================================================================
(require 'nxml-mode)

(defconst my-xml-escape-chars 
  '(("&" "&amp;") ("<" "&lt;") (">" "&gt;")))

(defun my-xml-escape (s)
  (let ((result s))    
    (dolist (kv my-xml-escape-chars)
      (setq result (replace-regexp-in-string (car kv) (second kv) result)))
    result))

(defun my-xml-unescape (s)
  (let ((result s))    
    (dolist (kv my-xml-escape-chars)
      (setq result (replace-regexp-in-string (second kv) (car kv) result)))
    result))
		
(defun my-xml-escape-paste ()
  "insert the contents of the clipboard escaping html characters"
  (interactive)
  (save-excursion
    (insert (my-xml-escape (current-kill 0 1)))))

(defun my-xml-escape-region ()
  "kills the current region & replaces it with an x/html escaped version, the previous text is saved in the kill ring.
  if no region is selected it defaults to the current nxml p (see with M-h)"
  (interactive)
  (when (not (region-active-p))
    (nxml-mark-paragraph))
  (let ((start (region-beginning))
	(end (region-end)))                 
    (kill-region start end)
    (goto-char start)
    (insert (my-xml-escape (current-kill 0 1)))))

  
(defun region-test (start end)
  (interactive "r")
  (message (number-to-string start)))

;; nxml doesnt have a mode hook so we'll add the binding directly to it's keymap
(define-key nxml-mode-map (kbd "C-y") 'yank)
(define-key nxml-mode-map (kbd "M-C-y") 'my-xml-escape-paste)


;; ===================================================================================================
(require 'anki)

(global-set-key (kbd "<f12> a") 'anki-add-fact) 

(require 'itail)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(itail-highlight-list (quote (("\\b(ERROR|WARN|FATAL)\\b.*$" . hi-red-b) ("\\bINFO\\b" . link) ("^[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\},[0-9]\\{3\\} " . font-lock-string-face)))))

;; ===================================================================================================
;; jump-char
(require 'ace-jump-mode)
(require 'jump-char)

(global-set-key [(meta m)] 'jump-char-forward)
(global-set-key [(shift meta m)] 'jump-char-backward)
(global-set-key [(control c) space] 'ace-jump-mode)


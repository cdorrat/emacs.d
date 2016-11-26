;; (set-face-attribute 'default nil :height 120)
;; "Essential PragmataPro" -> default face?
;; "Droid Sans Mono"

;; (custom-set-faces
;;  ;; custom-set-faces was added by Custom.
;;  ;; If you edit it by hand, you could mess it up, so be careful.
;;  ;; Your init file should contain only one such instance.
;;  ;; If there is more than one, they won't work right.
;;  '(default ((t (:inherit nil :stipple nil :background "white" :foreground "black" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 120 :width normal :foundry "unknown" :family "Essential PragmataPro")))))

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


(defvar cdorrat/packages '(			   
			   ag
			   cl
			   clj-refactor
			   command-log-mode
			   company
			   helm-projectile
			   hydra
			   key-chord
			   magit
			   markdown-mode
			   multiple-cursors
			   projectile
			   ace-jump-mode
			   cider
			   dash
			   dockerfile-mode
			   ess
			   fiplr
			   fixmee
			   git-gutter-fringe
			   helm-ag
			   iedit
			   itail
			   jump-char
			   nxml
			   package
			   paredit
			   paredit-menu
			   s
			   sass-mode
			   tramp
			   workgroups
			   wsd-mode
			   yaml-mode))

(require 'cl)
(require 'package)
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)
;; (add-to-list 'package-pinned-packages '(cider . "melpa-stable") t)
;; (add-to-list 'package-pinned-packages '(clojure-mode . "melpa-stable") t)
(package-initialize)

(defun cdorrat/packages-installed-p ()
  (loop for pkg in cdorrat/packages
        when (not (package-installed-p pkg)) do (return nil)
        finally (return t)))

(unless (cdorrat/packages-installed-p)
  (message "%s" "Refreshing package database...")
  (package-refresh-contents)
  (dolist (pkg cdorrat/packages)
    (when (not (package-installed-p pkg))
      (package-install pkg))))

(defconst user-init-dir
  (cond ((boundp 'dotfiles-dir) dotfiles-dir) 
	((boundp 'user-emacs-directory) user-emacs-directory)
        ((boundp 'user-init-directory) user-init-directory)
        (t "~/.emacs.d/")))

(setq modules-path (file-name-as-directory (concat user-init-dir  "modules")))
(add-to-list 'load-path modules-path)

(require 'tramp)
(require 'iedit) ;; C-; search/replace

(require 'fiplr) ;; find files in project
(setq fiplr-root-markers '(".git" ".svn" "project.clj"))
(global-set-key [33554450] 'fiplr-find-file) ;; C-S-r

;; =================================================================================================== 
;; auto completion
(setq tab-always-indent 'complete)
(add-to-list 'completion-styles 'initials t)

(setq ido-enable-flex-matching t)
(ido-mode 1)
(ido-everywhere 1)

(require 'company)
(global-company-mode)

;; (require 'auto-complete-config)
;; (add-to-list 'ac-dictionary-directories "~/.emacs.d/dict")
;; (ac-config-default)
;; (ac-flyspell-workaround)

;; =================================================================================================== 
;; Configure clojure
(require 'my-clojure)
(require 'setup-paredit)
(require 'paredit-menu)

(require 'ob)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((clojure . t)
   (sh . t)
   (emacs-lisp . t)
   (sql . t)))

(setq org-babel-clojure-backend 'cider)

;; Let's have pretty source code blocks
(setq org-edit-src-content-indentation 0
      org-src-tab-acts-natively t
      org-src-fontify-natively t
       org-confirm-babel-evaluate nil
      org-support-shift-select 'always)

;; Useful keybindings when using Clojure from Org
(org-defkey org-mode-map "\C-x\C-e" 'cider-eval-last-sexp)
(org-defkey org-mode-map "\C-c\C-d" 'cider-doc)

;; No timeout when executing calls on Cider via nrepl
(setq org-babel-clojure-nrepl-timeout nil)


;; ===================================================================================================
;; jump-char

(require 'fast-load)
(global-set-key [(f8)] 'xah-open-file-fast)


(require 'ace-jump-mode)
(require 'jump-char)

(global-set-key [(meta m)] 'jump-char-forward)
(global-set-key [(shift meta m)] 'jump-char-backward)
(global-set-key (quote [67108912]) 'ace-jump-mode) ;; Ctrl-0
(global-unset-key "")

;;
;; eshell
;;(local-set-key [C-up] (quote eshell-previous-matching-input-from-input))
(require 'eshell)
(add-hook 'eshell-mode-hook
	  '(lambda ()
	     (define-key eshell-mode-map [C-up] 'eshell-previous-matching-input-from-input)))

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
 '(package-selected-packages
   (quote
    (yaml-mode wsd-mode paredit-menu itail iedit helm-ag multiple-cursors markdown-mode magit key-chord hydra helm-projectile ag workgroups magit-popup jump-char git-gutter-fringe git-commit fixmee fiplr ess command-log-mode clj-refactor ace-jump-mode))))


;; ===================================================================================================
(require 'multiple-cursors)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)

(defun eval-and-replace ()
  "Replace the preceding sexp with its value."
  (interactive)
  (backward-kill-sexp)
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
	     (current-buffer))
    (error (message "Invalid expression")
	   (insert (current-kill 0)))))


;; ===================================================================================================
;; Custom key bindings
(mouse-wheel-mode t)
(global-set-key [mouse-4] 'scroll-down)
(global-set-key [mouse-5] 'scroll-up)
(global-set-key (quote [201326632]) 'scroll-down)
(global-set-key (quote [201326633]) 'scroll-up)
(global-set-key "" (quote call-last-kbd-macro))
(global-set-key (quote [f9]) 'magit-status)
(global-set-key [(meta m)] 'jump-char-forward)
(global-set-key [(shift meta m)] 'jump-char-backward)
(global-set-key (quote [67108912]) 'ace-jump-mode) ;; Ctrl-0
(global-unset-key "")

;; ===================================================================================================
(setq magit-last-seen-setup-instructions "1.4.0")

;; setup pairning env
(defun ss-setup ()
  (interactive)
  (load-theme 'wombat)
  (auto-revert-mode)
  
  ;; show which emacs commands are being used
  ;; (require 'command-log-mode)
  ;; (add-hook 'cider-mode-hook 'command-log-mode)
  ;; (add-hook 'clojure-mode-hook 'command-log-mode)

  (if (functionp 'window-system)
      (when (and (window-system)
		 (>= emacs-major-version 24))
	(server-start))))


 (ss-setup)


;; ===================================================================================================
(require 'projectile)
(require 'helm-projectile)
(projectile-global-mode)
(setq projectile-completion-system 'helm)
(helm-projectile-on)


;;
(defun rotate-windows-helper(x d)
  (if (equal (cdr x) nil) (set-window-buffer (car x) d)
    (set-window-buffer (car x) (window-buffer (cadr x))) (rotate-windows-helper (cdr x) d)))
 
(defun rotate-windows ()
  (interactive)
  (rotate-windows-helper (window-list) (window-buffer (car (window-list))))
  (select-window (car (last (window-list)))))

(require 'key-chord)
(key-chord-mode 1)

(require 'fixmee)
;(global-fixmee-mode 1)

(defun my-curr-buffer-to-cider ()
  (interactive)
  (pop-to-buffer-same-window   
   (cider-current-repl-buffer)))

(require 'hydra)
(key-chord-define-global
 "ww"
 (defhydra hydra-window  (global-map "C-x w")
   "manipulate windows"
   ("0" delete-window)
   ("1" delete-other-windows)
   ("2" split-window-below)
   ("3" split-window-right)
   ("n" other-window)
   ("C-<up>" shrink-window)
   ("C-<down>" enlarge-window)
   ("C-<left>" shrink-window-horizontally)
   ("C-<right>" enlarge-window-horizontally)
   ("<up>" windmove-up)
   ("<down>" windmove-down)
   ("<left>" windmove-left)
   ("<right>" windmove-right)
   ("C-n" windmove-down)
   ("C-p" windmove-up)
   ("C-f" windmove-right)
   ("C-b" windmove-left) 
   ("=" balance-windows)
   ("r" rotate-windows)
   ("c" my-curr-buffer-to-cider)
   ("B" helm-projectile-switch-to-buffer)
   ("b" ido-switch-buffer)
   ("F" helm-projectile-find-file)
   ("f" ido-find-file)
   ("q" nil :exit true)
   ("W" make-frame-command)))

 (defhydra hydra-projectile (:color blue :hint nil :idle 0)
   "
                                                                                                                          ╭────────────┐                   ╭────────┐
   Files             Search          Buffer             Do                Other Window      Run             Cache         │ Projectile │    Do             │ Fixmee │
 ╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴────────────╯  ╭────────────────┴────────╯
   [_f_] file          [_a_] ag prj      [_b_] switch         [_gg_] magit        [_F_] file          [_U_] test        [_kc_] clear         [_x_] TODO & FIXME
   [_l_] file dwim     [_A_] ag file     [_v_] show all       [_p_] commander     [_L_] dwim          [_m_] compile     [_kk_] add current   [_X_] toggle
   [_r_] recent file   [_s_] occur       [_V_] ibuffer        [_i_] info          [_D_] dir           [_c_] shell       [_ks_] cleanup
   [_d_] dir           [_S_] replace     [_K_] kill all       [_gd_] vc diff      [_O_] other         [_C_] command     [_kd_] remove
    ^ ^                 ^ ^              [_y_] kill ring       ^ ^                [_B_] buffer
   [_P_] Switch Project
  --------------------------------------------------------------------------------
        "
   ("<tab>" hydra-master/body "back")
   ("<ESC>" nil "quit")
   ("q" nil "quit")
   ("a"   helm-ag-project-root)
   ("A"   helm-ag-this-file)
   ("b"   projectile-switch-to-buffer)
   ("B"   projectile-switch-to-buffer-other-window)
   ("c"   projectile-run-async-shell-command-in-root)
   ("C"   projectile-run-command-in-root)
   ("d"   projectile-find-dir)
   ("D"   projectile-find-dir-other-window)
   ("f"   projectile-find-file)
   ("F"   projectile-find-file-other-window)
   ("gg"  projectile-vc)
   ("gd"  vc-diff)
   ("h"   projectile-dired)
   ("i"   projectile-project-info)
   ("kc"  projectile-invalidate-cache)
   ("kd"  projectile-remove-known-project)
   ("kk"  projectile-cache-current-file)
   ("P"   projectile-switch-project)
   ("K"   projectile-kill-buffers)
   ("ks"  projectile-cleanup-known-projects)
   ("l"   projectile-find-file-dwim)
   ("L"   projectile-find-file-dwim-other-window)
   ("m"   projectile-compile-project)
   ("o"   projectile-find-other-file)
   ("O"   projectile-find-other-file-other-window)
   ("p"   projectile-commander)
   ("r"   projectile-recentf)
   ("s"   projectile-multi-occur)
   ("S"   projectile-replace)
   ("t"   projectile-find-tag)
   ("T"   projectile-regenerate-tags)
   ("u"   projectile-find-test-file)
   ("U"   projectile-test-project)
   ("v"   projectile-display-buffer)
   ("V"   projectile-ibuffer)
   ("X"   fixmee-mode)
   ("x"   fixmee-view-listing)
   ("y"   helm-show-kill-ring "list" :color blue))

(global-set-key (kbd "C-=") 'hydra-projectile/body)


;; (key-chord-define-global
;;  "rr"
;;  (defhydra hydra-cljr (:color pink :hint nil)
;;    " Fns & General ^^NS / Import ^^Project ^^Let ------------------------------------------------------------------------------------------------------------------------------------ _pf_ Promote function _am_ Add missing libspec _pc_ Project clean _il_ Introduce let _cp_ Cycle privacy _cn_ Clean ns _hd_ Hotload dependency _el_ Expand let _fe_ Create function from example _sr_ Stop referring _sp_ Sort project dependencies _rl_ Remove let _cs_ Change function signature _ru_ Replace use _ap_ Add project dependency _ml_ Move to let _dk_ Destructure keys _ai_ Add import to ns _sc_ Show the project's changelog _ec_ Extract constant _au_ Add use to ns _up_ Update project dependencies ^Threading _ef_ Extract function _ar_ Add require to ns _ad_ Add declaration ------------------------ _fu_ Find usages _sn_ Sort ns ^^ _th_ Thread _is_ Inline symbol _rr_ Remove unused requires ^^ _tf_ Thread first all _mf_ Move form to ns ^^^^ _tl_ Thread last all _rf_ Rename file-or-dir ^^^^ _ua_ Unwind all _rs_ Rename symbol ^^^^ _uw_ Unwind ^^^^^^_ct_ Cycle thread _as_ Add stubs for the interface / protocol at point. _cc_ Cycle coll _rd_ Remove debug fns _ci_ Cycle if _q_ quit "
;;    ("ai" cljr-add-import-to-ns "Add import to ns")
;;    ("am" cljr-add-missing-libspec "Add missing libspec")
;;    ("ap" cljr-add-project-dependency "Add project dependency")
;;    ("ar" cljr-add-require-to-ns "Add require to ns")
;;    ("as" cljr-add-stubs "Add stubs for the interface / protocol at point.")
;;    ("au" cljr-add-use-to-ns "Add use to ns")
;;    ("cc" cljr-cycle-coll "Cycle coll")
;;    ("ci" cljr-cycle-if "Cycle if")
;;    ("cn" cljr-clean-ns "Clean ns")
;;    ("cp" cljr-cycle-privacy "Cycle privacy")
;;    ("cs" cljr-change-function-signature "Change function signature")
;;    ("ct" cljr-cycle-thread "Cycle thread")
;;    ("dk" cljr-destructure-keys "Destructure keys")
;;    ("ec" cljr-extract-constant "Extract constant")
;;    ("ef" cljr-extract-function "Extract function")
;;    ("el" cljr-expand-let "Expand let")
;;   ("fe" cljr-create-fn-from-example "Create function from example")
;;    ("fu" cljr-find-usages "Find usages")
;;    ("hd" cljr-hotload-dependency "Hotload dependency")
;;    ("il" cljr-introduce-let "Introduce let")
;;   ("is" cljr-inline-symbol "Inline symbol")
;;    ("mf" cljr-move-form "Move form")
;;    ("ml" cljr-move-to-let "Move to let")
;;   ("pc" cljr-project-clean "Project clean")
;;    ("pf" cljr-promote-function "Promote function")
;;    ("rd" cljr-remove-debug-fns "Remove debug fns")
;;    ("rf" cljr-rename-file-or-dir "Rename file-or-dir")
;;    ("rl" cljr-remove-let "Remove let")
;;  ("rr" cljr-remove-unused-requires "Remove unused requires")
;;    ("rs" cljr-rename-symbol "Rename symbol")
;;    ("ru" cljr-replace-use "Replace use")
;;    ("sn" cljr-sort-ns "Sort ns")
;;    ("sc" cljr-show-changelog "Show the project's changelog")
;;    ("sp" cljr-sort-project-dependencies "Sort project dependencies")
;;    ("sr" cljr-stop-referring "Stop referring")
;;    ("tf" cljr-thread-first-all "Thread first all")
;;    ("th" cljr-thread "Thread")
;;    ("tl" cljr-thread-last-all "Thread last all")
;;    ("ua" cljr-unwind-all "Unwind all")
;;    ("uw" cljr-unwind "Unwind")
;;    ("up" cljr-update-project-dependencies "Update project dependencies")
;;    ("ad" cljr-add-declaration "Add declaration")
;;    ("q" nil :exit true)))



(defhydra hydra-git-gutter
  (
   :body-pre (git-gutter-mode 1)
	     :idle 0
	     :hint "my test head")
  "
Git gutter:
  _j_: next hunk        _s_tage hunk     _q_uit
  _k_: previous hunk    _r_evert hunk    _Q_uit and deactivate git-gutter
  ^ ^                   _p_opup hunk
  _h_: first hunk
  _l_: last hunk        set start _R_evision
"
  ("j" git-gutter:next-hunk)
  ("<down>" git-gutter:next-hunk)
  ("k" git-gutter:previous-hunk)
  ("<up>" git-gutter:previous-hunk)
  
  ("h" (progn (goto-char (point-min))
	      (git-gutter:next-hunk 1)))
  ("<home>" (progn (goto-char (point-min))
		   (git-gutter:next-hunk 1)))
  
  ("l" (progn (goto-char (point-min))
	      (git-gutter:previous-hunk 1)))
  ("<end>" (progn (goto-char (point-min))
		  (git-gutter:previous-hunk 1)))
  ("s" git-gutter:stage-hunk)
  ("r" git-gutter:revert-hunk)
  ("p" git-gutter:popup-hunk)
  ("R" git-gutter:set-start-revision)
  ("q" nil :color blue)
  ("Q" (progn (git-gutter-mode -1)
	      ;; git-gutter-fringe doesn't seem to
	      ;; clear the markup right away
	      (sit-for 0.1)
	      (git-gutter:clear))
   :color blue))


(global-set-key (kbd "C-c g")  'hydra-git-gutter/body)

(defun kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;; ===================================================================================================
;; org mode setup
(require 'org)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (clojure . t)))

(setq org-babel-clojure-backend 'cider)

(setq org-edit-src-content-indentation 0
      org-src-tab-acts-natively t
      org-src-fontify-natively t
      org-confirm-babel-evaluate nil)


(put 'narrow-to-region 'disabled nil)

(require 'ansi-color)

(defun ansi-color-display ()
  (interactive)
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region (point-min) (point-max))))


;;(require 'password-store)

;; ===================================================================================================
;; OSX specific config
(when (eq system-type 'darwin)
  (setq mac-option-modifier 'super)
  (setq mac-command-modifier 'meta)
  (global-set-key [f11] (quote toggle-frame-fullscreen))
  (global-set-key [home] (quote beginning-of-line))
  (global-set-key [end] (quote end-of-line))
  (global-set-key [C-help] (quote kill-ring-save))
  (global-set-key [S-help] (quote yank))  
   
  (set-variable
   'exec-path
   (quote
    ("/usr/bin" "/bin" "/usr/sbin" "/usr/local/bin" "/sbin"
     "/Applications/Emacs.app/Contents/MacOS/bin-x86_64-10_9"
     "/Applications/Emacs.app/Contents/MacOS/libexec-x86_64-10_9"
     "/Applications/Emacs.app/Contents/MacOS/libexec"
     "/Applications/Emacs.app/Contents/MacOS/bin"))))

;; ===================================================================================================
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



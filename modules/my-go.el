;; Golang support


(setq exec-path
      (append exec-path 
	      (list (concat (substring  (shell-command-to-string "go env GOPATH") 0 -1) "/bin"))))

(setq company-idle-delay 0)
(setq company-minimum-prefix-length 1)

;; Go - lsp-mode
(require 'go-mode)
(require 'gorepl-mode)
;;(require 'dap-dlv-go)
(setq lsp-go-gopls-server-path "/Users/cdorrat/Development/gap/.hermit/go/bin/gopls")

;; Set up before-save hooks to format buffer and add/delete imports.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; Start LSP Mode and YASnippet mode
(add-hook 'go-mode-hook #'lsp-deferred)
(add-hook 'go-mode-hook #'yas-minor-mode)
(add-hook 'go-mode-hook #'gorepl-mode)
(add-hook 'go-mode-hook (lambda ()
			  (setq tab-width 3)))


(defun mygo/switch-to-most-recent-go-buffer ()
  (when-let ((go-source-buffer (seq-find (lambda (buf)
				      (string-suffix-p ".go" (buffer-name buf) 't))
					 (buffer-list))))
    (switch-to-buffer-other-window go-source-buffer)))

(defun mygo/toggle-switch-to-repl ()
  (interactive)
  (if (string= gorepl-buffer (buffer-name))
      (mygo/switch-to-most-recent-go-buffer)
    (and
	(gorepl--run-gore '())
	(switch-to-buffer-other-window (get-buffer gorepl-buffer))
	(gorepl-mode 1))))

(defun mygo/repl-eval-func ()
  (interactive)
  (save-excursion
    (let ((begin (progn (go-beginning-of-defun) (point)))
	  (end (progn (go-end-of-defun) (point))))
      (set-mark begin)
      (goto-char end)
      (call-interactively 'gorepl-eval-region)
      (deactivate-mark))))

(defun mygo/repl-eval-line-or-region (num-lines)
  (interactive "p")
  (if (use-region-p)
      (progn
       (gorepl-eval-region (region-beginning) (region-end))
       (deactivate-mark))
    (call-interactively 'gorepl-eval-line num-lines)))

(defun mygo/repl-load-current-file ()
  (interactive)
  (call-interactively 'gorepl-run-load-current-file)
  (mygo/toggle-switch-to-repl))

(defun mygo/test-project ()
  (interactive)
  (my-test-current-project nil))

(defun mygo/race-test-project ()
  (interactive)
  (my-test-current-project 1))


 (defhydra hydra-go (:color blue :hint nil :idle 0)   
   "
   Docs                Search                Tools             Repl               Debugger    
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────╯
   [_dp_] doc at point  [_fd_] declaration    [_a_]  add import  [_l_]  load file   [_dd_] debug
   [_S_]  search docs   [_i_]  implementation [_e_]  show errors [_R_]  run         [_dl_] rerun last
   [_s_]  dash docs     [_r_]  references     [_k_]  flycheck    [_Q_] quit         [_db_] toggle breakpoint
                      [_td_]  type dec      [_tt_] run tests    [_p_]  set project
                      [_y_]  symbols        [_tr_] race tests                 
   ────────────────────────────────────────────────────────────────────────────────────────────────────
        "
   ("dp" godoc-at-point)
   ("S" godoc)
   ("s" dash-at-point)
   
   ("fd" lsp-find-declaration)
   ("i" lsp-find-implementation)
   ("r" lsp-find-references)
   ("td" lsp-find-type-definition)
   ("y" helm-lsp-workspace-symbol)

   ("a" go-import-add)
   ("e" helm-lsp-diagnostics)
   ("k" my-flycheck-project)
;;   ("c" go-coverage)
;;   ("ff" gofmt)
   ("tt" mygo/test-project)
   ("tr" mygo/race-test-project)
   ("p" go-set-project)

   ("l" mygo/repl-load-current-file)
   ("R" gorepl-run)
   ("Q" gorepl-quit)
   
   ("dd" dap-debug)
   ("dl" dap-debug-last)
   ("db" dap-breakpoint-toggle)
   )

(defun mygo/bind-go-mode-keys ()
  (interactive)
  (local-set-key (kbd "<f12>")  'hydra-go/body)
  (local-set-key (kbd "C-c C-z") 'mygo/toggle-switch-to-repl)
  (local-set-key (kbd "C-M-x") 'mygo/repl-eval-func)
  (define-key go-mode-map (kbd "C-x C-e") 'mygo/repl-eval-line-or-region)
  (define-key go-mode-map (kbd "C-c C-l") 'mygo/repl-load-current-file))


(add-hook 'go-mode-hook 'mygo/bind-go-mode-keys)
(add-hook 'gorepl-mode-hook 'mygo/bind-go-mode-keys)

(define-key go-mode-map (kbd "C-c C-z") 'mygo/toggle-switch-to-repl)
(define-key gorepl-mode-map (kbd "C-c C-z") 'mygo/toggle-switch-to-repl)

;; Add flycheck for additional linter
(flycheck-define-checker go-ci-lint
  "A Linter as used in the block ci server using  `golangci-lint run"
  :command ("golangci-lint" "run" "--out-format" "line-number" "--color" "never"
	    "--config" "/Users/cdorrat/Development/gap/.golangci.yml")
  :error-patterns
  (
   (warning line-start (file-name) ":" line ":"
          (optional column ":") " "
          (message (one-or-more not-newline))
          line-end)
  )
  :modes go-mode
  :predicate (lambda ()
	       (flycheck-buffer-saved-p)
               ;; (and (flycheck-buffer-saved-p)
               ;;      (not (string-suffix-p "_test.go" (buffer-file-name))))
	       ))

(with-eval-after-load 'flycheck
   (add-to-list 'flycheck-checkers 'go-ci-lint)
   (flycheck-add-next-checker 'go-gofmt 'go-ci-lint))

; lsp, if enabled, disables the flycheck checkers by default.
; Re-add ours in that case.
(add-hook 'lsp-configure-hook
      (lambda ()
        (when (eq major-mode 'go-mode)
          (flycheck-add-next-checker 'lsp 'go-ci-lint)))
      100)


(provide 'my-go)

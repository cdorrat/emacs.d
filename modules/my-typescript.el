(require 'js2-mode)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

;; compilation mode support for tsc & eslint
(require 'ansi-color)
(defun colorize-compilation-buffer ()
  (ansi-color-apply-on-region compilation-filter-start (point-max)))
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

;; support for goiing to es-lint errors from a compile buffer
(load "../compile-eslint/compile-eslint.el")
(require 'compile-eslint)
(push 'eslint compilation-error-regexp-alist)

(require 'web-mode)
(setq web-mode-content-types-alist
  '(
    ("jsx"  . ".*\\.js[x]?\\'")))

(require 'indium)             ;; javascript repl
(require 'tide)               ;; typescript editing mode
(require 'my-typescript-repl) ;; ts-comint & key bindings

(defun my-typescript-repl-launch ()
  (interactive)
  (indium-interaction-mode 0)
  (typescript-interaction-mode 1)
  (run-ts))

(defun my-indium-repl-launch ()
  (interactive)
  (typescript-interaction-mode 0)
  (indium-interaction-mode 1)
  (indium-launch))

(defun enable-my-js-keys ()
  (interactive)
  (local-set-key (kbd "C-c M-J") #'my-typescript-repl-launch)
  (local-set-key (kbd "C-c M-j") #'my-indium-repl-launch))


(defun my-setup-indent (n)
  ;; java/c/c++
  (setq-local c-basic-offset n)
  ;; web development
  (setq-local coffee-tab-width n) ; coffeescript
  (setq-local javascript-indent-level n) ; javascript-mode
  (setq-local js-indent-level n) ; js-mode
  (setq-local js2-basic-offset n) ; js2-mode, in latest js2-mode, it's alias of js-indent-level
  (setq-local typescript-indent-level n)
  (setq-local web-mode-markup-indent-offset n) ; web-mode, html tag in html file
  (setq-local web-mode-css-indent-offset n) ; web-mode, css in html file
  (setq-local web-mode-code-indent-offset n) ; web-mode, js code in html file
  (setq-local css-indent-offset n) ; css-mode
  )

(defun work-js-indentation ()
  (interactive)
  (setq indent-tabs-mode nil) ;; spaces instead of tabs
  (my-setup-indent 2) ;; 2 char indents
  )

;;(add-hook 'js-mode-hook #'indium-interaction-mode)
(add-hook 'js2-mode-hook 'enable-my-js-keys)
(add-hook 'js2-mode-hook 'work-js-indentation)


(setq tide-format-options '(:indentSize 2 :tabSize 2 :convertTabsToSpaces t))

(defun setup-tide-mode ()
  (interactive)  
  (tide-setup)
  (auto-revert-mode +1)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  (company-mode +1)
  (indium-interaction-mode +1)
  (setq-local compile-command "npm run build"))

;; aligns annotation to the right hand side
(setq company-tooltip-align-annotations t)

(with-eval-after-load 'flycheck
  (flycheck-add-mode 'javascript-eslint 'typescript-mode))
  
;; formats the buffer before saving
(add-hook 'before-save-hook 'tide-format-before-save)

(add-hook 'typescript-mode-hook #'work-js-indentation)
(add-hook 'typescript-mode-hook #'setup-tide-mode)
(add-hook 'typescript-mode-hook #'enable-my-js-keys)

;;(add-hook 'js2-mode-hook #'setup-tide-mode)
;; configure javascript-tide checker to run after your default javascript checker
(flycheck-add-next-checker 'javascript-eslint 'javascript-tide 'append)


(provide 'my-typescript)

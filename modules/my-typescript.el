(require 'js2-mode)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

;; compilation mode support for tsc & eslint
(require 'ansi-color)
(defun colorize-compilation-buffer ()
  (ansi-color-apply-on-region compilation-filter-start (point-max)))
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

(load "../compile-eslint/compile-eslint.el")
(require 'compile-eslint)
(push 'eslint compilation-error-regexp-alist)

(require 'indium)


(require 'tide)


(defun setup-cogent-env-vars ()
  (interactive)
  (setenv "BILLING_ENTITIES_API_URL" "https://api.test.corp.realestate.com.au/billing_entities")
  (setenv "PROVISIONING_ENTITIES_API_URL" "https://api.test.corp.realestate.com.au/provisioning_entities")
  (setenv "CUSTOMER_ENTITIES_API_URL" "https://api.test.corp.realestate.com.au/customers")
  (setenv "DEAL_PROPOSALS_API_URL" "https://api.test.corp.realestate.com.au/deal_proposals")
  (setenv "LOCKE_USERS_API_URL" "https://api.locke.rea-group.com/au/v1/admin/user")
  (setenv "REALPAY_URL" "https://realpay.test.corp.realestate.com.au/")
  (setenv "SIGNUP_CALLBACK_URL" "https://signup.resi-reach-staging.realestate.com.au/#/results")
  (setenv "DEVELOPMENT_MODE" "true")
  (setenv "LOCKE_ENV" "au_prod")
  (setenv "LOCKE_COOKIE_DOMAIN" "localhost")
  (setenv "LOCKE_CALLBACK_ORIGIN" "http://localhost:3000")
  (setenv "SECURE_ENDPOINT_ALLOW_ORIGIN" "http://localhost:1234")
  (setenv "LOCKE_CLIENT_SECRET" "96bfi12u91n7e782nhpl85mapcfhuo9meo6mggnibui3oq6l577")
  (setenv "LOCKE_APP_ORIGIN" "http://localhost:1234/#/post-sign-in")
  (setenv "LOCKE_CLIENT_ID" "7vnb7uhl86dshmh6t8vjair3hk")
  (setenv "API_KEY" "secret")
  (setenv "REACH_CONFIG" "localhost")
  (setenv "MONEY_API_KEY" "secret")
  (setenv "STORE_API_URL" "http://localhost:4000")
  (setenv "STORE_API_KEY" "secret")
  (setenv "PGDATABASE" "agentreachstore")
  (setenv "PGHOST" "localhost")
  (setenv "DB_SCHEMA" "reach")
  (setenv "PGUSER" "postgres")
  (setenv "PGPASSWORD" "postgres")
  (setenv "STORE_API_USERNAME" "reach")
  (setenv "STORE_API_PASSWORD" "reach")
  (setenv "ANALYTICS_USERNAME" "reachanal")
  (setenv "ANALYTICS_PASSWORD" "reachanal"))

(defun enable-my-js-keys ()
  (interactive)
  ;; (local-set-key (kbd "C-x C-e") 'ts-send-last-sexp)
  ;; (local-set-key (kbd "C-M-x") 'ts-send-last-sexp-and-go)
  ;; (local-set-key (kbd "C-c b") 'ts-send-buffer)
  ;; (local-set-key (kbd "C-c C-b") 'ts-send-buffer-and-go)
  ;; (local-set-key (kbd "C-c l") 'ts-load-file-and-go)
  (local-set-key (kbd "C-c M-j") 'indium-launch)
  )


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

(add-hook 'js-mode-hook #'indium-interaction-mode)
(add-hook 'js2-mode-hook 'enable-my-js-keys)
(add-hook 'js2-mode-hook 'work-js-indentation)


(setq tide-format-options '(:indentSize 2 :tabSize 2 :convertTabsToSpaces t))

(defun setup-tide-mode ()
  (interactive)  
  (tide-setup)
  (auto-revert-mode +1)
  (setq flycheck-eslint-args '("--fix")) ;; thse two lines will lint & fix on save
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  (company-mode +1)
  (indium-interaction-mode +1))

;; aligns annotation to the right hand side
(setq company-tooltip-align-annotations t)

;; formats the buffer before saving
(add-hook 'before-save-hook 'tide-format-before-save)

(add-hook 'typescript-mode-hook #'work-js-indentation)
(add-hook 'typescript-mode-hook #'setup-tide-mode)
(add-hook 'typescript-mode-hook #'enable-my-js-keys)



;; (setq tide-format-options
;;       '(:indentSize 2
;;         :tabSize 2
;; 	;; :indentStyle "space"
;; 	;; :convertTabsToSpaces t
;; 	;; :insertSpaceAfterFunctionKeywordForAnonymousFunctions t
;; 	;; :placeOpenBraceOnNewLineForFunctions nil
;; 	))

;;(add-hook 'js2-mode-hook #'setup-tide-mode)
;; configure javascript-tide checker to run after your default javascript checker
(flycheck-add-next-checker 'javascript-eslint 'javascript-tide 'append)




(provide 'my-typescript)

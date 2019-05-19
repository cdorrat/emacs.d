(require 'easymenu)

;; typescript (tsun) repl support 
(require 'ts-comint)

(defun typescript-switch-to-repl ()
  "Switch to the minizinc output buffer"
  (interactive)
  (switch-to-ts 't))

(defun typescript-switch-to-last-typescript-buffer ()
  "Switch to the most recently active minizinc-mode buffer "
  (interactive)
  (if (equal 'ts-comint-mode major-mode)
      (if-let* ((buf (seq-find (lambda (b)
				  (with-current-buffer b (derived-mode-p 'typescript-mode)))
				(buffer-list))))
	  (pop-to-buffer buf)
	(user-error "No typescript buffer found"))
    (user-error "Not in a typescript comint buffer")))

(add-hook 'ts-comint-mode-hook (lambda ()
				 (local-set-key (kbd "C-c C-z") 'typescript-switch-to-last-typescript-buffer)))

(defvar typescript-interaction-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x C-e") #'ts-send-last-sexp-and-go)
    (define-key map (kbd "C-x e")   #'ts-send-last-sexp)
    (define-key map (kbd "C-c C-k")   #'ts-send-buffer-and-go)
    (define-key map (kbd "C-c k") #'ts-send-buffer)
    (define-key map (kbd "C-c C-l") #'ts-load-file-and-go)
    (define-key map (kbd "C-c C-z") #'typescript-switch-to-repl)
    
    (easy-menu-define typescript-interaction-mode-menu map
      "Menu for Typescript interaction mode"
      '("Indium interaction"
        ["Switch to REPL" typescript-switch-to-repl]
        "--"
        ("Evaluation"
         ["Evaluate last expression" ts-send-last-sexp]
         ["Inspect last expr and go" ts-send-last-sexp-and-go]
	 ["Send buffer" ts-send-buffer]
	 ["Send buffer and go" ts-send-buffer-and-go]
	 ["Load file and go"  ts-load-file-and-go])))
    map))

(define-minor-mode typescript-interaction-mode
  "Mode for Typescript evaluation.

\\{typescript-interaction-mode-map}"
  :lighter " ts-interaction"
  :keymap typescript-interaction-mode-map)

(provide 'my-typescript-repl)


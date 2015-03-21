;; clojure mode settings

(require 'cider)
;;(setq cider-hide-special-buffers t) 
(setq cider-popup-stacktraces-in-repl t)
(setq cider-repl-history-file "~/.emacs.d/nrepl-history")


;(add-hook 'cider-repl-mode-hook #'company-mode)
;(add-hook 'cider-mode-hook #'company-mode)
(require 'ac-cider)
(add-hook 'cider-mode-hook 'ac-flyspell-workaround)
(add-hook 'cider-mode-hook 'ac-cider-setup)
(add-hook 'cider-repl-mode-hook 'ac-cider-setup)
(eval-after-load "auto-complete"
  '(progn
     (add-to-list 'ac-modes 'cider-mode)
     (add-to-list 'ac-modes 'cider-repl-mode)))

(add-hook 'cider-mode-hook 'subword-mode)

;; Some default eldoc facilities
(add-hook 'cider-connected-hook
	  (defun pnh-clojure-mode-eldoc-hook ()
	    (add-hook 'cider-mode-hook 'turn-on-eldoc-mode)
	    (add-hook 'cider-repl-mode-hook 'cider-turn-on-eldoc-mode)
	    (cider-enable-on-existing-clojure-buffers)))
 

;; Auto completion for NREPL
;; (load (concat user-init-dir "ac-nrepl-compliment/ac-cider-compliment.el"))
;; (require 'ac-cider-compliment)
;; (add-hook 'cider-mode-hook 'ac-cider-compliment-setup)
;; (add-hook 'cider-repl-mode-hook 'ac-cider-compliment-repl-setup)
;; (add-to-list 'ac-modes 'cider-mode)
;; (add-to-list 'ac-modes 'cider-repl-mode)


;; (require 'ac-cider-compliment)
;; (add-hook 'cider-mode-hook 'ac-flyspell-workaround)
;; (add-hook 'cider-mode-hook 'ac-cider-compliment-setup)
;; (eval-after-load "auto-complete"
;;   '(add-to-list 'ac-modes 'cider-mode))

;; (defun set-auto-complete-as-completion-at-point-function ()
;;   (setq completion-at-point-functions '(auto-complete)))
;; (add-hook 'auto-complete-mode-hook 'set-auto-complete-as-completion-at-point-function)

;; (add-hook 'cider-mode-hook 'set-auto-complete-as-completion-at-point-function)



;;(require 'slamhound)
;; seems to be a bug inthe current elpa version 20121227.1032, 
;; it looks for a non-nil value of nrepl-current-connection-buffer to see if it should use nrepl or slime
;; with my version of nrepl (0.1.8-preview) this is always nil
;; this patch seesm to work ok though
;; (defun slamhound ()
;;   "Run slamhound on the current buffer.

;;   Requires active nrepl or slime connection."
;;   (interactive)
;;   (let* ((code (slamhound-clj-string buffer-file-name))
;;          (result (if (and (fboundp 'nrepl-current-connection-buffer) 
;;                           (nrepl-current-connection-buffer))
;;                      (plist-get (nrepl-send-string-sync code) :stdout)
;;                    (first (slime-eval `(swank:eval-and-grab-output ,code))))))
;;     (if (string-match "^:error \\(.*\\)" result)
;;         (error (match-string 1 result))
;;       (goto-char (point-min))
;;       (kill-sexp)
;;       (insert result))))


;; my nrepl customisation

;; (add-hook 'nrepl-connected-hook 
;;   (lambda () (nrepl-set-ns (plist-get
;;                  (nrepl-send-string-sync "(symbol (str *ns*))") :value))))

  
(defun my-select-nrepl-buffer ()
  (interactive)
  (if (string= (cider-current-repl-buffer) (buffer-name))
      (pop-to-buffer (other-buffer (current-buffer) t))      
    (switch-to-buffer-other-window (cider-current-repl-buffer))))

(defun my-run-in-nrepl (str)
  "Run a string in the repl by executing it in the current buffer.
  If output in the mini-buffer is ok use nrepl-interactive-eval instead"
  (interactive)
  (with-current-buffer (get-buffer (cider-current-repl-buffer))
    (goto-char (point-max))    
    (insert str)
    (cider-repl-return)))


(defun my-read-var-name (prompt)
  "read the name of a var with completion"
   (completing-read prompt (ac-nrepl-candidates-vars)
		    nil nil (or (nrepl-sexp-at-point)
				(save-excursion
				  (unless (equal (string (char-before)) " ")
				    (backward-char)
				    (nrepl-sexp-at-point))))))

(defun my-inspect-tree (v)
  "Inspect a var with clojure.inspector/inspect-tree"
  (interactive
   (list 
    (my-read-var-name "Var to inspect: ")))
  (nrepl-interactive-eval (format "(do (require 'clojure.inspector) 
                                     (clojure.inspector/inspect-tree %s))" v)))

(defun my-inspect (v)
  "inspect a var in emacs"
  (interactive
   (list 
    (my-read-var-name "Var to inspect: ")))
  (nrepl-inspect v))


(defun my-load-debug-packages ()
  "Load some commonly used debug packages into the current namespace"
  (interactive)
  (my-run-in-nrepl
   (format "%s"
     '(do 
	  (use 'clojure.pprint)
	  (use 'clojure.inspector)
	(require '[clojure.tools [trace :as tt]])))))

(defun my-clj-gui-diff (a b)
  "Run GUI diff against 2 vars in the repl"
  (interactive
   (list
    (my-read-var-name "lhs var: ")
    (my-read-var-name "rhs var: ")))
  (my-run-in-nrepl (format "(do (require 'gui.diff) 
                              (gui.diff/gui-diff-strings 
                                 (gui.diff/p-str %s) 
                                 (gui.diff/p-str %s)))" a b)))

(defun my-clipboard-eval-handler (buffer)
  "Make an interactive eval handler for BUFFER."
  (nrepl-make-response-handler buffer
                               (lambda (buffer value)
                                 (kill-new value))
                               (lambda (buffer value)
                                 (cider-emit-interactive-output value))
                               (lambda (buffer err)
                                 (message "%s" err)
                                 (cider-highlight-compilation-errors
                                  buffer err))
                               '()))

(defun my-clipboard-eval (form)
  "Evaluate the given FORM and print value in minibuffer."
  (remove-overlays (point-min) (point-max) 'cider-note-p t)
  (let ((buffer (current-buffer)))
    (nrepl-send-string form
                       (my-clipboard-eval-handler buffer)
                       (cider-current-ns))))


(defun my-copy-sym-path () 
  "Copy the full ns & file fo the symbol under the cursor to the clipboard"
  (interactive)
  (my-clipboard-eval 
   (format 
     "(let [i (meta #'%s)] 
          (format \"%%s/%%s (%%s:%%d)\" (:ns i) (:name i) (:file  i) (:line i)))" 
     (cider-symbol-at-point))))

  
(defun my-start-pedestal ()
  (interactive)
  (my-run-in-nrepl
   (format "%s"
	   '(do 
		(use 'dev)
		(start)
	      (watch :development)))))
  
(defun my-toggle-spyscope-at-point ()
  ;; TODO:
  ;; toggle spycope reader macros for the current form
  ;; see https://github.com/dgrnbrg/spyscope
)

;; TODO: include clojure refactoriing support
;; see https://github.com/luckykevin/clojure-refactoring


(defun my-selector-help () 
  (message "nRepl selector:
  r - switch to nRepl buffer (or most recent window in in buffer)
  u - load (use) debugging packages into the current namespace
  i - inspect a variable 
  t - inspect a variable with clojure.inspector/inspect-tree
  g - run gui-diff on two vars
  c - nrepl connection browser
  ? - show this help"))

;; I should convert these to a keymap on clojure/nrepl modes 
(defun my-nrepl-selector (c)
  "Quick launch for a set of clojure/nRepl development tasks"
  (interactive "cn-repl selector [ruitgc?]: ")
  (cond   
   ((= c ?u) (my-load-debug-packages))
   ((= c ?r) (my-select-nrepl-buffer))
   ((= c ?i) (call-interactively 'my-inspect))
   ((= c ?t) (call-interactively 'my-inspect-tree))
   ((= c ?g) (call-interactively 'my-clj-gui-diff))
   ((= c ?c) (nrepl-connection-browser))
   (t (message (concat "unrecognised option: " c))))
)

(defun my-load-default-workgroups () 
  (wg-load "~/.emacs_files/workgroups"))

(defun enable-my-clojure-keys ()
  (interactive)
  (local-set-key (kbd "<f12> u") 'my-load-debug-packages) 
  (local-set-key (kbd "<f12> r") 'my-select-nrepl-buffer ) 
  (local-set-key (kbd "<f12> i") 'my-inspect)
  (local-set-key (kbd "<f12> t") 'my-inspect-tree)
  (local-set-key (kbd "<f12> g") 'my-clj-gui-diff)
  (local-set-key (kbd "<f12> c") 'nrepl-connection-browser)
  (local-set-key (kbd "<f12> p") 'my-start-pedestal)
  (local-set-key (kbd "C-c M-t") 'cider-toggle-trace-var)


  (local-set-key (kbd "M-h") 'mark-sexp)
)


;;(add-hook 'nrepl-mode-hook 'enable-my-clojure-keys)
(add-hook 'cider-mode-hook 'enable-my-clojure-keys)
(add-hook 'clojure-mode-hook 'enable-my-clojure-keys)

;; (global-set-key [f12] (quote my-nrepl-selector))


;; (easy-menu-define my-nrepl-mode-menu (list cider-mode-map nrepl-mode-map clojure-mode-map)
;;   "My menu for nREPL interaction mode")
;; '("My repl"
;;   ["GUI Diff" my-clj-gui-diff]     ;; repl
;;   ["Inspect" my-inspect ]          ;; repl  
;;   ["Inspect Tree" my-inspect-tree] ;; repl
;;   ["iEdit" iedit-mode :keys "C-;"] ;; always
;;   "--"
;;   ["Laptop Frame" 'frame-on-laptop]
;;   "--"
;;   ["Slamhound" 'slamhound]         ;; repl + clojure-mode
;;   "--"
;;   ("Workgroups"
;;    ["Create workgroup" 'wg-create-workgroup ]
;;    ["Switch to workgroup" 'wg-switch-to-workgroup]
;;    ["Rename workgroup" 'wg-rename-workgroup]
;;    ["Revert to base config" 'wg-revert-workgroup]
;;    ["Update base config" 'wg-update-workgroup]
;;    "--"
;;    ["Save workgroups"  'wg-save]
;;    ["Load workgroups"  'my-load-default-workgroups]
;;    )
;;   ("Debugging"
;;    ["Launch ritz repl" 'nrepl-ritz-jack-in]
;;    ["Break on exceptions" 'nrepl-ritz-break-on-exception ]
;;    ["Show threads" 'nrepl-ritz-threads]
;;    ["Set breakpoints" 'ignore :key "C-c C-x X-b"]
;;    )
;;   )

;; troncle adds support for tracing
;;(load-library "troncle")

(provide 'my-clojure)

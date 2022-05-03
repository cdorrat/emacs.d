;; clojure mode settings

(require 'cider)

;;(setq cider-hide-special-buffers t) 
(setq cider-popup-stacktraces-in-repl t)
(setq cider-repl-history-file "~/.emacs.d/nrepl-history")
(setq cider-show-error-buffer 'only-in-repl)
(setq cider-auto-select-error-buffer nil)

;; (require 'ac-cider)
;; (add-hook 'cider-mode-hook 'ac-flyspell-workaround)
;; (add-hook 'cider-mode-hook 'ac-cider-setup)
;; (add-hook 'cider-repl-mode-hook 'ac-cider-setup)
;; (eval-after-load "auto-complete"
;;   '(progn
;;      (add-to-list 'ac-modes 'cider-mode)
;;      (add-to-list 'ac-modes 'cider-repl-mode)))
(add-hook 'cider-mode-hook 'subword-mode)
(add-hook 'clojurescript-mode-hook 'paredit-mode)

;; clj-refactor support
;;(require 'clj-refactor)
;;(require 'cider-hydra)
;;(require 'sayid)
;;(cider-hydra-on)

(defun my-clojure-mode-hook ()
;;    (clj-refactor-mode 1)
    (yas-minor-mode 1) ; for adding require/use/import
    (cljr-add-keybindings-with-prefix "C-c C-m")
    (setq dash-at-point-docset "clojure"))

(add-hook 'clojure-mode-hook #'my-clojure-mode-hook)

;; (require 'sayid)
;; (eval-after-load 'clojure-mode
;;    '(sayid-setup-package))


;; Some default eldoc facilities
(add-hook 'cider-connected-hook
	  (defun pnh-clojure-mode-eldoc-hook ()
	    ;;(add-hook 'cider-mode-hook 'turn-on-eldoc-mode)
	    ;;(add-hook 'cider-repl-mode-hook 'cider-turn-on-eldoc-mode)
	    (cider-enable-on-existing-clojure-buffers)))


;; (defun my-clojure-switch-to-repl  (&optional set-namespace)
;;   "The buffer chosen is based on the file open in the current buffer.  If
;; multiple REPL buffers are associated with current connection the most
;; recent is used.

;; If the REPL buffer cannot be unambiguously determined, the REPL
;; buffer is chosen based on the current connection buffer and a
;; message raised informing the user.

;; Hint: You can use `display-buffer-reuse-frames' and
;; `special-display-buffer-names' to customize the frame in which
;; the buffer should appear.

;; With a prefix arg SET-NAMESPACE sets the namespace in the REPL buffer to that
;; of the namespace in the Clojure source buffer."
;;   (interactive "P")
;;   (let* ((connections (cider-connections))
;;          (type (cider-connection-type-for-buffer))
;; 	 (buffer-dir (clojure-project-dir (file-name-directory buffer-file-name)))
;;          (a-repl)
;;          (the-repl (or
;; 		    (cider-find-connection-buffer-for-project-directory buffer-dir)
;; 		    (seq-find (lambda (b)
;; 				(when (member b connections)
;; 				  (unless a-repl
;; 				    (setq a-repl b))
;; 				  (equal type (cider-connection-type-for-buffer b))))
;; 			      (buffer-list)))))
;;     (if-let* ((repl (or the-repl a-repl)))
;;         (cider--switch-to-repl-buffer repl set-namespace)
;;       (user-error "No REPL found"))))
 
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
   (completing-read prompt nil ;;(ac-nrepl-candidates-vars)
		    nil nil (or (cider-sexp-at-point)
				(save-excursion
				  (unless (equal (string (char-before)) " ")
				    (backward-char)
				    (cider-sexp-at-point))))))

(defun my-inspect-tree (v)
  "Inspect a var with clojure.inspector/inspect-tree"
  (interactive
   (list 
    (my-read-var-name "Var to inspect: ")))
  (cider-interactive-eval (format "(do (require 'clojure.inspector) 
                                     (clojure.inspector/inspect-tree %s))" v)))

(defun my-inspect (v)
  "inspect a var in emacs"
  (interactive
   (list 
    (my-read-var-name "Var to inspect: ")))
  (cider-inspect v))


(defun my-load-debug-packages ()
  "Load some commonly used debug packages into the current namespace"
  (interactive)
  (my-run-in-nrepl
   (format "%s"
     '(do 
	  (use 'clojure.pprint)
	  (use 'clojure.inspector)
	(require '[clojure.tools [trace :as tt]])
	(require '[sc.api :as sapi])))))

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
    (nrepl-request:eval form
			(my-clipboard-eval-handler buffer)
			(cider-current-repl)
			(cider-current-ns))))


(defun my-copy-sym-path () 
  "Copy the full ns & file fo the symbol under the cursor to the clipboard"
  (interactive)
  (my-clipboard-eval 
   (format 
     "(let [i (meta #'%s)] 
          (format \"%%s/%%s (%%s:%%d)\" (:ns i) (:name i) (:file  i) (:line i)))" 
     (cider-symbol-at-point))))

(defun my-browser-ns-at-point ()
  "Browse the clojure namespace at point"
  (interactive)
  (cider-browse-ns
   (cider-symbol-at-point)))

(defun my-qualify-keyword (sym)
  (if (string-match-p "::" sym)
      (replace-regexp-in-string  "::" (concat ":" (clojure-find-ns) "/")  sym)
    sym))

(defun my-browser-spec-at-point ()
  "Browse the clojure namespace at point"
  (interactive)
  (cider-browse-spec
   (my-qualify-keyword (cider-symbol-at-point))))

(defun my-spec-example-at-point ()
  (interactive)
  (my-run-in-nrepl (format "(do 
                              (require 'clojure.spec)
                              (second (first (clojure.spec/exercise s))))"
			   (my-qualify-keyword (cider-symbol-at-point)))))

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

(defun my-figwheel-repl ()
  (interactive)
  (cider-connect "localhost" 7888)  
  (my-run-in-nrepl
   (format "%s"
	   '(do 
		(require '[figwheel-sidecar.repl-api :refer :all])
		(cljs-repl)))))


(defun my-weasel-connect ()
  (interactive)
  (my-run-in-nrepl
   "(do 
     (require '[weasel.repl.websocket])
     (cemerick.piggieback/cljs-repl
       (weasel.repl.websocket/repl-env :ip \"0.0.0.0\" :port 9001)))"))


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
  (local-set-key (kbd "<f12> c") 'sesman-browser)
  (local-set-key (kbd "<f12> f") 'my-figwheel-repl)
  (local-set-key (kbd "<f12> d") 'cider-debug-defun-at-point)
  
  (local-set-key (kbd "C-c M-t") 'cider-toggle-trace-var)
  (local-set-key (kbd "C-c M-o") 'cider-repl-clear-buffer)  
  (local-set-key (kbd "M-h") 'mark-sexp)
  (local-set-key (kbd "C-c C-n") 'my-browser-ns-at-point)
  (local-set-key (kbd "C-c C-s") 'my-browser-spec-at-point))

(defun enable-my-cider-keys ()
  (interactive)
  ;;(define-key cider-mode-map (kbd "C-c C-z") 'my-clojure-switch-to-repl)
  )


;;(add-hook 'nrepl-mode-hook 'enable-my-clojure-keys)
(add-hook 'cider-mode-hook 'enable-my-clojure-keys)
(add-hook 'cider-mode-hook 'enable-my-cider-keys)
(add-hook 'clojure-mode-hook 'enable-my-clojure-keys)
(add-hook 'cider-repl-mode-hook 'enable-my-clojure-keys)


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


(setq cider-cljs-lein-repl
	"(do (require 'figwheel-sidecar.repl-api)
         (figwheel-sidecar.repl-api/start-figwheel!)
         (figwheel-sidecar.repl-api/cljs-repl))")

;; (defun my-clojure-switch-to-repl ()
;;   (interactive)

;;   (let* ((buffer-dir (clojure-project-dir (file-name-directory buffer-file-name)))
;; 	 (repl-dir (clojure-project-dir (cider-current-dir))))
;;     (insert "Project: " buffer-dir "\nRepl: " repl-dir)))

;; my-cider-switch-to-repl-buffer



(provide 'my-clojure)

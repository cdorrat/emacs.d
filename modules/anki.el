;; support for creating Anki cards in emacs

(defgroup anki nil
  "support for adding new facts to Anki."
  :group 'data)

(defcustom anki-mode-hook nil
  "Hook run upon entering anki minor mode."
  :group 'anki
  :type 'hook)

(defcustom anki-default-code-language "R" "The default laguage to use when formatting code samples"
  :group 'anki)

(defcustom anki-cards-file "~/.emacs_files/anki_cards.xml" "The file to keep anki cards in"
  :group 'anki)

(define-minor-mode anki-mode
  "A minor mode for entering Anki facts"      
  nil ;; The initial value.      
  " Anki" ;; The indicator for the mode line.  
  '(("\C-\o" . anki-save-card) ;; The minor mode bindings.
    ("\M-\w" . anki-export-cards)
    ("\C-\q" . (lambda () 
		 (interactive) 
		 (kill-buffer (current-buffer))))) 
  :group 'anki )

(define-minor-mode anki-export-mode
  "A minor mode for displayign the results of an anki export"      
  nil ;; The initial value.      
  " Anki" ;; The indicator for the mode line.  
  '(("q" . (lambda () 
	     (interactive)
	     (kill-buffer (current-buffer)))))
  :group 'anki )

(provide 'anki)

(require 'widget)

(eval-when-compile
  (require 'wid-edit))

(defvar anki-card-vals )

(defun anki-export-cards ()
  (interactive)
  (with-current-buffer (get-buffer-create "*Anki Export*")
    (erase-buffer)    
    (goto-char 0)
    (insert "exporting anki cards with external program ...\n")
    (start-process "anki-export"
		 (current-buffer)
		 "java"
		 "-jar"
		 "/home/cnd/src/clojure/anki_cards/target/anki_cards-0.1.0-SNAPSHOT-standalone.jar"
		 "-i" 
		 (file-truename anki-cards-file))
    (read-only-mode)
    (anki-export-mode))
  (switch-to-buffer "*Anki Export*")
  (message "anki card export started"))


(defun anki--init-cards-file (filename)
 (with-temp-buffer 
   (insert "<cards>\n\n</cards>")
   (append-to-file (point-min) (point-max) filename)))

(defun anki--get-cards-buffer () 
  (when (not (file-exists-p anki-cards-file))
    (anki--init-cards-file anki-cards-file))
  (or 
   (get-buffer "*Anki Cards*")
   (save-excursion
     (set-buffer (find-file-noselect anki-cards-file))
     (rename-buffer "*Anki Cards*"))))

(defun anki-cards-buffer ()
  "Switch to the buffer with the anki cards data"
  (interactive)
  (switch-to-buffer (anki--get-cards-buffer)))

(defun anki--save-card (card-vals)
  (with-current-buffer (anki--get-cards-buffer)
    (goto-char (point-max))
    (backward-sexp 1)
    (insert
     (format "  <card> 
    <front><![CDATA[%s]]></front>
    <back><![CDATA[%s]]></back>
    <code class=\"code\" language=\"%s\"><![CDATA[%s]]></code>
  </card>\n"
	     (gethash :front card-vals "")
	     (gethash :back card-vals "")
	     (gethash :language card-vals "") 
	     (gethash :code card-vals "")))
    (save-buffer)))


(defun anki-save-card () 
  "Save the current fact to the anki cards file"
  (interactive)
  (anki--save-card anki-card-vals)
  (anki-add-fact))


(defun anki-add-fact ()
  "Create the widgets from the Widget manual."
  (interactive)

  ;; Bug - need to switch to an existing window if ones visible, otherwise create a new one
  (switch-to-buffer (get-buffer-create "*Anki Fact*"))

  (kill-all-local-variables)
  (make-local-variable 'anki-card-vals)
  (anki-mode)
  (setq anki-card-vals (make-hash-table :test 'equal))
  (puthash :language "R" anki-card-vals)
  
  (let ((inhibit-read-only t))
    (erase-buffer))  
  (remove-overlays)

  (widget-insert "\nEnter the new fact (may use markdown).\n\n")
  
  (widget-create 'text
		 :format "Front: %v\n" ; Text after the field!
		 :tab-order 1
		 :notify (lambda (w &rest ignore)
			   (puthash :front (widget-value w) anki-card-vals))
		 "")

  (widget-create 'text
		 :format "Back : %v\n" ; Text after the field!
		 :tab-order 2
		 :notify (lambda (w &rest ignore)
			   (puthash :back (widget-value w) anki-card-vals))
		 "")

  (widget-create 'text
		 :format "Code: %v\n" ; Text after the field!
		 :tab-order 3
		 :notify (lambda (w &rest ignore)
			   (puthash :code (widget-value w) anki-card-vals))
		 "")

  (widget-create 'menu-choice
		 :format "Language: %v \n" ; Text after the field!
		 :tag "Language"
		 :tab-order -1
		 :notify (lambda (w &rest ignore)
			   (puthash :language (widget-value w) anki-card-vals))
		 :value anki-default-code-language
		 :help-echo "Langauge used for syntax highlighting"
		 '(choice-item "R")
		 '(choice-item "Clojure")
		 )

  (widget-create 'push-button
		 :notify (lambda (&rest ignore)			   
			   (anki--save-card anki-card-vals)
			   (anki-add-fact))
		 :tab-order 4
		 "Save")
  (widget-insert " ")
  (widget-create 'push-button
		 :notify (lambda (&rest ignore)
			   (anki-export-cards))
		 :tab-order 5
		 "Export Cards")

  (widget-insert " ")
  (widget-create 'push-button
		 :tab-order 6
		 :notify (lambda (&rest ignore)
			   (kill-buffer (current-buffer)))
		 "Quit")

  (widget-insert "\n")
  (use-local-map widget-keymap)  
  (widget-setup)
  (goto-char 0)
  (widget-forward 1))



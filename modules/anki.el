;; support for creating Anki cards in emacs

(require 'widget)

(eval-when-compile
  (require 'wid-edit))

(defcustom anki-default-code-language "R" "The default laguage to use when formatting code samples")
(defcustom anki-cards-file "~/.emacs_files/anki_cards.xml" "The file to keep anki cards in")

(defvar anki-card-vals )

(defun anki--init-cards-file (filename)
  ;; create a new empty cards file
  (message "TODO: we dont create empty cards files yet"))

(defun anki--get-cards-buffer () 
  (when (not (file-exists-p anki-cards-file))
    (anki--init-cards-file anki-cards-file))
  (find-file-noselect anki-cards-file))
  

(defun anki--save-card (card-vals)
  (message "save a fact..")  
  (message (concat (gethash :front card-vals) ", "
		   (gethash :back card-vals) ", "
		   (gethash :code card-vals) ", "            
		   (gethash :language card-vals)))
  (with-current-buffer (anki--get-cards-buffer)
    (goto-char (point-max))
    (backward-sexp 1)
    (insert
     (format "  <card> 
    <front><![CDATA[%s]]></front>
    <back><![CDATA[%s]]></back>
    <code language=\"%s\"><![CDATA[%s]]></code>
  </card>\n"
	     (gethash :front card-vals)
	     (gethash :back card-vals)
	     (gethash :language card-vals) 
	     (gethash :code card-vals)))
    (save-buffer)))


(defun anki-add-fact ()
  "Create the widgets from the Widget manual."
  (interactive)
  (switch-to-buffer "*Anki Fact*")
  (kill-all-local-variables)
  (make-local-variable 'anki-card-vals)
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
		 " ")

  (widget-create 'text
		 :format "Back : %v\n" ; Text after the field!
		 :tab-order 2
		 :notify (lambda (w &rest ignore)
			   (puthash :back (widget-value w) anki-card-vals))
		 " ")

  (widget-create 'text
		 :format "Code: %v\n" ; Text after the field!
		 :tab-order 3
		 :notify (lambda (w &rest ignore)
			   (puthash :code (widget-value w) anki-card-vals))
		 " ")

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
			   (anki--save-card anki-card-vals)
			   (kill-buffer (current-buffer)))
		 :tab-order 5
		 "Save & Quit")

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
  (widget-forward 1)
)

(provide 'anki)


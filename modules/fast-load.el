(provide 'fast-load)

(require 'ido)

(defvar xah-filelist nil "alist for files i need to open frequently. Key is a short abbrev, Value is file path.")

(setq xah-filelist
      '(
        ("todo" . "~/todo.txt" )
        ("init" . "~/.emacs.d/init.el" )
        ("project" . "~/src/clojure/quelea-racing/project.clj" )
	("lein" . "~/.lein/profiles.clj")
        ("src" . "~/src/" )
        ;; more here
        ))

(defun xah-open-file-fast (openCode)
  "Prompt to open a file from a pre-defined set."
  (interactive
   (list (ido-completing-read "Open:" (mapcar (lambda (x) (car x)) xah-filelist)))
   )
  (find-file (cdr (assoc openCode xah-filelist)) ))


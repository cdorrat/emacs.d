
(require 'seq)

(defun read-lines (filePath)
  "Return a list of lines of a file at filePath."
  (with-temp-buffer
    (insert-file-contents filePath)
    (split-string (buffer-string) "\n" t)))



(defun env-from-file (path)
  (interactive "f")
    (seq-doseq (l (read-lines path))
      (cl-multiple-value-bind (k v) (split-string (s-trim l) "=")
	(when v
	  ;; (setenv k v)
    	  (print (concat k "=<>=" v "\n"))))))

  

(env-from-file "~/work/cogent/agent-reach-ad-publisher/dist/.env")
(provide 'file-env)





(require 'chatgpt-arcana)

;; clone https://github.com/cdorrat/chatgpt-arcana.el.git in the modules dir

(defun my-read-env-file (filename)
  "Reads environment variables from a file and sets them in the current process."
  (interactive "fEnter file name: ")
  (when (file-exists-p filename)
    (with-temp-buffer
      (insert-file-contents filename)
      (while (not (eobp))
        (let* ((line (thing-at-point 'line))
               (parts (split-string line "=" nil "\n"))
               (key (car parts))
               (value (cadr parts)))
          (when (and key value)
            (setenv key value)))
        (forward-line)))))

(my-read-env-file "~/.openai")
(setq chatgpt-arcana-api-key (getenv "OPENAI_API_KEY"))


(defun my-gpt-add-prog-prompt (mode lang)
  (add-to-list 'chatgpt-arcana-system-prompts-modes-alist `(,mode . ,mode))
  (add-to-list 'chatgpt-arcana-system-prompts-alist
	       `(,mode . ,(format
			   "You are an expert professional %s programmer. \
You may only respond with concise code only and no explanation unless explicitly asked. " lang))))

(my-gpt-add-prog-prompt 'clojure-mode "Clojure")
(my-gpt-add-prog-prompt 'clojurescript-mode "Clojurescript")
(my-gpt-add-prog-prompt 'python-mode "Python")
(my-gpt-add-prog-prompt 'go-mode "Golang")
(my-gpt-add-prog-prompt 'emacs-lisp-mode "Emacs")

(defun my-chatgpt-code-replace-region (prompt)
  "Send the selected region to the OpenAI API with PROMPT and
replace the region with the output."
  (interactive "sPrompt: ")
  (let ((selected-region (buffer-substring-no-propterties (mark) (point))))
    (let ((modified-region (chatgpt-arcana--query-api-alist `(((role . "system") (content . ,(chatgpt-arcana-get-system-prompt) ))
							     ((role . "user") (content . ,(concat  "\n" prompt " " selected-region)))))))
      (delete-region (mark) (point))
      (insert modified-region))))

(provide 'my-chatgpt)

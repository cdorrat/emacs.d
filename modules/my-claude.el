
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))

;; install required inheritenv dependency:
(use-package inheritenv
  :vc (:url "https://github.com/purcell/inheritenv" :rev :newest))

(use-package monet
  :vc (:url "https://github.com/stevemolitor/monet" :rev :newest))

;; for eat terminal backend:
(use-package eat :ensure t)

;; for vterm terminal backend:
(use-package vterm :ensure t)

;; install claude-code.el
(use-package claude-code :ensure t
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
  :config
  ;; optional IDE integration with Monet
;;  (add-hook 'claude-code-process-environment-functions #'monet-start-server-function)
;;  (monet-mode 1)

  (claude-code-mode)
  :bind-keymap ("C-c c" . claude-code-command-map)

  ;; Optionally define a repeat map so that "M" will cycle thru Claude auto-accept/plan/confirm modes after invoking claude-code-cycle-mode / C-c M.
  :bind
  (:repeat-map my-claude-code-map ("M" . claude-code-cycle-mode)))

(defun my-claude-notify (title message)
  "Display a macOS notification with sound."
  (start-process "notify" nil "osascript"
                 "-e" (format "display notification %S with title %S sound name \"Glass\""
                              message title)))

(setq claude-code-notification-function #'my-claude-notify)


(load-file "/Users/cdorrat/.emacs.d/elpa/claude-code/examples/hooks/claude-code-auto-revert-hook.el")

(setup-claude-auto-revert)

(add-hook 'claude-code-process-environment-functions #'monet-start-server-function)
(monet-mode 1)

;; Load org-mode integration for managing Claude instances from org documents
(require 'claude-org)

;; Load Claude session list mode
(require 'claude-buffer-list)

(use-package pretty-hydra :ensure t)

(pretty-hydra-define my/claude-hydra
  (:title "Claude" :quit-key "q" :color blue)
  ("Instance"
   (("c" claude-code "start/open")
    ("n" claude-code-new-instance "new instance")
    ("d" claude-code-start-in-directory "start in dir")
    ("r" claude-code-resume "resume")
    ("C" claude-code-continue "continue")
    ("s" claude-code-select-buffer "select buffer")
    ("t" claude-code-toggle "toggle"))
   "Send"
   (("p" claude-org-send-to-claude "send prompt")
    ("e" claude-code-send-command "send command")
    ("w" claude-code-send-command-with-context "send with context")
    ("R" claude-code-send-region "send region")
    ("f" claude-code-send-buffer-file "send file"))
   "Control"
   (("m" claude-code-cycle-mode "cycle mode")
    ("F" claude-code-fork "fork")
    ("o" claude-code-toggle-read-only-mode "read-only")
    ("x" claude-code-send-escape "escape")
    ("/" claude-code-slash-commands "slash commands"))
   "Manage"
   (("k" claude-code-kill "kill instance")
    ("K" claude-code-kill-all "kill all")
    ("l" claude-buffer-list "list sessions"))
   "Org"
   (("/" claude-org-send-to-claude "send at point")
    ("<f9>" claude-org-magit-status "magit at point")
    )
   ))

(define-key org-mode-map (kbd "C-/") #'claude-org-send-to-claude)
(define-key org-mode-map (kbd "<f9>") #'claude-org-magit-status)

(provide 'my-claude)

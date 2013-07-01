;;; fiplr-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (fiplr-clear-cache fiplr-find-directory fiplr-find-file
;;;;;;  fiplr-root) "fiplr" "fiplr.el" (20918 40856 0 0))
;;; Generated autoloads from fiplr.el

(autoload 'fiplr-root "fiplr" "\
Locate the root of the project by walking up the directory tree.

\(fn)" nil nil)

(autoload 'fiplr-find-file "fiplr" "\
Runs a completing prompt to find a file from the project.

\(fn)" nil nil)

(autoload 'fiplr-find-directory "fiplr" "\
Runs a completing prompt to find a directory from the project.

\(fn)" nil nil)

(autoload 'fiplr-clear-cache "fiplr" "\
Clears the internal caches used by fiplr so the project is searched again.

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("fiplr-pkg.el") (20918 40856 962223 19000))

;;;***

(provide 'fiplr-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; fiplr-autoloads.el ends here

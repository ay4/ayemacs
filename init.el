;; ──────────────────────────────────────────
;; Package Manager — straight.el
;; ──────────────────────────────────────────

;; Bootstrap straight.el: a declarative, git-based package manager that
;; installs packages from source and ensures reproducible setups.

;; Only check for package modifications on file save, not every startup.
;; This eliminates the ~0.2s git-check overhead that dominates init time.
(setq straight-check-for-modifications '(check-on-save find-when-checking))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))


;; ──────────────────────────────────────────
;; Early Packages
;; ──────────────────────────────────────────

;; Must be loaded before config.el uses use-package / general-define-key
(straight-use-package 'use-package)
(straight-use-package 'org)
(straight-use-package 'general)
(straight-use-package 'esup)


;; ──────────────────────────────────────────
;; Performance
;; ──────────────────────────────────────────

(setq gc-cons-threshold 100000000)
(setq read-process-output-max (* 1024 1024))
(defvar ay/startup-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'after-init-hook
  (lambda ()
    (setq gc-cons-threshold 800000)
    (setq file-name-handler-alist ay/startup-file-name-handler-alist)))


;; ──────────────────────────────────────────
;; Infrastructure
;; ──────────────────────────────────────────

;; Fix TLS 1.3 handshake failures in Emacs < 26.3
(when (version< emacs-version "26.3")
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

;; Redirect Emacs's auto-generated settings to a separate file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(unless (file-exists-p custom-file) (write-region "" nil custom-file))
(load custom-file nil t)

;; Redirect all backups and auto-saves to /tmp
(defconst emacs-tmp-dir
  (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory))
(setq backup-by-copying t
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t
      auto-save-list-file-prefix emacs-tmp-dir
      auto-save-file-name-transforms `((".*" ,emacs-tmp-dir t))
      backup-directory-alist `((".*" . ,emacs-tmp-dir)))

;; Disable lock files
(setq create-lockfiles nil)


;; Suppress "For information about GNU Emacs..." echo area message.
;; Must be a literal string in init.el — Emacs scans for it before eval.
(setq inhibit-startup-echo-area-message "ay4")


;; ──────────────────────────────────────────
;; Load Config
;; ──────────────────────────────────────────

(load (expand-file-name "config.el" user-emacs-directory) nil t)

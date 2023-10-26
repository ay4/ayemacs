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

(straight-use-package 'use-package)
(straight-use-package 'org)

(setq gc-cons-threshold 100000000)
(setq read-process-output-max (* 1024 1024)) ;; 1mb
(add-hook 'after-init-hook #'(lambda ()
       ;; restore after startup
       (setq gc-cons-threshold 800000)))

(when (version< emacs-version "26.3")
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(unless (file-exists-p custom-file)
  (write-region "" nil custom-file))
(load custom-file nil t)

(defconst emacs-tmp-dir (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory))
(setq
   backup-by-copying t                                        ; Avoid symlinks
   delete-old-versions t
   kept-new-versions 6
   kept-old-versions 2
   version-control t
   auto-save-list-file-prefix emacs-tmp-dir
   auto-save-file-name-transforms `((".*" ,emacs-tmp-dir t))  ; Change autosave dir to tmp
   backup-directory-alist `((".*" . ,emacs-tmp-dir)))

(setq create-lockfiles nil)

(add-to-list 'default-frame-alist '(fullscreen . maximized))
(setq ns-pop-up-frames nil)

(if (not custom-enabled-themes)
    (load-theme 'wheatgrass t))

(defun open-inbox ()
  (interactive)
  (find-file "/Users/neiaglov/infogarden/inbox.org")
  (end-of-buffer))

(defun set-exec-path-from-shell-PATH ()
  (interactive)
  (let ((path-from-shell (replace-regexp-in-string
			  "[ \t\n]*$" "" (shell-command-to-string
					  "$SHELL --login -c 'echo $PATH'"
						    ))))
    (setenv "PATH" path-from-shell)
    (setq exec-path (split-string path-from-shell path-separator))))

(set-exec-path-from-shell-PATH)

(defun reload-config ()
  (interactive)
  (load-file (expand-file-name "init.el" user-emacs-directory)))

(defun my-write-copy-to-file ()
  "Write a copy of the current buffer or region to a file."
  (interactive)
  (let* ((curr (buffer-file-name))
         (new (read-file-name
               "Copy to file: " nil nil nil
               (and curr (file-name-nondirectory curr))))
         (mustbenew (if (and curr (file-equal-p new curr)) 'excl t)))
    (if (use-region-p)
        (write-region (region-beginning) (region-end) new nil nil nil mustbenew)
      (save-restriction
        (widen)
        (write-region (point-min) (point-max) new nil nil nil mustbenew)))))

(defun generate-config-and-reload ()
"Generate the init.el and load it again."
(interactive)
(org-babel-tangle)
(reload-config)
)

(defun close-win-kill-buf ()
  "Simple close the window and kill the buffer in it."
  (interactive)
  (kill-buffer)
  (delete-window))

(defun isearch-from-buffer-start ()
  (interactive)
  (goto-char (point-min))
  (isearch-forward))

(defun what-face (pos)
    (interactive "d")
        (let ((face (or (get-char-property (point) 'read-face-name)
            (get-char-property (point) 'face))))
    (if face (message "Face: %s" face) (message "No face at %d" pos))))

(use-package reverse-im
  :straight t
  :custom
  (reverse-im-input-methods
   '("russian-computer"))
  :config
  (reverse-im-mode t))

(defalias 'open-file 'find-file)
(defalias 'save-file 'save-buffer)
(defalias 'close-window 'delete-window)
(defalias 'close-file 'kill-buffer)
(defalias 'generate-config 'org-babel-tangle)

(if (fboundp 'menu-bar-mode)
    (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode)
    (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

(set-face-attribute 'default nil :font "Victor Mono")
(set-face-attribute 'default nil :height 140)

(setq shr-use-fonts nil)

(straight-use-package 'nord-theme)
(straight-use-package 'gruvbox-theme)
(straight-use-package 'solarized-theme)
(straight-use-package 'ayu-theme)
(straight-use-package 'catppuccin-theme)
;(load-theme 'nord t)
;(load-theme 'solarized-dark t)
;(load-theme 'solarized-light t)
;(load-theme 'ayu-dark t)
;(load-theme 'ayu-grey t)
;(load-theme 'ayu-light t)
;(load-theme 'gruvbox-dark-medium  t)
;(load-theme 'gruvbox-dark-soft t)
(load-theme 'catppuccin t)
(setq catppuccin-flavor 'frappe)
;(load-theme 'gruvbox-dark-hard t)
;(load-theme 'gruvbox-light-medium t)
;(load-theme 'gruvbox-light-soft t)
;(load-theme 'gruvbox-light-hard t)

(set-face-background 'internal-border (face-attribute 'default :background))
(set-face-background 'fringe (face-attribute 'default :background))
(set-frame-parameter nil 'internal-border-width 40)

(defun setup-frame (frame)
  (with-selected-frame frame
    (set-frame-parameter nil 'internal-border-width 40)))

(add-hook 'after-make-frame-functions #'setup-frame)

(straight-use-package 'visual-fill-column)
(setq-default visual-fill-column-center-text t)
(setq-default visual-fill-column-enable-sensible-window-split t)
(advice-add 'text-scale-adjust :after #'visual-fill-column-adjust)
(add-hook 'visual-line-mode-hook #'visual-fill-column-mode)
(global-visual-line-mode 1)

(straight-use-package 'dimmer)
'(dimmer-adjustment-mode :both)
'(dimmer-fraction 1.0)
(add-hook 'after-init-hook (lambda ()
     (when (fboundp 'dimmer-mode)
       (dimmer-mode t))))

'(window-divider-default-bottom-width 1)
'(window-divider-default-places t)
'(window-divider-default-right-width 1)
'(window-divider-mode t)

(global-display-line-numbers-mode 0)

(setq-default mode-line-format nil)

(setq-default cursor-type 'box)

(setq inhibit-startup-screen t)

(setq initial-scratch-message "")

(setq-default frame-title-format '("%b"))

(setq ring-bell-function 'ignore)

(fset 'yes-or-no-p 'y-or-n-p)

(delete-selection-mode 1)

(global-auto-revert-mode t)

(electric-indent-mode -1)

(straight-use-package 'telega)
(setq telega-use-images 1)

(straight-use-package 'org-mac-link)

(straight-use-package 'general)

(use-package undo-tree
  :straight t
  :init (global-undo-tree-mode)
  :config (setq-default undo-tree-auto-save-history nil))
(add-hook 'before-save-hook
    'delete-trailing-whitespace)

(straight-use-package 'vertico)
(vertico-mode t)
(straight-use-package 'consult)
(global-set-key [rebind switch-to-buffer] #'consult-buffer)

(cua-mode t)

(straight-use-package 'all-the-icons)

(straight-use-package 'which-key)
(which-key-mode)
(setq which-key-idle-delay 0)

(straight-use-package 'avy)
(setq avy-keys '(?i ?e ?a ?h))
(setq avy-background t)

(straight-use-package 'nov)
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
(setq nov-variable-pitch nil)

;(add-to-list 'load-path "~/.emacs.d")
(straight-use-package 'vterm)
(add-hook 'vterm-mode-hook (lambda() visual-line-mode -1))

(general-define-key
:keymaps 'nov-mode-map
"SPC" nil "S-SPC" nil "q" nil "w" nil "s" nil "a" nil "d" nil "[" nil "]" nil "t" nil "l" nil "r" nil "<left>" nil "<right>" nil "<up>" nil "<down>" nil
)
(general-define-key
:keymaps 'nov-mode-map
"SPC" 'nov-scroll-up
"s" 'nov-scroll-up
"S-SPC" 'nov-scroll-down
"w" 'nov-scroll-down
"<home>" 'nov-goto-toc
"a" 'nov-previous-document
"d" 'nov-next-document
)

(general-define-key "s-s" nil "C-x h" nil "C-a" nil "C-e" nil "C-x <right>" nil "C-x C-c" nil "C-g" nil "s-o" nil "M-w" nil "s-q" nil)
(general-define-key
:keymaps 'isearch-mode-map
"C-c" nil "C-v" nil "C-x <timeout>" nil "C-z" nil)
(general-define-key
:keymaps 'cua--cua-keys-keymap
"C-c <timeout>" nil "<escape>" nil "<return>" nil)

(general-define-key
"s-p" 'execute-extended-command
"s-s" 'save-buffer
;"s-q" 'kill-emacs
"s-q" 'save-buffers-kill-terminal

)

(general-define-key "s-f" 'isearch-from-buffer-start)
(general-define-key
:keymaps 'isearch-mode-map
"<return>" 'isearch-repeat-forward
"<escape>" 'isearch-exit
)

(general-define-key "s-a" 'mark-whole-buffer)
(general-define-key
:keymaps 'cua--cua-keys-keymap
"s-c" 'copy-region-as-kill
"s-v" 'yank
"s-x" 'kill-region
"s-z" 'undo
)
(general-define-key
"s-<left>" 'move-beginning-of-line
"s-<right>" 'move-end-of-line
"s-l" 'avy-goto-line
)

(general-define-key
"s-t" 'split-window-right
"s-T" 'split-window-below
"s-{" 'previous-multiframe-window
"s-}" 'next-multiframe-window
"s-w" 'close-win-kill-buf
"M-w" 'delete-other-windows
)

(general-define-key
:keymaps 'minibuffer-local-map
"<escape>" 'abort-recursive-edit
)

(defconst ayleader "s-o")
  (general-define-key
  :prefix ayleader
  :wk-full-keys nil
  "b" '(:prefix-command aybuffer-map :which-key "buffers")
  "f" '(:prefix-command ayfile-map :which-key "files")
  "a" '(:prefix-command ayapp-map :which-key "apps")
  "s" '(:prefix-command aysystem-map :which-key "system")
  "v" '(:prefix-command aytoo-map :which-key "view")
  "s-o" '(open-inbox :which-key "open inbox")
  "t" '(:keymap telega-prefix-map :which-key "telegram")
)

(general-define-key
:keymaps 'aytoo-map
:wk-full-keys nil
"w" '(visual-fill-column-mode :which-key "wide")
"n" '(global-display-line-numbers-mode :which-key "line numbers")
)

(general-define-key
:keymaps 'aybuffer-map
:wk-full-keys nil
"l" '(switch-to-buffer :which-key "list buffers")
"p" '(previous-buffer :which-key "previous buffer")
"n" '(next-buffer :which-key "next buffer")
"<left>" '(previous-buffer :which-key "previous buffer")
"<right>" '(next-buffer :which-key "next buffer")
)

(general-define-key
:keymaps 'ayfile-map
:wk-full-keys nil
"s" '(save-buffer :which-key "save file")
"n" '(switch-to-buffer :which-key "new file")
"o" '(find-file :which-key "open file")
"a" '(my-write-copy-to-file :which-key "save as")
)

(general-define-key
:keymaps 'aysystem-map
:wk-full-keys nil
"c" '((lambda()(interactive)(find-file "~/.emacs.d/README.org")) :which-key "open config")
"r" '(generate-config-and-reload :which-key "generate config and reload it")
)

(general-define-key
:keymaps 'ayapp-map
:wk-full-keys nil
"t" '(shell :which-key "terminal")
"l" '(org-mac-link-get-link :which-key "get open links")
"b" '(eww :which-key "browser")
)

(general-define-key
:prefix ayleader
:keymaps 'org-mode-map
:major-modes t
:wk-full-keys nil
"i" '(:prefix-command ayorg-insert-map :which-key "insert")
)

(general-define-key
:keymaps 'ayorg-insert-map
:major-modes 'org-mode
:wk-full-keys nil
"h" '(:prefix-command ayorg-insert-header-map :which-key "header")
"d" '((lambda()(interactive)(insert (shell-command-to-string "echo -n $(date +%d.%m.%Y)"))) :which-key "Current date")
"t" '((lambda()(interactive)(insert "***** TODO")) :keymaps 'ayorg-insert-map :which-key "todogram")

)

(general-define-key
:keymaps 'ayorg-insert-header-map
:major-modes t
:wk-full-keys nil
"1" '((lambda()(interactive)(insert "* ")) :which-key "H1")
"2" '((lambda()(interactive)(insert "** ")) :which-key "H2")
"3" '((lambda()(interactive)(insert "*** ")) :which-key "H3")
"4" '((lambda()(interactive)(insert "**** ")) :which-key "H4")
"5" '((lambda()(interactive)(insert "***** ")) :which-key "H5")
)

(defun applauncher ()
  "Run external apps"
(interactive)
(require 'subr-x)
(start-process "Temp" "Temp" (string-trim-right (read-shell-command "→  "))))

(defun launch-browser ()
"Run Nyxt"
(interactive)
(start-process "Temp" "Temp" "nyxt"))

(define-key global-map (kbd "M-SPC") nil)
(define-key global-map (kbd "M-SPC") '("Run commands" . applauncher))

(setq-default line-spacing 4)

(with-eval-after-load "org"

(customize-set-variable 'org-blank-before-new-entry
                        '((heading . nil)
                          (plain-list-item . nil)))
(setq org-cycle-separator-lines 1)

(add-hook 'org-mode-hook 'org-indent-mode)

(require 'org-tempo)

(general-define-key
:keymaps 'org-mode-map
"M-S-<left>" nil
"M-S-<right>" nil
"M-<left>" nil
"M-<right>" nil
"S-<left>" nil
"S-<right>" nil
"S-<up>" nil
"S-<down>" nil
"t" nil
)

(setq org-support-shift-select 1)

(general-define-key
:keymaps 'org-mode-map
"M-<down>" 'org-shiftright
"M-<up>" 'org-shiftleft
"s-]" 'org-metaright
"s-[" 'org-metaleft
)

(general-define-key
:keymaps 'org-mode-map
"s-<return>" 'org-open-at-point
)

(general-define-key
:keymaps 'org-mode-map
"s-b" (lambda() (interactive) (org-emphasize ?\*))
"s-i" (lambda() (interactive) (org-emphasize ?\/))
"s-k" 'org-insert-link
)

(straight-use-package 'org-appear)
(setq org-appear-autoemphasis 1)
(setq org-hide-emphasis-markers 1)
(setq org-appear-autolinks 1)
(add-hook 'org-mode-hook 'org-appear-mode)

)

(setq-default major-mode
              (lambda () ; guess major mode from file name
                (unless buffer-file-name
                  (let ((buffer-file-name (buffer-name)))
                    (set-auto-mode)))))
(setq confirm-kill-emacs #'yes-or-no-p)
(setq window-resize-pixelwise t)
(setq frame-resize-pixelwise t)
(save-place-mode t)
(savehist-mode t)
(recentf-mode t)
(defalias 'yes-or-no #'y-or-n-p)

(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

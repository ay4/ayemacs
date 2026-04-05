;; editing.el — Text editing behaviour and language modes
;;
;; Contents:
;;   - Indentation (tabs → spaces, 4-wide)
;;   - Russian keybindings (reverse-im)
;;   - Smooth scrolling
;;   - Undo / redo (undo-tree)
;;   - Which-key (keybinding popup)
;;   - Ivy / Counsel (completion framework)
;;   - Org mode (indent, folding, shift-select)
;;   - Markdown mode (folding, ay-markdown-indent-mode)
;;   - Typewriter mode (cursor centered, scroll-margin 999 + topspace)
;;   - Olivetti (center mode — horizontal body centering)
;;   - Visual line mode (word-wrap globally)


;; ──────────────────────────────────────────
;; Indentation
;; ──────────────────────────────────────────

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq tab-stop-list (number-sequence 4 200 4))
(general-define-key "TAB" 'tab-to-tab-stop)


;; ──────────────────────────────────────────
;; Russian Keybindings
;; ──────────────────────────────────────────

;; reverse-im: all keybindings keep working when the Russian input method is active
(use-package reverse-im
  :straight t
  :custom (reverse-im-input-methods '("russian-computer"))
  :config (reverse-im-mode t))


;; ──────────────────────────────────────────
;; Smooth Scrolling
;; ──────────────────────────────────────────

;; Scroll one line at a time instead of jumping half a page
(setq scroll-step 1)
;; scroll-conservatively and pixel-scroll-precision-mode are managed by
;; ay-typewriter-mode below: centering requires both to be off/zero.
;; When typewriter mode is off, pixel-scroll and conservatively=10000 are restored.
(pixel-scroll-precision-mode 1)
(setq scroll-conservatively 10000)


;; ──────────────────────────────────────────
;; Undo / Redo
;; ──────────────────────────────────────────

;; undo-tree: branching undo/redo tree, C-x u opens visual browser
(use-package undo-tree
  :straight t
  :init (global-undo-tree-mode)
  :config (setq-default undo-tree-auto-save-history nil))

(general-define-key "M-z" 'undo-tree-redo)


;; ──────────────────────────────────────────
;; Which-key
;; ──────────────────────────────────────────

;; :defer 0.5 — loads after 0.5s idle, not needed in the first moment
(use-package which-key
  :straight t
  :defer 0.5
  :config
  (setq which-key-idle-delay 0)
  (which-key-mode))


;; ──────────────────────────────────────────
;; Ivy / Counsel
;; ──────────────────────────────────────────

;; ivy: incremental narrowing completion framework — replaces the default
;; completing-read with a live-filtered vertical list.
(use-package ivy
  :straight t
  :config
  (setq ivy-use-virtual-buffers t)   ; include recent files in buffer list
  (setq ivy-count-format "(%d/%d) ") ; show match count
  (setq ivy-wrap t)                  ; wrap around at top/bottom
  (setq ivy-height 15)               ; show 15 candidates
  (setq ivy-initial-inputs-alist nil) ; don't pre-fill ^ in searches
  (ivy-mode 1)
  ;; Escape closes the minibuffer (consistent with global ESC = keyboard-quit)
  (define-key ivy-minibuffer-map (kbd "<escape>") 'minibuffer-keyboard-quit))

;; counsel: ivy-powered replacements for common Emacs commands (find-file, M-x, etc.)
(use-package counsel
  :straight t
  :after ivy
  :config
  (counsel-mode 1))


;; ──────────────────────────────────────────
;; Org Mode
;; ──────────────────────────────────────────

;; org-indent-mode: visually shifts sub-headings and body text rightward
;; org-cycle via TAB: folds/unfolds heading sections
;; indentation-per-level 3: matches markdown indent width
(use-package org
  :straight t
  :hook ((org-mode . org-indent-mode))
  :custom
  (org-indent-indentation-per-level 3)
  (org-support-shift-select t)
  :config
  (general-define-key :keymaps 'org-mode-map "TAB" 'org-cycle)
  ;; Force entire org buffer to use the default monospace font
  (add-hook 'org-mode-hook
            (lambda () (face-remap-add-relative 'default 'fixed-pitch)))
  ;; Disable topspace in org — org-indent-mode overlays conflict with auto-centering
  (add-hook 'org-mode-hook (lambda () (topspace-mode -1))))


;; ──────────────────────────────────────────
;; Markdown Mode
;; ──────────────────────────────────────────

;; markdown-cycle via TAB: folds/unfolds heading sections
;; :defer t — only loads when a .md file is opened
(use-package markdown-mode
  :straight t
  :defer t
  :config
  (general-define-key :keymaps 'markdown-mode-map "TAB" 'markdown-cycle))

;; ay-markdown-indent-mode: visual indentation by heading level,
;; like org-indent-mode. Shifts content rightward using line-prefix
;; and wrap-prefix text properties based on the parent heading depth.
(defvar ay-markdown-indent-width 3
  "Columns of visual indentation per heading level.")

(defun ay--markdown-indent-fontify (beg end)
  "Set line-prefix and wrap-prefix between BEG and END by heading level."
  (with-silent-modifications
    (save-excursion
      (goto-char beg)
      (setq beg (line-beginning-position))
      (goto-char end)
      (setq end (line-end-position))
      (goto-char beg)
      (let ((level 0))
        (save-excursion
          (when (re-search-backward "^\\(#\\{1,6\\}\\) " nil t)
            (setq level (- (match-end 1) (match-beginning 1)))))
        (while (and (<= (point) end) (not (eobp)))
          (when (looking-at "\\(#\\{1,6\\}\\) ")
            (setq level (- (match-end 1) (match-beginning 1))))
          (let* ((indent (* (max 0 (1- level)) ay-markdown-indent-width))
                 (prefix (make-string indent ?\s))
                 (eol (min (1+ (line-end-position)) (point-max))))
            (put-text-property (point) eol 'line-prefix prefix)
            (put-text-property (point) eol 'wrap-prefix prefix))
          (forward-line 1))))))

(define-minor-mode ay-markdown-indent-mode
  "Visually indent markdown content by heading level."
  :lighter nil
  (if ay-markdown-indent-mode
      (progn
        (jit-lock-register #'ay--markdown-indent-fontify)
        (ay--markdown-indent-fontify (point-min) (point-max)))
    (jit-lock-unregister #'ay--markdown-indent-fontify)
    (with-silent-modifications
      (remove-text-properties (point-min) (point-max)
                              '(line-prefix nil wrap-prefix nil)))))

(add-hook 'markdown-mode-hook #'ay-markdown-indent-mode)


;; ──────────────────────────────────────────
;; Typewriter Mode
;; ──────────────────────────────────────────

;; topspace: adds virtual scrollable space above line 1, so the first
;; line can be centered on screen by scroll-margin (typewriter mode).
;; Without this, scroll-margin can't push line 1 past the window top.
(use-package topspace
  :straight t
  :config
  (setq topspace-autocenter-buffers t)
  (setq topspace-center-position 0.5))

;; Typesetter mode — cursor always vertically centered.
;; Root cause of all previous failures: Emacs bug#66769 — pixel-scroll-precision-mode
;; conflicts with scroll-margin in Emacs 30, intercepting scroll events before
;; scroll-margin logic applies. Fix: disable pixel-scroll while typewriter is active.
;; Also requires scroll-conservatively 0 (allow recentering); 10000 blocks it.
;;
;; Mechanism: scroll-margin 999 + maximum-scroll-margin 0.5 = vim's scrolloff=999.
;; Effective margin = min(999, 50% of window height) → cursor always at midpoint.
(defvar ay--typewriter-saved-state nil)

(define-minor-mode ay-typewriter-mode
  "Keep the cursor line always vertically centered (typewriter style)."
  :global t :lighter nil
  (if ay-typewriter-mode
      (progn
        (setq ay--typewriter-saved-state
              (list scroll-conservatively scroll-margin maximum-scroll-margin
                    pixel-scroll-precision-mode))
        (pixel-scroll-precision-mode -1)
        (setq scroll-conservatively  0
              scroll-margin          999
              maximum-scroll-margin  0.5)
        (global-topspace-mode 1))
    (global-topspace-mode -1)
    (when ay--typewriter-saved-state
      (setq scroll-conservatively (nth 0 ay--typewriter-saved-state)
            scroll-margin         (nth 1 ay--typewriter-saved-state)
            maximum-scroll-margin (nth 2 ay--typewriter-saved-state))
      (when (nth 3 ay--typewriter-saved-state)
        (pixel-scroll-precision-mode 1)))))

;; (ay-typewriter-mode 1)

;; Recenter on file open so line 1 gets top padding from topspace
;; (scroll-margin only triggers on cursor movement, not initial display)
(defun ay--recenter-top-padding ()
  (when ay-typewriter-mode (recenter)))
(add-hook 'find-file-hook #'ay--recenter-top-padding)


;; ──────────────────────────────────────────
;; Olivetti (Center Mode)
;; ──────────────────────────────────────────

;; Visual-line-mode globally: wraps long lines at word boundaries
(global-visual-line-mode 1)

;; Olivetti: center mode — narrows the text body and centers it horizontally.
;; :defer t — loaded via window-setup-hook so it doesn't slow init,
;; but activates before the frame becomes visible.
(use-package olivetti
  :straight t
  :defer t
  :config
  (setq-default olivetti-body-width 80)
  (defun ay--olivetti-turn-on ()
    (unless (derived-mode-p 'eat-mode)
      (olivetti-mode 1)))
  (define-globalized-minor-mode global-olivetti-mode
    olivetti-mode ay--olivetti-turn-on))

;; (add-hook 'window-setup-hook (lambda () (require 'olivetti)) t)

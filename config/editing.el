;;; editing.el --- -*- lexical-binding: t; -*-
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
;;   - Markdown & AsciiDoc modes (folding, ay-heading-indent-mode)
;;   - Preview (ay-preview: markdown/asciidoc/org → HTML)
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
;; Markdown / AsciiDoc Modes
;; ──────────────────────────────────────────

;; markdown-cycle via TAB: folds/unfolds heading sections
;; :defer t — only loads when a .md file is opened
(use-package markdown-mode
  :straight t
  :defer t
  :config
  (general-define-key :keymaps 'markdown-mode-map "TAB" 'markdown-cycle))

;; adoc-mode: AsciiDoc, set up to behave exactly like markdown-mode —
;; adoc-cycle on TAB folds/unfolds heading sections, ay-heading-indent-mode
;; indents by level, and ui.el maps its title faces onto markdown's.
;; :defer t — only loads when a .adoc/.asciidoc file is opened
(use-package adoc-mode
  :straight t
  :defer t
  :config
  (general-define-key :keymaps 'adoc-mode-map
    "TAB" 'adoc-cycle
    ;; adoc-mode claims M-<left>/M-<right> for promote/demote, which
    ;; shadows word-by-word motion everywhere else in Emacs. Hand the
    ;; arrows back and move promote/demote onto M-S-<left>/M-S-<right>
    ;; (they are also in the asciidoc menu under "list").
    "M-<left>"    nil
    "M-<right>"   nil
    "M-S-<left>"  'adoc-promote
    "M-S-<right>" 'adoc-demote))

;; ay-heading-indent-mode: visual indentation by heading level,
;; like org-indent-mode. Shifts content rightward using line-prefix
;; and wrap-prefix text properties based on the parent heading depth.
;; The heading syntax is per-buffer, so one mode serves both markdown
;; (# heading) and asciidoc (= heading).
(defvar ay-heading-indent-width 3
  "Columns of visual indentation per heading level.")

(defvar-local ay-heading-indent-regexp "^\\(#\\{1,6\\}\\) "
  "Regexp matching a heading line for `ay-heading-indent-mode'.
Must be anchored at `^'; the length of group 1 is the heading level.")

(defun ay--heading-indent-level-at (pos)
  "Heading level in effect at POS, or 0 above the first heading."
  (save-excursion
    (goto-char pos)
    (if (re-search-backward ay-heading-indent-regexp nil t)
        (- (match-end 1) (match-beginning 1))
      0)))

(defun ay--heading-indent-fontify (beg end)
  "Set line-prefix and wrap-prefix between BEG and END by heading level."
  (with-silent-modifications
    (save-excursion
      (goto-char beg)
      (setq beg (line-beginning-position))
      (goto-char end)
      (setq end (line-end-position))
      (goto-char beg)
      (let ((level (ay--heading-indent-level-at beg)))
        (while (and (<= (point) end) (not (eobp)))
          (when (looking-at ay-heading-indent-regexp)
            (setq level (- (match-end 1) (match-beginning 1))))
          (let* ((indent (* (max 0 (1- level)) ay-heading-indent-width))
                 (prefix (make-string indent ?\s))
                 (eol (min (1+ (line-end-position)) (point-max))))
            (put-text-property (point) eol 'line-prefix prefix)
            (put-text-property (point) eol 'wrap-prefix prefix))
          (forward-line 1))))))

;; An empty last line has no character to carry line-prefix, so after
;; RET at end of buffer the cursor would sit at column 0 until the first
;; keystroke. A zero-width overlay at point-max draws the prefix instead;
;; the cursor lands after a before-string, i.e. at the indented position.
(defvar-local ay--heading-indent-eob-ov nil)

(defun ay--heading-indent-eob ()
  "Show the heading-level prefix on an empty last line."
  (let ((empty-last (or (= (point-min) (point-max))
                        (eq (char-before (point-max)) ?\n))))
    (if (not empty-last)
        (when ay--heading-indent-eob-ov
          (delete-overlay ay--heading-indent-eob-ov))
      (let* ((level (ay--heading-indent-level-at (point-max)))
             (prefix (make-string (* (max 0 (1- level))
                                     ay-heading-indent-width)
                                  ?\s)))
        (unless (overlayp ay--heading-indent-eob-ov)
          (setq ay--heading-indent-eob-ov
                (make-overlay (point-max) (point-max) nil t nil)))
        (move-overlay ay--heading-indent-eob-ov (point-max) (point-max))
        (overlay-put ay--heading-indent-eob-ov 'before-string prefix)))))

(define-minor-mode ay-heading-indent-mode
  "Visually indent buffer content by heading level."
  :lighter nil
  (if ay-heading-indent-mode
      (progn
        (jit-lock-register #'ay--heading-indent-fontify)
        (ay--heading-indent-fontify (point-min) (point-max))
        (add-hook 'post-command-hook #'ay--heading-indent-eob nil t)
        (ay--heading-indent-eob))
    (jit-lock-unregister #'ay--heading-indent-fontify)
    (remove-hook 'post-command-hook #'ay--heading-indent-eob t)
    (when ay--heading-indent-eob-ov
      (delete-overlay ay--heading-indent-eob-ov))
    (with-silent-modifications
      (remove-text-properties (point-min) (point-max)
                              '(line-prefix nil wrap-prefix nil)))))

(defun ay--markdown-heading-indent ()
  (setq-local ay-heading-indent-regexp "^\\(#\\{1,6\\}\\) ")
  (ay-heading-indent-mode 1))

(defun ay--adoc-heading-indent ()
  ;; AsciiDoc one-line titles: "= Title", "== Section", … up to level 6.
  (setq-local ay-heading-indent-regexp "^\\(=\\{1,6\\}\\) ")
  (ay-heading-indent-mode 1))

(add-hook 'markdown-mode-hook #'ay--markdown-heading-indent)
(add-hook 'adoc-mode-hook     #'ay--adoc-heading-indent)


;; ──────────────────────────────────────────
;; Preview
;; ──────────────────────────────────────────

;; ay-preview renders the current markdown / asciidoc / org buffer to HTML
;; and opens it: pandoc for markdown, asciidoctor for asciidoc, org's own
;; exporter for org. The buffer is piped in as it stands, so previewing an
;; unsaved draft works.
;;
;; The HTML is written as a hidden file beside the source, so relative
;; image and stylesheet paths resolve exactly as in the final document.
;; Every file written this way is deleted when Emacs exits.

(defvar ay-preview-in-eww nil
  "When non-nil, open previews in eww instead of the system browser.")

(defvar ay-preview-pandoc-args
  '("-f" "gfm" "-t" "html5" "--standalone")
  "Pandoc arguments used to render markdown previews.")

(defvar ay--preview-files nil
  "Preview files written in this session, deleted when Emacs exits.")

(defun ay--preview-file ()
  "Path of the preview HTML for the current buffer."
  (if buffer-file-name
      (expand-file-name (format ".%s-preview.html"
                                (file-name-base buffer-file-name))
                        (file-name-directory buffer-file-name))
    (expand-file-name (format ".%s-preview.html"
                              (replace-regexp-in-string
                               "[^A-Za-z0-9]+" "-" (buffer-name)))
                      temporary-file-directory)))

(defun ay--preview-program (program hint)
  "Return PROGRAM's full path, or fail with an install HINT."
  (or (executable-find program)
      (user-error "%s is not installed — run: %s" program hint)))

(defun ay--preview-render (program args out)
  "Pipe the buffer through PROGRAM with ARGS, writing the HTML to OUT."
  ;; call-process-region wants a *file* for stderr, not a buffer.
  (let ((html (generate-new-buffer " *ay-preview*"))
        (err  (make-temp-file "ay-preview-stderr")))
    (unwind-protect
        (let ((status (apply #'call-process-region (point-min) (point-max)
                             program nil (list html err) nil args)))
          (unless (eq status 0)
            (user-error "%s failed: %s"
                        (file-name-nondirectory program)
                        (string-trim
                         (with-temp-buffer (insert-file-contents err)
                                           (buffer-string)))))
          (with-current-buffer html
            (write-region (point-min) (point-max) out nil 'quiet)))
      (kill-buffer html)
      (ignore-errors (delete-file err)))))

(defun ay--preview-cleanup ()
  "Delete every preview file written in this session."
  (dolist (f ay--preview-files)
    (when (file-exists-p f) (ignore-errors (delete-file f)))))

(add-hook 'kill-emacs-hook #'ay--preview-cleanup)

(defun ay-preview ()
  "Render the current document to HTML and open the result."
  (interactive)
  (let ((out (ay--preview-file))
        (dir (or (and buffer-file-name (file-name-directory buffer-file-name))
                 default-directory)))
    (cond
     ((derived-mode-p 'markdown-mode)
      (ay--preview-render
       (ay--preview-program "pandoc" "brew install pandoc")
       (append ay-preview-pandoc-args
               (list "--metadata" (format "title=%s" (buffer-name))))
       out))
     ((derived-mode-p 'adoc-mode)
      (ay--preview-render
       (ay--preview-program "asciidoctor" "brew install asciidoctor")
       ;; -B sets the base directory for include:: directives; "-o -" and the
       ;; trailing "-" make asciidoctor read stdin and write stdout.
       (list "-B" (expand-file-name dir) "-o" "-" "-")
       out))
     ((derived-mode-p 'org-mode)
      (require 'ox-html)
      (org-export-to-file 'html out))
     (t (user-error "No preview for %s" major-mode)))
    (unless (member out ay--preview-files)
      (push out ay--preview-files))
    (if ay-preview-in-eww (eww-open-file out) (browse-url-of-file out))
    (message "Preview: %s" (abbreviate-file-name out))))


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

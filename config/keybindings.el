;; keybindings.el — Global key bindings and unbindings
;;
;; Contents:
;;   - CUA mode (C-c/C-x/C-v/C-z)
;;   - Key unbindings (clear Emacs defaults replaced below)
;;   - Search (C-f, isearch behaviour)
;;   - Copy / paste / navigation (ESC, C-a, C-arrows)
;;   - Editor keybindings (C-k menu, C-o open, C-s save, C-t split, C-w close…)
;;   - reload-config
;;   - Transient ESC behaviour


;; ──────────────────────────────────────────
;; macOS Modifier Remapping
;; ──────────────────────────────────────────

;; On macOS, remap modifiers to match the ThinkPad/keyd layout:
;;   Cmd    → C-  (matches physical Alt on ThinkPad)
;;   Ctrl   → s-  (matches physical Ctrl on ThinkPad)
;;   Option → M-  (matches physical Win on ThinkPad)
;; This way all keybindings work identically on both platforms.
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'control)
  (setq mac-control-modifier 'super)
  (setq mac-option-modifier 'meta))


;; ──────────────────────────────────────────
;; CUA Mode
;; ──────────────────────────────────────────

;; CUA mode: C-c copy (with region), C-x cut (with region), C-v paste, C-z undo
(cua-mode t)


;; ──────────────────────────────────────────
;; Key Unbindings
;; ──────────────────────────────────────────

;; NOTE on keyd modifier remapping:
;; Physical Alt   → sends Ctrl  → Emacs sees C- (user's "logical Ctrl")
;; Physical Win   → sends Alt   → Emacs sees M- (user's "logical Alt")
;; Physical Ctrl  → sends Super → not transmitted through terminal
;; All custom bindings use C- (not s-).

;; Remove default C- bindings that are replaced below
(general-define-key
 "C-p"      nil   ; previous-line (unbound)
 "C-k"      nil   ; kill-line            → opens main menu
 "C-n"      nil   ; next-line            → goes to scratch buffer
 "C-f"      nil   ; forward-char         → opens search
 "C-b"      nil   ; backward-char        → use arrow left
 "C-a"      nil   ; move-beginning-of-line → selects all
 "C-e"      nil   ; move-end-of-line     → use C-<left/right>
 "C-x h"    nil   ; mark-whole-buffer    → replaced by C-a
 "M-w"      nil   ; kill-ring-save       → CUA handles copy via C-c
 "C-s"      nil   ; isearch-forward      → saves
 "C-r"      nil   ; isearch-backward     → reloads config
 "C-o"      nil   ; open-line            → opens file
 "C-w"      nil   ; kill-region          → closes buffer
 "C-q"      nil   ; quoted-insert        → quits Emacs
 "C-z"      nil   ; suspend-frame        → undoes (CUA + undo-tree)
 "M-z"      nil   ; zap-to-char          → redoes
 "C-<left>" nil   ; left-word            → word by word (rebound below)
 "C-<right>" nil) ; right-word           → word by word (rebound below)

;; Prevent isearch from swallowing CUA clipboard keys
(general-define-key :keymaps 'isearch-mode-map
 "C-c" nil "C-v" nil "C-z" nil)

;; Prevent CUA from swallowing Escape and Return
(general-define-key :keymaps 'cua--cua-keys-keymap
 "<escape>" nil "<return>" nil)


;; ──────────────────────────────────────────
;; Search
;; ──────────────────────────────────────────

;; Always start isearch from buffer top so nothing is missed
(defun isearch-from-buffer-start ()
  (interactive)
  (goto-char (point-min))
  (isearch-forward))

(general-define-key "C-f" 'isearch-from-buffer-start)

;; Inside isearch: Enter = next match, Escape = exit
(general-define-key :keymaps 'isearch-mode-map
 "<return>" 'isearch-repeat-forward
 "<escape>" 'isearch-exit)


;; ──────────────────────────────────────────
;; Copy-Paste and Navigation
;; ──────────────────────────────────────────

(general-define-key "<escape>" 'keyboard-quit)
(general-define-key "C-a" 'mark-whole-buffer)
(general-define-key "C-<left>"  'left-word
                    "C-<right>" 'right-word)


;; ──────────────────────────────────────────
;; Editor Keybindings
;; ──────────────────────────────────────────

(general-define-key "C-k" 'ay-menu)
(general-define-key "C-o" 'counsel-find-file)
(general-define-key "C-=" 'text-scale-increase)
(general-define-key "C--" 'text-scale-decrease)
(general-define-key "C-0" 'text-scale-adjust) ; C-0 resets to default
(general-define-key "C-s" 'save-buffer)
(general-define-key "C-n" (lambda () (interactive) (switch-to-buffer "*scratch*")))
(general-define-key "C-t" 'ay-split-right)
(general-define-key "C-w" 'ay-close-pane-or-buffer)
(general-define-key "C-q" 'save-buffers-kill-emacs)

(defun reload-config ()
  "Reload init.el and config.el in the running session."
  (interactive)
  (load-file (expand-file-name "init.el" user-emacs-directory)))

(general-define-key "C-r" 'reload-config)


;; ──────────────────────────────────────────
;; Transient
;; ──────────────────────────────────────────

(require 'transient)

;; ESC navigates up one transient level; at the top level it closes
(with-eval-after-load 'transient
  (define-key transient-map (kbd "<escape>") #'transient-quit-one))

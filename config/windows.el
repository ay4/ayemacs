;; windows.el — Window/pane management and dimming
;;
;; Contents:
;;   - ay-split-right / ay-split-below
;;   - ay-close-pane-or-buffer
;;   - M-TAB / M-S-TAB pane cycling, C-{ / C-} buffer cycling keybindings
;;   - dimmer (inactive pane dimming, ERC + transient exclusions)


;; ──────────────────────────────────────────
;; Window Management
;; ──────────────────────────────────────────

;; Split the frame and move focus to the new pane.
(defun ay-split-right ()
  "Split window right and focus the new pane."
  (interactive)
  (split-window-right)
  (other-window 1))

(defun ay-split-below ()
  "Split window below and focus the new pane."
  (interactive)
  (split-window-below)
  (other-window 1))

(defun ay-close-pane-or-buffer ()
  "Close the current pane if there are multiple; otherwise close the buffer."
  (interactive)
  (if (one-window-p) (kill-buffer) (delete-window)))

;; M-TAB / M-S-TAB cycle panes, C-{ / C-} cycle buffers
(general-define-key
 "M-TAB"   'other-window
 "M-S-TAB" (lambda () (interactive) (other-window -1))
 "C-{"     (lambda () (interactive) (previous-buffer))
 "C-}"     'next-buffer)


;; ──────────────────────────────────────────
;; Dimmer
;; ──────────────────────────────────────────

;; Dim inactive windows so the active pane stands out.
(use-package dimmer
  :straight t
  :config
  (setq dimmer-fraction 0.7)        ; 0.0 = no dimming, 1.0 = fully dark
  ;; Never dim ERC buffers (all use erc-mode).
  (defun ay-dimmer-erc-p (buf) (with-current-buffer buf (derived-mode-p 'erc-mode)))
  (push 'ay-dimmer-erc-p dimmer-buffer-exclusion-predicates)
  ;; Never dim the transient popup (it sits in a non-selected window at the bottom).
  (add-to-list 'dimmer-buffer-exclusion-regexps "^ \\*transient\\*")
  (dimmer-mode 1))

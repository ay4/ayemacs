;; ui.el — Visual appearance and startup
;;
;; Contents:
;;   - Basic UI (hide toolbars, cursor, bell…)
;;   - mood-line (minimal mode line)
;;   - Frame border (40 px padding matching theme background)
;;   - Line numbers (prog-mode only)
;;   - Theme packages + ay-pick-theme
;;   - Monospace heading enforcement (org, markdown)
;;   - Startup state (load saved theme)


;; ──────────────────────────────────────────
;; UI / Visuals
;; ──────────────────────────────────────────

(setq inhibit-startup-screen t)
(setq initial-scratch-message "")
(setq initial-major-mode 'text-mode) ; scratch buffer starts in plain text mode
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(setq-default frame-title-format '("%b"))
(setq ring-bell-function 'ignore)
(fset 'yes-or-no-p 'y-or-n-p)
(delete-selection-mode 1)
(transient-mark-mode 1)
(global-auto-revert-mode t)
(setq-default cursor-type 'box)
(when (fboundp 'fringe-mode) (fringe-mode 0))


;; ──────────────────────────────────────────
;; Mode Line
;; ──────────────────────────────────────────

(use-package mood-line
  :straight t
  :config
  (mood-line-mode))


;; ──────────────────────────────────────────
;; Frame Border
;; ──────────────────────────────────────────

;; Adds 40 px of invisible padding around the frame: the internal border is
;; set to match the theme background so it blends in rather than standing out.
(defvar ay-frame-border-width 40
  "Internal border width in pixels — visual breathing room around the frame.")

(defun ay-setup-frame-border (&rest _)
  "Set internal frame border width, color, and ns-appearance to match the theme."
  (when (display-graphic-p)
    ;; Small delay lets the theme fully settle before reading background color.
    (run-at-time 0.1 nil
      (lambda ()
        (when (display-graphic-p)
          (let ((bg (face-attribute 'default :background nil t)))
            (when (and bg (not (eq bg 'unspecified)))
              (set-face-background 'internal-border bg)
              ;; Keep title-bar buttons dark/light in sync with the theme.
              (when (eq system-type 'darwin)
                (let* ((c (color-values bg))
                       (appearance (if (< (+ (nth 0 c) (nth 1 c) (nth 2 c))
                                          (* 3 32767))
                                       'dark 'light)))
                  (dolist (frame (frame-list))
                    (set-frame-parameter frame 'ns-appearance appearance))))))
          (dolist (frame (frame-list))
            (set-frame-parameter frame 'internal-border-width ay-frame-border-width)))))))

;; Apply now, on every new frame, and after every theme change.
(ay-setup-frame-border)
(add-hook 'after-make-frame-functions #'ay-setup-frame-border)
(advice-add 'load-theme :after #'ay-setup-frame-border)


;; ──────────────────────────────────────────
;; Line Numbers
;; ──────────────────────────────────────────

;; Show line numbers in any programming/code buffer.
(add-hook 'prog-mode-hook #'display-line-numbers-mode)


;; ──────────────────────────────────────────
;; Themes
;; ──────────────────────────────────────────

;; modus-themes must load before ef-themes (ef-themes uses modus-themes-theme macro).
(straight-use-package 'modus-themes)
(require 'modus-themes)

(straight-use-package 'nord-theme)
(straight-use-package 'gruvbox-theme)
(straight-use-package 'solarized-theme)
(straight-use-package 'ayu-theme)
(straight-use-package 'catppuccin-theme)
(straight-use-package '(lambda-themes :type git :host github :repo "Lambda-Emacs/lambda-themes"))
(straight-use-package '(elegant-nano  :type git :host github :repo "oracleyue/elegant-theme"))
(straight-use-package 'ef-themes)
(straight-use-package 'doom-themes)
;; modus-vivendi / modus-vivendi-tinted are built-in — no install needed

(defun ay-save-theme (theme)
  (with-temp-file (expand-file-name "theme.el" user-emacs-directory)
    (insert (format "(load-theme '%s t)\n" theme))))

(defun ay-pick-theme ()
  "Choose a theme from all available themes and persist the choice."
  (interactive)
  (let* ((current (car custom-enabled-themes))
         (themes (mapcar #'symbol-name (custom-available-themes)))
         (chosen (intern (completing-read "theme: " themes nil t))))
    (when current (disable-theme current))
    (load-theme chosen t)
    (ay-save-theme chosen)))


;; ──────────────────────────────────────────
;; Monospace Headings
;; ──────────────────────────────────────────

;; Force heading faces to the default (monospace) font family and
;; uniform height. Re-applied after every theme load so themes
;; that set variable-pitch or enlarged headings get overridden.
(defun ay-enforce-monospace-headings (&rest _)
  "Reset heading faces to monospace font; org headings at body size, markdown slightly smaller."
  (let ((family (face-attribute 'default :family)))
    (dolist (face '(org-level-1 org-level-2 org-level-3 org-level-4
                    org-level-5 org-level-6 org-level-7 org-level-8))
      (when (facep face)
        (set-face-attribute face nil :family family :height 1.0)))
    (dolist (face '(markdown-header-face
                    markdown-header-face-1 markdown-header-face-2
                    markdown-header-face-3 markdown-header-face-4
                    markdown-header-face-5 markdown-header-face-6))
      (when (facep face)
        (set-face-attribute face nil :family family :height 1.1)))))

(advice-add 'load-theme :after #'ay-enforce-monospace-headings)

;; Re-apply after org/markdown load — faces don't exist until first use
(with-eval-after-load 'org (ay-enforce-monospace-headings))
(with-eval-after-load 'markdown-mode (ay-enforce-monospace-headings))


;; ──────────────────────────────────────────
;; Startup State
;; ──────────────────────────────────────────

;; Load saved theme — after all theme packages are registered above
(let ((theme-file (expand-file-name "theme.el" user-emacs-directory)))
  (when (file-exists-p theme-file)
    (load theme-file nil t)))

;; early-init.el hides the frame to prevent white flash during startup.
;; Position the frame (matching Hammerspoon HYPER+v: 12×8 grid, x=4 y=1 w=4 h=6)
;; then reveal it — depth -10 ensures positioning runs before visibility at depth 0.
(defun ay-set-initial-frame-geometry ()
  (let* ((wa   (frame-monitor-workarea))
         (wa-x (nth 0 wa)) (wa-y (nth 1 wa))
         (wa-w (nth 2 wa)) (wa-h (nth 3 wa))
         (f-x  (+ wa-x (round (* (/ 4.0 12) wa-w))))
         (f-y  (+ wa-y (round (* (/ 1.0  8) wa-h))))
         (f-w  (round (* (/ 4.0 12) wa-w)))
         (f-h  (round (* (/ 6.0  8) wa-h))))
    (set-frame-parameter nil 'left   f-x)
    (set-frame-parameter nil 'top    f-y)
    (set-frame-parameter nil 'width  (cons 'text-pixels f-w))
    (set-frame-parameter nil 'height (cons 'text-pixels f-h))))

(add-hook 'after-init-hook #'ay-set-initial-frame-geometry -10)
(add-hook 'after-init-hook #'make-frame-visible)

;; apps.el — Application packages: terminal, browsers, IRC, bookmarks
;;
;; Contents:
;;   - Eat terminal emulator (keybindings via emulation-mode-map-alists)
;;   - Ace-link (hint-jump navigation for EWW and Elpher)
;;   - EWW browser (keybindings, copy-link, bookmarks)
;;   - Elpher (Gemini / Gopher browser, shared bookmarks)
;;   - ERC IRC client (Libera.Chat TLS+SASL, Undernet plain)
;;   - Bookmark+ (enhanced bookmarks, shared across EWW and Elpher)


;; ──────────────────────────────────────────
;; Terminal Emulators
;; ──────────────────────────────────────────

;; eat (Emulate A Terminal): fast terminal emulator written in pure Elisp.
;; Works in both GUI and terminal Emacs without external C dependencies.
(use-package eat
  :straight '(eat :type git :host codeberg :repo "akib/emacs-eat"
                  :files ("*.el" ("term" "term/*.el") "*.texi"
                          "*.ti" ("terminfo/e" "terminfo/e/*")
                          ("terminfo/65" "terminfo/65/*")
                          ("integration" "integration/*")
                          ("e" "e/*") ("dist" "dist/*")))
  :defer t
  :config
  (setq eat-kill-buffer-on-exit t)
  (setq eat-shell "/bin/zsh")
  (setq eat-term-name "xterm-256color")
  (setq eat-query-before-killing-running-terminal nil)

  (defun ay-eat-shift-select (move-fn)
    "Select text in eat buffer with shift+arrows."
    (unless (region-active-p) (push-mark (point) nil t))
    (funcall move-fn))

  (defun ay-eat-send-c-c ()
    "Send interrupt (C-c) to the eat terminal process."
    (interactive)
    (process-send-string (get-buffer-process (current-buffer)) "\C-c"))

  (defun ay-eat-copy ()
    "Copy selection in eat buffer."
    (interactive)
    (when (region-active-p)
      (kill-ring-save (region-beginning) (region-end))
      (deactivate-mark)))

  ;; All custom eat keybindings live in an emulation-mode-map, which has
  ;; higher priority than both eat's own semi-char keymap (which gets
  ;; regenerated, losing any bindings set on it) and CUA mode (which
  ;; intercepts C-c as a prefix key). Keyed on eat--semi-char-mode
  ;; (the internal minor mode variable, double-dash).
  (defvar ay-eat-override-map (make-sparse-keymap))
  (define-key ay-eat-override-map (kbd "C-c") #'ay-eat-send-c-c)
  (define-key ay-eat-override-map (kbd "C-S-c") #'ay-eat-copy)
  (define-key ay-eat-override-map (kbd "C-S-v") #'eat-yank)
  (define-key ay-eat-override-map (kbd "C-k") #'ay-menu)
  (define-key ay-eat-override-map (kbd "S-<left>")
    (lambda () (interactive) (ay-eat-shift-select #'backward-char)))
  (define-key ay-eat-override-map (kbd "S-<right>")
    (lambda () (interactive) (ay-eat-shift-select #'forward-char)))
  (define-key ay-eat-override-map (kbd "S-<up>")
    (lambda () (interactive) (ay-eat-shift-select #'previous-line)))
  (define-key ay-eat-override-map (kbd "S-<down>")
    (lambda () (interactive) (ay-eat-shift-select #'next-line)))
  (define-key ay-eat-override-map (kbd "C-<left>")
    (lambda () (interactive)
      (process-send-string (get-buffer-process (current-buffer)) "\eb")))
  (define-key ay-eat-override-map (kbd "C-<right>")
    (lambda () (interactive)
      (process-send-string (get-buffer-process (current-buffer)) "\ef")))
  (defvar ay-eat-emulation-alist `((eat--semi-char-mode . ,ay-eat-override-map)))
  (add-to-list 'emulation-mode-map-alists 'ay-eat-emulation-alist))


;; ──────────────────────────────────────────
;; Ace-link
;; ──────────────────────────────────────────

;; ace-link: overlays short labels on visible links so you can jump to any
;; link by pressing its letter — like qutebrowser's 'h' hint mode.
(use-package ace-link
  :straight t
  :config
  (setq avy-style 'pre)
  (ace-link-setup-default))


;; ──────────────────────────────────────────
;; EWW Browser
;; ──────────────────────────────────────────

;; EWW: Emacs built-in web browser. Keybindings mirror elinks/qutebrowser:
;;   g / C-l  → go to URL          h   → hint-jump links (ace-link)
;;   a / [    → back               d / ] → forward
;;   w        → previous link      s   → next link
;;   b        → bookmarks list     B   → add bookmark
;;   C-r      → reload             r   → reader mode
;;   t        → new EWW buffer     u   → copy URL      q → close

;; Show only bookmark names in the bookmark list, not URLs.
(setq bookmark-bmenu-toggle-filenames nil)

(use-package eww
  :straight (:type built-in)
  :defer t
  :config
  (setq eww-search-prefix "https://lite.duckduckgo.com/lite/?q=")
  (setq shr-use-fonts nil)      ; keep monospace; don't switch to proportional
  (setq shr-inhibit-images t)  ; don't load or display images
  (setq shr-width 80)           ; wrap rendered text at 80 chars
  (setq eww-history-limit 50)

  (defun ay-eww-add-bookmark ()
    "Bookmark the current EWW page in Emacs bookmarks."
    (interactive)
    (let ((title (plist-get eww-data :title))
          (url (eww-current-url)))
      (bookmark-set (or title url))
      (message "Bookmarked: %s" (or title url))))

  (defun ay-eww-copy-link ()
    "Copy the URL of the link under point to the kill ring."
    (interactive)
    (let ((url (get-text-property (point) 'shr-url)))
      (if url
          (progn (kill-new url) (message "Copied: %s" url))
        (message "No link under point"))))

  (defun ay-eww-copy-url ()
    "Copy the current EWW page URL to the kill ring."
    (interactive)
    (let ((url (eww-current-url)))
      (kill-new url)
      (message "Copied: %s" url)))

  (defun ay-eww-new-buffer ()
    "Prompt for a URL and open it in a new EWW buffer."
    (interactive)
    (let ((url (read-string "URL: ")))
      (eww url t)))

  (defun ay-eww-follow ()
    "Follow link or press form button at point."
    (interactive)
    (condition-case nil
        (eww-follow-link)
      (error (widget-button-press (point)))))

  ;; Bind keys in eww-mode-map. EWW is a read-only special-mode buffer,
  ;; so single-letter keys work as commands (no text insertion).
  (general-define-key :keymaps 'eww-mode-map
    "g"         'eww                  ; go to URL
    "C-l"       'eww                  ; go to URL (like qutebrowser C-l)
    "h"         'ace-link-eww         ; hint-jump links (like qutebrowser h)
    "a"         'eww-back-url         ; back (like elinks/qutebrowser a)
    "d"         'eww-forward-url      ; forward (like elinks/qutebrowser d)
    "["         'eww-back-url         ; back alternate
    "]"         'eww-forward-url      ; forward alternate
    "w"         'shr-previous-link    ; prev link (like elinks w)
    "s"         'shr-next-link        ; next link (like elinks s)
    "b"         'counsel-bookmark  ; bookmarks list (like elinks b)
    "B"         'ay-eww-add-bookmark  ; add bookmark (like elinks B)
    "u"         'ay-eww-copy-url      ; copy page URL
    "t"         'ay-eww-new-buffer    ; new browser buffer (like elinks t)
    "r"         'eww-readable         ; reader/article mode
    "C-r"       'eww-reload           ; reload (like qutebrowser C-r)
    "C-k"       'ay-menu              ; main menu
    "q"         'kill-buffer          ; close browser buffer
    "<return>"  'ay-eww-follow        ; follow link or press button under point
    "TAB"       'shr-next-link        ; next link
    "<backtab>" 'shr-previous-link))  ; previous link


;; ──────────────────────────────────────────
;; Elpher (Gemini / Gopher)
;; ──────────────────────────────────────────

;; Elpher: Gemini and Gopher browser. Same navigation conventions as EWW.
;; (Gemini has no "forward" — a/[ both go back.)

(use-package elpher
  :straight nil   ; installed via apt (elpa-elpher)
  :commands elpher
  :config
  (setq elpher-default-url-type "gemini")
  (setq elpher-use-emacs-bookmark-menu t) ; share bookmarks with EWW

  (general-define-key :keymaps 'elpher-mode-map
    "g"         'elpher-go               ; go to address
    "h"         'elpher-jump             ; hint-jump by link name
    "a"         'elpher-back             ; back (gemini has no forward)
    "["         'elpher-back             ; back alternate
    "w"         'elpher-prev-link        ; previous link
    "s"         'elpher-next-link        ; next link
    "b"         'elpher-show-bookmarks   ; bookmarks list
    "B"         'elpher-bookmark-link    ; add bookmark
    "u"         'elpher-copy-current-url ; copy page URL
    "C-r"       'elpher-reload           ; reload
    "C-k"       'ay-menu                 ; main menu
    "q"         'kill-buffer             ; close buffer
    "<return>"  'elpher-follow-current-link
    "TAB"       'elpher-next-link
    "<backtab>" 'elpher-prev-link))


;; ──────────────────────────────────────────
;; ERC (IRC)
;; ──────────────────────────────────────────

;; ERC: built-in IRC client. Libera.Chat via TLS+SASL, Undernet plain.

(use-package erc
  :custom
  ;; Use actual variable name (erc-join-buffer is just an alias for this).
  ;; 'buffer = switch to new ERC buffers in the current window.
  (erc-buffer-display 'buffer)
  (erc-interactive-display 'buffer)
  :config
  (setq erc-nick "ay4"
        erc-user-full-name "ay4")

  ;; Modules to load. No 'services' — auth via SASL only (avoids NickServ on Undernet).
  (setq erc-modules '(autojoin button completion dcc fill irccontrols
                      match networks netsplit noncommands readonly ring
                      stamp track truncate))
  (erc-update-modules)

  ;; Load erc-sasl explicitly so its variables exist before we set them.
  (require 'erc-sasl)
  ;; SASL PLAIN — only fires when server offers the sasl capability (Libera.Chat).
  ;; erc-sasl-password stays at default :password, meaning it reads the session
  ;; password passed via :password to erc-tls.
  (setq erc-sasl-mechanism 'plain
        erc-sasl-user "ay4")

  ;; Timestamps on the left.
  (setq erc-timestamp-format "%H:%M "
        erc-insert-timestamp-function 'erc-insert-timestamp-left)

  ;; Wrap at 80 chars.
  (setq erc-fill-column 80)

  ;; Hide join/part/quit noise.
  (setq erc-hide-list '("JOIN" "PART" "QUIT"))


  (defun ay-erc-send (cmd)
    "Send raw IRC command CMD in current ERC buffer."
    (erc-send-command cmd))

  (defun ay-erc-list ()
    "Send IRC LIST to get channel list."
    (interactive)
    (ay-erc-send "LIST"))

  (defun ay-erc-names ()
    "Send IRC NAMES for the current channel."
    (interactive)
    (ay-erc-send (concat "NAMES " (erc-default-target))))

  ;; Reset ERC faces to inherit from default so the theme's foreground is used.
  (with-eval-after-load 'erc-goodies
    (dolist (face '(erc-default-face erc-input-face erc-my-nick-face
                    erc-nick-default-face erc-prompt-face erc-timestamp-face
                    erc-notice-face erc-action-face erc-error-face))
      (when (facep face)
        (set-face-attribute face nil :foreground 'unspecified :weight 'unspecified))))

  ;; DCC settings — must load erc-dcc first so variables exist.
  (with-eval-after-load 'erc-dcc
    (setq erc-dcc-get-default-directory (expand-file-name "~/downloads/irc/"))
    (setq erc-dcc-send-request 'auto)
    (setq erc-dcc-auto-masks '(".*!.*@.*"))
    ;; Auto-accept passes a bare filename with no directory; prepend the
    ;; configured download dir so files don't land in ~.
    (defun ay-erc-dcc-get-file-fix-dir (orig entry file parent-proc)
      (let ((file (if (file-name-absolute-p file)
                      file
                    (expand-file-name (file-name-nondirectory file)
                                      (or erc-dcc-get-default-directory
                                          default-directory)))))
        (funcall orig entry file parent-proc)))
    (advice-add 'erc-dcc-get-file :around #'ay-erc-dcc-get-file-fix-dir))

  ;; M-TAB is used globally for pane cycling; unbind ERC's nick completion from it.
  (define-key erc-mode-map (kbd "M-TAB") nil)

  (defun ay-erc-libera ()
    "Connect to Libera.Chat (TLS + SASL PLAIN)."
    (interactive)
    (let ((erc-modules (append erc-modules '(sasl))))
      (erc-tls :server "irc.libera.chat" :port 6697 :nick "ay4"
               :password "wellwe11well")))

  (defun ay-erc-undernet ()
    "Connect to Undernet (plain, no auth)."
    (interactive)
    (erc :server "irc.undernet.org" :port 6667 :nick "ay4")))


;; ──────────────────────────────────────────
;; Bookmark+
;; ──────────────────────────────────────────

;; bookmark+: enhanced bookmarks with tagging, annotations, and sorting.
;; Shared between EWW, Elpher, and regular buffers.
(use-package bookmark+
  :straight (bookmark+ :type git :host github :repo "emacsmirror/bookmark-plus")
  :defer t
  :config
  (setq bookmark-save-flag 1)) ; auto-save bookmarks on every change

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
  (setq eat-shell "/bin/bash")
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
  ;; higher priority than both eat's own semi-char/char keymaps (which get
  ;; regenerated, losing any bindings set on them) and CUA mode (which
  ;; intercepts C-c as a prefix key). Keyed on eat--semi-char-mode and
  ;; eat--char-mode (the internal minor mode variables, double-dash) so it
  ;; applies in both keybinding modes - in particular C-k must keep opening
  ;; `ay-menu' even in char-mode (used by e.g. `ay-matrix'/gomuks), not get
  ;; forwarded to whatever program is running in the terminal.
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
  (defvar ay-eat-emulation-alist `((eat--semi-char-mode . ,ay-eat-override-map)
                                    (eat--char-mode . ,ay-eat-override-map)))
  (add-to-list 'emulation-mode-map-alists 'ay-eat-emulation-alist))


;; ──────────────────────────────────────────
;; Matrix (gomuks, via eat)
;; ──────────────────────────────────────────

;; gomuks is a standalone Go TUI (see ~/setup/journal 032-033), launched via
;; the `matrix' shell alias. It owns a lot of Ctrl/Alt+arrow and Ctrl+Home/
;; End bindings that eat's "semi-char" mode never forwards to the terminal at
;; all (see `eat-semi-char-non-bound-keys'), so switching to char-mode as
;; soon as gomuks starts lets those reach it. C-k still opens the global
;; `ay-menu' rather than reaching gomuks's own "fuzzy search rooms" binding -
;; `ay-eat-override-map' above is wired into char-mode too specifically so
;; that carve-out holds; everything else not in that map still passes
;; straight through.
(defun ay-matrix ()
  "Launch gomuks (Matrix TUI client) in a dedicated eat buffer, in char-mode."
  (interactive)
  (require 'eat)
  (let ((buf (get-buffer-create "*matrix*")))
    (with-current-buffer buf
      (unless (eq major-mode 'eat-mode)
        (eat-mode))
      (pop-to-buffer-same-window buf)
      (unless (and eat-terminal
                   (eat-term-parameter eat-terminal 'eat--process))
        ;; Full path, not the `matrix' alias: the Emacs daemon runs under
        ;; systemd (emacs.service), whose PATH doesn't include ~/bin.
        (eat-exec buf (buffer-name) "/home/ay4/.local/bin/gomuks-new" nil nil))
      (eat-char-mode))))


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
  :straight (:host github :repo "emacsmirror/elpher")
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
    (erc-server-send cmd))

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


;; ──────────────────────────────────────────
;; Multitran
;; ──────────────────────────────────────────

;; multitran: English<->Russian dictionary lookup, defaults to word at point.
;; Bound as "m" in every "here" menu (see menus.el).
(use-package multitran
  :straight (multitran :type git :host github :repo "zevlg/multitran.el")
  :commands multitran
  :config
  ;; multitran calls plain `pop-to-buffer', which by default pops open a
  ;; new window/pane. Reuse the current window instead.
  (add-to-list 'display-buffer-alist
               '("\\*multitran\\*" (display-buffer-same-window))))


;; ──────────────────────────────────────────
;; Telega (Telegram)
;; ──────────────────────────────────────────

;; telega: Telegram client. Requires TDLib 1.8.64 built from source and
;; installed to /usr/local (headers at /usr/local/include/td/, library at
;; /usr/local/lib/libtdjson.so). Build telega-server with M-x telega-server-build.
(use-package telega
  :straight (telega :type git :host github :repo "zevlg/telega.el"
                     :files (:defaults "etc" "server" "contrib" "Makefile"))
  :commands telega
  :config
  ;; TDLib installed to /usr/local (the default, but explicit for clarity).
  (setq telega-server-libs-prefix "/usr/local")
  (setq telega-use-images t)
  (setq telega-root-default-view-function 'telega-view-compact)
  (setq telega-chat-show-avatars nil)
  (setq telega-root-show-avatars nil)
  (setq telega-emoji-use-images nil)

  ;; IRC-like message format: <Dima Neiaglov>: Hello
  (defun my/telega-ins--msg-sender (msg &rest _args)
    (let ((sender (telega-msg-sender msg)))
      (telega-ins "<")
      (telega-ins (telega-msg-sender-title sender))
      (telega-ins ">")))
  (setq telega-inserter-for-msg-sender #'my/telega-ins--msg-sender)

  (telega-notifications-mode 1))

;; Thin, always-defined wrapper used by `ay-apps-menu' (menus.el) instead of
;; the `telega' symbol directly. transient force-loads any autoloaded
;; command referenced as a menu suffix the instant the menu is constructed
;; (`transient--load-command-if-autoload', called from
;; `transient--init-suffix'), not when the suffix is actually selected -
;; confirmed by tracing a `provide' breakpoint back through that call chain.
;; telega is heavy enough that this is a visible pause the first time the
;; apps menu is opened at all, even without picking "telegram". Since this
;; wrapper is a plain defun, not an autoload stub, transient leaves it
;; alone, and `telega' only autoloads for real on the one call inside it.
(defun ay-telega ()
  "Launch telega, deferring its (heavy) autoload to this exact call."
  (interactive)
  (telega))



;; ──────────────────────────────────────────
;; Dirvish (file manager)
;; ──────────────────────────────────────────

;; Toggle mark on the file at point and move to the next line.
;; dired-mark alone doesn't unmark, so we check the marker char first.
(defun ay-dired-mark-toggle ()
  (interactive)
  (if (eq (char-after (line-beginning-position)) ?*)
      (dired-unmark 1)
    (dired-mark 1)))

(defun ay-dirvish ()
  "Open a dirvish/dired buffer for the current directory in a right split."
  (interactive)
  (let ((dir default-directory))
    (ay-split-right)
    (dired dir)))

;; Clipboard-style file staging so C-c/C-x/C-v work like a GUI file manager.
;; C-c stages marked files for copy, C-x for move; C-v executes in current dir.
(defvar ay-dired-stage nil)

(defun ay-dired-copy-stage ()
  (interactive)
  (let ((files (dired-get-marked-files)))
    (setq ay-dired-stage (list :files files :op 'copy))
    (message "Staged %d file(s) for copy" (length files))))

(defun ay-dired-cut-stage ()
  (interactive)
  (let ((files (dired-get-marked-files)))
    (setq ay-dired-stage (list :files files :op 'move))
    (message "Staged %d file(s) for move" (length files))))

(defun ay-dired-paste ()
  (interactive)
  (unless ay-dired-stage (user-error "Nothing staged — use C-c or C-x first"))
  (let* ((files (plist-get ay-dired-stage :files))
         (op    (plist-get ay-dired-stage :op))
         (dest  (dired-current-directory)))
    (dolist (f files)
      (let ((target (expand-file-name (file-name-nondirectory f) dest)))
        (if (eq op 'copy)
            (copy-file f target t)
          (rename-file f target t))))
    (when (eq op 'move) (setq ay-dired-stage nil))
    (revert-buffer)))

(use-package dirvish
  :straight t
  :init
  ;; Replace dired with dirvish everywhere (dired remains the backend).
  (dirvish-override-dired-mode)
  :config
  ;; No auto full-frame; ay-dirvish manages the split manually.
  (setq dirvish-default-layout nil)
  ;; Inline columns: file size and modification time.
  (setq dirvish-attributes '(file-size file-time))
  ;; ls: include dotfiles in the listing (needed for dired-omit-mode toggle
  ;; to work without a full buffer revert), but hide . and .. themselves.
  (setq dired-listing-switches
        "-l --almost-all --human-readable --group-directories-first --no-group")
  ;; dired-omit-mode (from dired-x) hides dotfiles from view by default.
  ;; The files are still in the buffer; toggling is instant (no revert needed).
  (require 'dired-x)
  (setq dired-omit-files "^\\.")          ; hide anything starting with .
  (setq dired-omit-verbose nil)           ; no "Omitting N files" message
  (add-hook 'dired-mode-hook #'dired-omit-mode)
  ;; Preview dispatchers in priority order.
  ;; Needs: imagemagick (images), ffmpegthumbnailer (video).
  (setq dirvish-preview-dispatchers '(image gif video audio pdf archive))
  ;; Reuse the same buffer when navigating into subdirectories so each
  ;; directory doesn't open a new tab.
  (setq dired-kill-when-opening-new-dired-buffer t)
  ;; Send deleted files to trash (F8 still asks for confirmation).
  (setq delete-by-moving-to-trash t)
  :bind
  (:map dirvish-mode-map
   ;; STANDARDS.md file manager keybindings
   ("<f2>"          . dired-do-rename)       ; rename
   ("<f4>"          . dired-find-file)        ; open in Emacs
   ("<f5>"          . dired-do-copy)          ; copy → other pane dir
   ("<f6>"          . dired-do-rename)        ; move → other pane dir
   ("<f7>"          . dired-create-directory) ; mkdir
   ("<f8>"          . dired-do-delete)        ; delete (→ trash)
   ("C-<backspace>" . dired-do-delete)        ; delete alternate
   ("<backspace>"   . dired-up-directory)     ; parent dir
   ("SPC"           . ay-dired-mark-toggle)   ; mark/unmark
   ("C-c"           . ay-dired-copy-stage)    ; copy  (stage, paste with C-v)
   ("C-x"           . ay-dired-cut-stage)     ; cut   (stage, paste with C-v)
   ("C-v"           . ay-dired-paste)         ; paste staged files here
   ;; ` toggles full-frame preview layout (image/video/pdf panel)
   ("`"             . dirvish-layout-toggle)))


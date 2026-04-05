;; menus.el — Transient menus (main, file, buffers, view, settings, pane, apps, here)
;;
;; Contents:
;;   - File menu
;;   - Buffers menu
;;   - View menu
;;   - Settings menu (theme, reload, open config dir)
;;   - Markdown formatting menu
;;   - Org formatting menu
;;   - Pane/window menu
;;   - Apps menu (terminal, browser, gemini, IRC submenu)
;;   - Here menus: EWW, Elpher, ERC, Eat (context-sensitive)
;;   - ay-here-menu dispatcher (selects menu by major mode)
;;   - Main menu (ay-menu, bound to C-k)


;; ── File ──────────────────────────────────
(transient-define-prefix ay-file-menu ()
  "File operations."
  [["file"
    ("n" "new (scratch)"  (lambda () (interactive) (switch-to-buffer "*scratch*")))
    ("o" "open"           counsel-find-file)
    ("s" "save"           save-buffer)
    ("S" "save as"        write-file)
    ("c" "close"          kill-buffer)]])

;; ── Buffers ───────────────────────────────
(transient-define-prefix ay-buffers-menu ()
  "Buffer operations."
  [["buffers"
    ("l" "list"  ivy-switch-buffer)
    ("c" "close" kill-buffer)]])

;; ── View ──────────────────────────────────
(transient-define-prefix ay-view-menu ()
  "View options."
  [["view"
    ("t" "typesetter mode" ay-typewriter-mode)
    ("c" "center mode"     olivetti-mode)
    ("m" "markdown mode"   markdown-mode)
    ("o" "org mode"        org-mode)
    ("p" "plain text"      text-mode)]])

;; ── Settings ──────────────────────────────
(transient-define-prefix ay-settings-menu ()
  "Settings."
  [["settings"
    ("t" "theme"         ay-pick-theme)
    ("r" "reload config" reload-config)
    ("o" "open config"   (lambda () (interactive)
                           (dired (expand-file-name "config/" user-emacs-directory))))]])

;; ── Markdown ──────────────────────────────
(transient-define-prefix ay-markdown-menu ()
  "Markdown formatting and insertion."
  [["format"
    ("b" "bold"          markdown-insert-bold)
    ("i" "italic"        markdown-insert-italic)
    ("c" "code"          markdown-insert-code)
    ("s" "strikethrough" markdown-insert-strike-through)
    ("q" "quote"         markdown-insert-blockquote)]
   ["insert"
    ("l" "link"          markdown-insert-link)
    ("g" "image"         markdown-insert-image)
    ("h" "heading"       markdown-insert-header-dwim)
    ("k" "code block"    markdown-insert-gfm-code-block)
    ("r" "rule"          markdown-insert-hr)]])

;; ── Org ───────────────────────────────────
(defun ay-org-bold () (interactive) (org-emphasize ?*))
(defun ay-org-italic () (interactive) (org-emphasize ?/))
(defun ay-org-code () (interactive) (org-emphasize ?~))
(defun ay-org-verbatim () (interactive) (org-emphasize ?=))
(defun ay-org-strikethrough () (interactive) (org-emphasize ?+))
(defun ay-org-underline () (interactive) (org-emphasize ?_))
(defun ay-org-code-block () (interactive) (org-insert-structure-template "src"))
(defun ay-org-quote-block () (interactive) (org-insert-structure-template "quote"))
(defun ay-org-insert-image ()
  "Insert an org image link, prompting for the file path."
  (interactive)
  (let ((path (read-file-name "Image: ")))
    (insert (format "[[file:%s]]" path))))

(transient-define-prefix ay-org-menu ()
  "Org formatting and insertion."
  [["format"
    ("b" "bold"          ay-org-bold)
    ("i" "italic"        ay-org-italic)
    ("c" "code"          ay-org-code)
    ("v" "verbatim"      ay-org-verbatim)
    ("s" "strikethrough" ay-org-strikethrough)
    ("u" "underline"     ay-org-underline)]
   ["insert"
    ("l" "link"          org-insert-link)
    ("h" "heading"       org-insert-heading)
    ("k" "code block"    ay-org-code-block)
    ("q" "quote block"   ay-org-quote-block)
    ("g" "image"         ay-org-insert-image)
    ("t" "toggle todo"   org-todo)
    ("e" "export"        org-export-dispatch)]])

;; ── Pane / Window ─────────────────────────
(transient-define-prefix ay-pane-menu ()
  "Window pane management."
  [["navigate"
    ("a" "prev pane"    (lambda () (interactive) (other-window -1)))
    ("d" "next pane"    other-window)]
   ["split"
    ("s" "split right"  ay-split-right)
    ("S" "split below"  ay-split-below)]
   ["close"
    ("c" "close pane"   delete-window)
    ("C" "close others" delete-other-windows)]])

;; ── Apps ──────────────────────────────────
(transient-define-prefix ay-irc-menu ()
  "IRC network selection."
  [["connect to"
    ("l" "Libera.Chat"  ay-erc-libera)
    ("u" "Undernet"     ay-erc-undernet)]])

(transient-define-prefix ay-apps-menu ()
  "Applications."
  [["apps"
    ("t" "terminal"  eat)
    ("b" "browser"   eww)
    ("g" "gemini"    elpher)
    ("i" "irc →"     ay-irc-menu)]])

;; ── Context (here) menus ──────────────────
(transient-define-prefix ay-here-eww-menu ()
  "EWW browser actions."
  [["navigate"
    ("g" "go to URL"    eww)
    ("a" "back"         eww-back-url)
    ("d" "forward"      eww-forward-url)
    ("C-r" "reload"     eww-reload)]
   ["page"
    ("r" "reader mode"  eww-readable)
    ("t" "new buffer"   ay-eww-new-buffer)
    ("u" "copy URL"     ay-eww-copy-url)
    ("y" "copy link"    ay-eww-copy-link)]
   ["bookmarks"
    ("b" "list"         counsel-bookmark)
    ("B" "add"          ay-eww-add-bookmark)]])

(transient-define-prefix ay-here-elpher-menu ()
  "Elpher Gemini/Gopher actions."
  [["navigate"
    ("g" "go to"        elpher-go)
    ("a" "back"         elpher-back)
    ("C-r" "reload"     elpher-reload)]
   ["page"
    ("u" "copy URL"     elpher-copy-current-url)
    ("c" "copy link"    elpher-copy-link-url)]
   ["bookmarks"
    ("b" "list"         elpher-show-bookmarks)
    ("B" "add"          elpher-bookmark-link)]])

(transient-define-prefix ay-here-erc-menu ()
  "ERC IRC actions."
  [["server"
    ("j" "join channel"  erc-join-channel)
    ("l" "channel list"  ay-erc-list)
    ("q" "quit IRC"      erc-quit-server)]
   ["channel"
    ("p" "part (leave)"  erc-part-from-channel)
    ("n" "names (members)" ay-erc-names)
    ("t" "next active"   erc-track-switch-buffer)]])

(transient-define-prefix ay-here-eat-menu ()
  "Eat terminal actions."
  [["terminal"
    ("c" "clear"  eat-reset)]])

(defun ay-here-menu ()
  "Open the context menu for the current major mode."
  (interactive)
  (cond
   ((derived-mode-p 'eww-mode)      (ay-here-eww-menu))
   ((derived-mode-p 'elpher-mode)   (ay-here-elpher-menu))
   ((derived-mode-p 'eat-mode)      (ay-here-eat-menu))
   ((derived-mode-p 'erc-mode)      (ay-here-erc-menu))
   ((derived-mode-p 'markdown-mode) (ay-markdown-menu))
   ((derived-mode-p 'org-mode)      (ay-org-menu))
   (t (message "No context menu for this mode"))))

;; ── Main Menu ─────────────────────────────
(transient-define-prefix ay-menu ()
  "Main menu."
  [["menu"
    ("f" "file →"     ay-file-menu)
    ("b" "buffers →"  ay-buffers-menu)
    ("p" "pane →"     ay-pane-menu)
    ("a" "apps →"     ay-apps-menu)
    ("v" "view →"     ay-view-menu)
    ("h" "here →"     ay-here-menu)
    ("s" "settings →" ay-settings-menu)
    ("q" "quit"       save-buffers-kill-emacs)]])
